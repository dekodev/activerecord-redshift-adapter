module ActiverecordRedshift
  class TableManager
    attr_reader :default_options

    DEFAULT_OPTIONS = { :exemplar_table_name => nil, :add_identity => false, :temporary => true}

    def initialize(connection, default_options = {})
      @connection = connection
      table_name_options = {}
      if default_options[:partitioned_model]
        model = default_options[:partitioned_model]
        default_options[:exemplar_table_name] = model.table_name
        default_options[:schema_name] = model.configurator.schema_name
      end

      if default_options[:table_name].blank?
        connection_pid = @connection.execute("select pg_backend_pid() as pid").first['pid'].to_i
        table_name_options[:table_name] = "temporary_events_#{connection_pid}" 
      end
      @default_options = DEFAULT_OPTIONS.merge(table_name_options).merge(default_options)
    end

    def partitioned_model
      return @default_options[:partitioned_model]
    end

    def schema_name
      return @default_options[:schema_name]
    end

    def exemplar_table_name
      return @default_options[:exemplar_table_name]
    end

    def add_identity
      return @default_options[:add_identity]
    end

    def temporary
      return @default_options[:temporary]
    end

    def base_table_name
      return @default_options[:table_name]
    end

    def table_name
      if schema_name.blank?
        return base_table_name
      end
      return "#{schema_name}.#{base_table_name}"
    end

    def drop_table
      @connection.execute("drop table #{table_name}")
    end

    def duplicate_table(options = {})
      current_options = @default_options.merge(options)
      target_table_name = current_options[:table_name]
      raise "target_table_name not set" if target_table_name.blank?
      exemplar_table_name = current_options[:exemplar_table_name]
      raise "exemplar_table_name not set" if exemplar_table_name.blank?
      table_name_elements = exemplar_table_name.split('.');
      if table_name_elements.length == 1
        table_name_elements.unshift("public")
      end
      schema_name = table_name_elements[0]
      parent_table_name = table_name_elements[1]

      # first find the diststyle
      ## namespace first
      sql = "select oid from pg_namespace where nspname = '#{schema_name}' limit 1"
      schema_oid = @connection.execute(sql).first['oid'].to_i

      ## now the diststyle 0 = even, 1 = some column
      sql = "select oid,reldiststyle from pg_class where relnamespace = #{schema_oid} and relname = '#{parent_table_name}' limit 1"
      pg_class_row = @connection.execute(sql).first
      reldiststyle = pg_class_row['reldiststyle'].to_i
      even_diststyle = (reldiststyle == 0)
      table_oid = pg_class_row['oid'].to_i

      ## get unique and primary key constraints (pg_constraints)
      sql = "select contype,conkey from pg_constraint where connamespace = #{schema_oid} and conrelid = #{table_oid}"
      primary_key = nil
      uniques = []
      @connection.execute(sql).each do |row|
        if row['contype'] == 'p'
          # primary key
          primary_key = row['conkey'][1..-2].split(',')
        elsif row['contype'] == 'u'
          # unique
          uniques << row['conkey'][1..-2].split(',')
        end
      end

      attnums = uniques.clone
      unless primary_key.blank?
        attnums << primary_key
      end
      attnums = attnums.flatten.uniq

      column_names = {}
      if attnums.length > 0
        sql = "select attname,attnum from pg_attribute where attrelid = #{table_oid} and attnum in (#{attnums.join(',')})"
        @connection.execute(sql).each do |row|
          column_names[row['attnum']] = row['attname']
        end
      end

      column_defaults = {}
      sql = "select a.attname,d.adsrc from pg_attribute as a,pg_attrdef as d where a.attrelid = d.adrelid and d.adnum = a.attnum and a.attrelid = #{table_oid}"
      @connection.execute(sql).each do |row|
        column_defaults[row['attname']] = row['adsrc']
      end
      
      with_search_path([schema_name]) do
        # select * from pg_table_def where tablename = 'bids' and schemaname = 'public';
        ## column, type, encoding, distkey, sortkey, not null
        sortkeys = []
        sql_columns = []

        if current_options[:add_identity]
          sql_columns << "_identity bigint identity"
        end

        sql = "select * from pg_table_def where tablename = '#{parent_table_name}' and schemaname = '#{schema_name}'"
        sql_column_rows = @connection.execute(sql)
        sql_column_rows.each do |row|
          column_info = []
          column_name = row['column']
          column_info << column_name
          column_info << row['type']
          if row['notnull'] == "t"
            column_info << "not null"
          end
          if row['distkey'] == "t"
            column_info << "distkey"
          end
          if row['encoding'] != 'none'
            column_info << "encode #{row['encoding']}"
          end
          if row['sortkey'] != "0"
            sortkeys[row['sortkey'].to_i - 1] = column_name
          end
          unless column_defaults[column_name].blank?
            column_info << "default #{column_defaults[column_name]}"
          end

          sql_columns << column_info.join(" ")
        end

        unless primary_key.blank?
          sql_columns << "primary key (#{primary_key.map{|pk| column_names[pk]}.join(',')})"
        end

        uniques.each do |unique|
          sql_columns << "unique (#{unique.map{|uk| column_names[uk]}.join(',')})"
        end

        if sortkeys.blank?
          sql_sortkeys = ""
        else
          sql_sortkeys = " sortkey (#{sortkeys.join(',')})"
        end
        sql = <<-SQL
         create #{"temporary " if current_options[:temporary]}table #{table_name}
         (
          #{sql_columns.join(', ')}
         ) #{"diststyle even " if even_diststyle}#{sql_sortkeys}
        SQL
        @connection.execute(sql)
      end
    end

    def table_def(table_name)
      table_parts = table_name.split('.')
      if table_parts.length == 1
        name = table_parts.first
        search_path = ["public"]
      else
        name = table_parts.last
        search_path = [table_parts.first]
      end

      with_search_path(search_path) do
        return @connection.execute("select * from pg_table_def where tablename = '#{name}'").to_a
      end
    end

    # search_path = array
    # modes: :prefix, :suffix, :replace
    def with_search_path(search_path, mode = :replace, &block)
      unless search_path.is_a? Array
        raise "search_path must be an Array"
      end

      old_search_path = get_search_path
      if mode == :prefix
        new_search_path = search_path + old_search_path
      elsif mode == :suffix
        new_search_path = old_search_path + search_path
      elsif mode == :replace
        new_search_path = search_path
      else
        raise "mode must be :prefix, :suffix, :replace"
      end

      set_search_path(new_search_path)
      begin
        yield
      ensure
        set_search_path(old_search_path)
      end
    end

    def get_search_path
      return @connection.execute("show search_path").to_a.first["search_path"].split(',').map{|p| p.delete('" ')}
    end

    def set_search_path(search_path)
      unless search_path.is_a? Array
        raise "search_path must be an Array"
      end
      quoted_search_path = search_path.map{|sp| "'#{sp}'"}.join(',')
      @connection.execute("set search_path = #{quoted_search_path}")
    end

  end
end
