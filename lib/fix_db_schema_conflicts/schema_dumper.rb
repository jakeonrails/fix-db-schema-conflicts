require 'delegate'

module FixDBSchemaConflicts
  module SchemaDumper
    class ConnectionWithSorting < SimpleDelegator
      def extensions
        __getobj__.extensions.sort
      end

      def columns(table)
        __getobj__.columns(table).sort_by(&:name)
      end

      def indexes(table)
        indexes_string_sort(table)
        # __getobj__.indexes(table).sort_by(&:name)
      end

      def foreign_keys(table)
        __getobj__.indexes(table).sort_by(&:name)
      end

      def indexes_string_sort(table)
        cols = __getobj__.indexes(table)
        cols.reduce({ids:[],datetimes:[],other:[]}) do |h,col|
          case col.name
          when /_id$"/
            h[:ids] << col
          when /_at$"/
            h[:datetimes] << col
          else
            h[:other] << col
          end
          h
        end.tap {|h| h[:ids      ] = h[:ids      ].sort{|a,b| a.name <=> b.name }}
        .tap    {|h| h[:datetimes] = h[:datetimes].sort{|a,b| a.name <=> b.name }}
        .tap    {|h| h[:other    ] = h[:other    ].sort{|a,b| a.name <=> b.name }}
        .values.flatten
      end
    end

    def extensions(*args)
      with_sorting do
        super(*args)
      end
    end

    def table(*args)
      with_sorting do
        super(*args)
      end
    end

    def with_sorting
      old, @connection = @connection, ConnectionWithSorting.new(@connection)
      result = yield
      @connection = old
      result
    end
  end
end

ActiveRecord::SchemaDumper.send(:prepend, FixDBSchemaConflicts::SchemaDumper)
