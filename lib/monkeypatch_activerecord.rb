module ActiveRecord
  module Querying
    delegate :unload, :copy, :to => :scoped
  end
end

module ActiveRecord::QueryMethods
  module CopyUnloadParser
    def self.parse_options(options, options_hash, valid_switches, valid_options, valid_unquoted_options, valid_special_options)
      # credentials first
      credentials = nil
      if options_hash.has_key?(:credentials)
        credentials = options_hash[:credentials]
      else
        creds = {}
        creds[:aws_access_key_id] = options_hash[:aws_access_key_id] if options_hash.has_key?(:aws_access_key_id)
        creds[:aws_secret_access_key] = options_hash[:aws_secret_access_key] if options_hash.has_key?(:aws_secret_access_key)
        creds[:token] = options_hash[:token] if options_hash.has_key?(:token)
        creds[:master_symmetric_key] = options_hash[:master_symmetric_key] if options_hash.has_key?(:master_symmetric_key)
        credentials = creds.map{|k,v| "#{k}=#{v}"}.join(';')
      end

      option_list = []
      option_list << "WITH CREDENTIALS AS #{connection.quote_value(credentials)}" unless credentials.blank?

      valid_switches.each do |switch_name|
        if options.include? switch_name
          option_list << switch_name.to_s.upcase
        end
      end

      valid_options.each do |option_name|
        if options_hash.has_key? option_name
          option_list << "#{option_name.to_s.upcase} AS #{connection.quote_value(options_hash[option_name])}"
        end
      end

      valid_unquoted_options.each do |option_name|
        if options_hash.has_key? option_name
          option_list << "#{option_name.to_s.upcase} #{options_hash[option_name]}"
        end
      end

      return credentials, option_list
    end
  end
end

module ActiveRecord
  module QueryMethods
    # UNLOAD ('select_statement')
    # TO 's3_path'
    # [ WITH ] CREDENTIALS [AS] 'aws_access_credentials' 
    # [ option [ ... ] ]
    #
    # where option is
    #
    # { DELIMITER [ AS ] 'delimiter_char' 
    # | FIXEDWIDTH [ AS ] 'fixedwidth_spec' }  
    # | ENCRYPTED
    # | GZIP     
    # | ADDQUOTES 
    # | NULL [ AS ] 'null_string'
    # | ESCAPE
    # | ALLOWOVERWRITE
    VALID_UNLOAD_SWITCHES = [
                             :gzip,
                             :addquotes,
                             :escape,
                             :allowoverwrite
                            ]
    VALID_UNLOAD_OPTIONS = [
                            :delimiter,
                            :fixedwidth,
                            :null
                           ]
    VALID_UNQUOTED_UNLOAD_OPTIONS = [ ]
    VALID_SPECIAL_UNLOAD_OPTIONS = [
                                    :credentials,
                                    :aws_access_key_id,
                                    :aws_secret_access_key,
                                    :master_symmetric_key,
                                    :token
                                   ]

    def unload(to_s3_filename, *options)
      if options.last.is_a? Hash
        options_hash = options.last
      else
        options_hash = {}
      end

      credentials, unload_options =
        ActiveRecord::QueryMethods::CopyUnloadParser.parse_options(options, options_hash,
                                                                   VALID_UNLOAD_SWITCHES, VALID_UNLOAD_OPTIONS, VALID_UNQUOTED_UNLOAD_OPTIONS, VALID_SPECIAL_UNLOAD_OPTIONS)


      relation = Arel::Nodes::UnloadStatement.new(Arel::Nodes::Unload.new(Arel::Nodes::Relation.new(clone), to_s3_filename), unload_options.join(" "))
      relation
    end

    VALID_COPY_SWITCHES = [
                           :encrypted,
                           :gzip,
                           :removequotes,
                           :explicit_ids,
                           :escape,
                           :acceptanydate,
                           :ignoreblanklines,
                           :truncatecolumns,
                           :fillrecord,
                           :trimblanks,
                           :noload,
                           :emptyasnull,
                           :blanksasnull,
                           :escape,
                           :roundec
                          ]
    VALID_COPY_OPTIONS = [
                          :delimiter,
                          :fixedwidth,
                          :csv,
                          :acceptinvchars,
                          :dateformat,
                          :timeformat,
                          :null
                         ]

    VALID_UNQUOTED_COPY_OPTIONS = [
                                   :maxerror,
                                   :ignoreheader,
                                   :comprows,
                                   :compupdate,
                                   :statupdate
                                  ]

    VALID_SPECIAL_COPY_OPTIONS = [
                                    :credentials,
                                    :aws_access_key_id,
                                    :aws_secret_access_key,
                                    :master_symmetric_key,
                                    :token
                                   ]

    # COPY table_name [ (column1 [,column2, ...]) ]
    # FROM 's3://objectpath'
    # [ WITH ] CREDENTIALS [AS] 'aws_access_credentials'
    # [ option [ ... ] ]

    # where option is 

    # { FIXEDWIDTH 'fixedwidth_spec' 
    # | [DELIMITER [ AS ] 'delimiter_char']  
    #   [CSV [QUOTE [ AS ] 'quote_character']}

    # | ENCRYPTED
    # | GZIP
    # | REMOVEQUOTES
    # | EXPLICIT_IDS

    # | ACCEPTINVCHARS [ AS ] ['replacement_char']
    # | MAXERROR [ AS ] error_count
    # | DATEFORMAT [ AS ] { 'dateformat_string' | 'auto' }
    # | TIMEFORMAT [ AS ] { 'timeformat_string' | 'auto' | 'epochsecs' | 'epochmillisecs' }
    # | IGNOREHEADER [ AS ] number_rows
    # | ACCEPTANYDATE
    # | IGNOREBLANKLINES
    # | TRUNCATECOLUMNS
    # | FILLRECORD
    # | TRIMBLANKS
    # | NOLOAD
    # | NULL [ AS ] 'null_string'
    # | EMPTYASNULL
    # | BLANKSASNULL
    # | COMPROWS numrows
    # | COMPUPDATE [ { ON | TRUE } | { OFF | FALSE } ]
    # | STATUPDATE [ { ON | TRUE } | { OFF | FALSE } ]
    # | ESCAPE
    # | ROUNDEC 
    def copy(to_s3_filename, *options)
      if options.last.is_a? Hash
        options_hash = options.last
      else
        options_hash = {}
      end

      credentials, copy_options =
        ::ActiveRecord::QueryMethods::CopyUnloadParser.parse_options(options, options_hash,
                                                                     VALID_COPY_SWITCHES, VALID_COPY_OPTIONS, VALID_UNQUOTED_COPY_OPTIONS, VALID_SPECIAL_COPY_OPTIONS)


      conncection.execute(Arel::Nodes::CopyStatement.new(Arel::Nodes::Copy.new(table_name, to_s3_filename), copy_options.join(" ")).to_sql)
    end
  end
end
