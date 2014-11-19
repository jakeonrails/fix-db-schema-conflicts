module ActiveRecord
  # = Active Record Schema Dumper
  #
  # This class is used to dump the database schema for some connection to some
  # output format (i.e., ActiveRecord::Schema).
  class SchemaDumper

    private
    class TableSorter < SimpleDelegator
      def columns(table)
        __getobj__.columns(table).sort_by(&:name)
      end

      def indexes(table)
        __getobj__.indexes(table).sort_by(&:name)
      end

      def foreign_keys(table)
        __getobj__.indexes(table).sort_by(&:name)
      end
    end

    def table_with_sorting(table, stream)
      old_connection = @connection
      @connection = TableSorter.new(old_connection)
      result = table_without_sorting(table, stream)
      @connection = old_connection
      result
    end
    alias_method_chain :table, :sorting

  end
end
