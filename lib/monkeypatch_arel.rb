module Arel
  module Nodes
    class Relation < Arel::Nodes::Unary
    end

    class Unload < Arel::Nodes::Binary
      alias :statement :left
      alias :statement= :left=
      alias :to :right
      alias :to= :right=
      def initialize statement = nil, to = nil
        super
      end

      def initialize_copy other
        super
        @right = @right.clone
      end
    end

    class UnloadStatement < Arel::Nodes::Binary
      alias :relation :left
      alias :relation= :left=
      alias :options :right
      alias :options= :right=

      def initialize relation = nil, options = []
        super
      end

      def initialize_copy other
        super
        @right = @right.clone
      end
    end

    class Copy < Arel::Nodes::Binary
      alias :statement :left
      alias :statement= :left=
      alias :from :right
      alias :from= :right=
      def initialize statement = nil, from = nil
        super
      end

      def initialize_copy other
        super
        @right = @right.clone
      end
    end

    class CopyStatement < Arel::Nodes::Binary
      alias :relation :left
      alias :relation= :left=
      alias :options :right
      alias :options= :right=

      def initialize relation = nil, options = []
        super
      end

      def initialize_copy other
        super
        @right = @right.clone
      end
    end

  end
end

module Arel
  module Visitors
    class ToSql < Arel::Visitors::Reduce

      def visit_Arel_Nodes_UnloadStatement o
        "#{visit o.relation} #{o.options}"
      end

      def visit_Arel_Nodes_Unload o
        "UNLOAD (#{visit o.statement}) TO #{visit o.to}"
      end

      def visit_Arel_Nodes_CopyStatement o
        "#{visit o.relation} #{o.options}"
      end

      def visit_Arel_Nodes_Copy o
        "COPY #{o.statement} FROM #{visit o.from}"
      end

      def visit_Arel_Nodes_Relation o
        visit o.expr.to_sql
      end
    end
  end
end
