require 'delegate'

module ActiveRecord
  # = Active Record Schema Dumper
  #
  # This class is used to dump the database schema for some connection to some
  # output format (i.e., ActiveRecord::Schema).
  class SchemaDumper

    private
    class ConnectionWithSorting < SimpleDelegator
      def extensions
        __getobj__.extensions.sort
      end

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

    def extensions_with_sorting(*args)
      with_sorting do
        extensions_without_sorting(*args)
      end
    end
    alias_method_chain :extensions, :sorting

    def table_with_sorting(*args)
      with_sorting do
        table_without_sorting(*args)
      end
    end
    alias_method_chain :table, :sorting

    def with_sorting(&block)
      old, @connection = @connection, ConnectionWithSorting.new(@connection)
      result = yield
      @connection = old
      result
    end
  end
end
