require 'delegate'
require_relative 'postgres_schema_info_extractor'
require 'fix_db_schema_conflicts/triggers_operations'
require 'fix_db_schema_conflicts/postgres_details_extractor'

module FixDBSchemaConflicts
  module SchemaDumper
    class ConnectionWithSorting < SimpleDelegator
      def initialize(connection)
        super(connection)
        @schema_info_extractor = FixDBSchemaConflicts::PostgresSchemaInfoExtractor.new(__getobj__)
      end

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
        __getobj__.foreign_keys(table).sort_by(&:name)
      end

      def pg_functions
        @schema_info_extractor.pg_functions
      end

      def fetch_enum_types
        @schema_info_extractor.fetch_enum_types
      end

      def triggers(table)
        query = <<-SQL
          SELECT tgname AS name, pg_get_triggerdef(oid) AS definition
          FROM pg_trigger
          WHERE tgrelid = '#{table}'::regclass AND NOT tgisinternal;
        SQL

        __getobj__.execute(query).map do |row|
          sanitized_sql = sanitize_trigger_definition(row['definition'])
          OpenStruct.new(name: row['name'], definition: sanitized_sql)
        end
      end

      def sanitize_trigger_definition(definition)
        new_definition = definition.gsub(/ON\s+(\w+\.)?(\w+\.)?/, 'ON ')
        new_definition.gsub!(/\bwizville\./, 'public.')
        new_definition
      end

      def fts_configurations
        @schema_info_extractor.fts_configurations
      end

      def all_aggregates
        @schema_info_extractor.aggregates
      end
    end

    def extensions(*args)
      with_sorting do
        super(*args)
      end
    end

    def tables(stream)
      specific = ENV['SCHEMA'] || if defined? ActiveRecord::Tasks::DatabaseTasks
                                    File.join(ActiveRecord::Tasks::DatabaseTasks.db_dir, 'specific.rb')
                                  else
                                    "#{Rails.root}/db/specific.rb"
                                  end

      if File.exist?(specific)
        stream.puts("\t" + File.read(specific).gsub("\n", "\n\t") + "\n\n")
      end

      aggreagates_fetched = false
      with_sorting do
        @details_operations = FixDBSchemaConflicts::PostgresDetailsExtractor.new(@connection)
        @details_operations.create_types(stream)
        @details_operations.create_functions(stream)
        @details_operations.create_fts_configurations(stream)
        @details_operations.create_aggregates(stream) unless aggreagates_fetched
      end
      super(stream)
    end

    def table(table_name, stream, *args)
      with_sorting do
        super(table_name, stream, *args)

        if @triggers_operations.nil?
          @triggers_operations = FixDBSchemaConflicts::TriggersOperations.new(@connection)
          @triggers_operations.reset_triggers_folder
        end
        @triggers_operations.triggers_creation(table_name, stream)
      end
    end

    def with_sorting
      old_connection = @connection
      @connection = ConnectionWithSorting.new(old_connection)
      begin
        yield
      ensure
        @connection = old_connection
      end
    end

    def sanitize_aggregate_definition(definition)
      # Sanitize or format the definition as needed
      definition.strip
    end
  end
end

ActiveRecord::SchemaDumper.send(:prepend, FixDBSchemaConflicts::SchemaDumper)
