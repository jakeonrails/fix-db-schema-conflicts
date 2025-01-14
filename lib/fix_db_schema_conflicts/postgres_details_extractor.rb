# frozen_string_literal: true

module FixDBSchemaConflicts
  class PostgresDetailsExtractor
    def initialize(connection)
      @connection = connection
      @pg_enum_types = @connection.fetch_enum_types
      @pg_functions = @connection.pg_functions
      @pg_fts_configurations = @connection.fts_configurations
      @pg_aggregates = @connection.all_aggregates
      files_verif_and_reset
    end

    def create_types(stream)
      @pg_enum_types.each do |enum|
        exttracted_values = extract_types_components(enum)
        types_in_file(exttracted_values)
      end

      if @pg_composite_types.present?
        @pg_composite_types.each do |composite|
          exttracted_values = extract_types_components(composite)
          types_in_file(exttracted_values)
        end
      end
      stream.puts("\tfile = Rails.root.join('db', 'others', 'types.sql')")
      stream.puts("\tfile_content = File.read(file)")
      stream.puts("\texecute file_content")
    end

    def create_aggregates(stream)
      return if @pg_aggregates.empty?

      @pg_aggregates.each do |aggregate|
        aggregates_in_file(aggregate.definition)
      end
      stream.puts("\taggregate_file = Rails.root.join('db', 'others', 'aggregates.sql')")
      stream.puts("\taggregate_content = File.read(aggregate_file)")
      stream.puts("\texecute aggregate_content")
    end

    def create_functions(stream)
      @pg_functions.each do |row|
        function_content, function_name = extract_function_components(row)
        functions_in_file(function_name, function_content)
      end

      stream.puts("\tfunction_files_path = Rails.root.join('db', 'functions')")
      stream.puts("\tsql_files = Dir.glob(File.join(function_files_path, '*.sql')).sort")
      stream.puts("\tsql_files.sort.each do |file|")
      stream.puts("\t    sql = File.read(file)")
      stream.puts("\t    execute sql")
      stream.puts("\tend")
    end

    def create_fts_configurations(stream)
      unless @pg_fts_configurations.empty?
        @pg_fts_configurations.each do |fts_configuration|
          sql_code = "DO $$ BEGIN " \
                        "IF NOT EXISTS (SELECT 1 FROM pg_ts_config WHERE cfgname = '#{fts_configuration.name}') THEN " \
                        "CREATE TEXT SEARCH CONFIGURATION #{fts_configuration.name} (COPY = simple); " \
                        "END IF; " \
                        "END $$;"
          extract_fts_configurations(sql_code)
        end
        stream.puts("\tfts_file = Rails.root.join('db', 'others', 'fts.sql')")
        stream.puts("\tfts_content = File.read(fts_file)")
        stream.puts("\texecute fts_content")
      end
    end

    private

    def files_verif_and_reset
      type_file_path = Rails.root.join('db', 'others')
      file_name = type_file_path.join("types.sql")
      FileUtils.mkdir_p type_file_path unless type_file_path.exist?
      File.open(file_name, "w") {}
      fts_file_path = Rails.root.join('db', 'others', 'fts.sql')
      File.open(fts_file_path, "w") {}
      aggreagte_file_path = Rails.root.join('db', 'others', 'aggregates.sql')
      File.open(aggreagte_file_path, "w") {}
      function_files = Rails.root.join('db', 'functions')
      FileUtils.rm_rf(Dir.glob("#{function_files}/*")) if function_files.present?
    end

    def extract_function_components(row)
      # Extract function components
      function_name = row.name
      arguments = row.arguments
      return_type = row.return_type
      language_name = row.language_name

      # Ensure function body doesn't have trailing semicolons
      function_body = row.body.strip.sub(/;+\z/, '')

      # Check if the function body starts with 'BEGIN'
      starts_with_begin = function_body.match?(/^\s*BEGIN/i)

      if starts_with_begin
        function_content = <<~SQL
        CREATE OR REPLACE FUNCTION #{function_name}(#{arguments})
          RETURNS #{return_type} AS $$
            #{function_body};
          $$ LANGUAGE #{language_name} #{row.volatility};
        SQL
      else
        function_content = <<~SQL
        CREATE OR REPLACE FUNCTION #{function_name}(#{arguments})
            RETURNS #{return_type} AS $$
              BEGIN
                #{function_body};
              END;
          $$ LANGUAGE plpgsql #{row.volatility};
        SQL
      end
      [function_content, function_name]
    end

    def extract_types_components(row)
      <<~SQL
        DO $$
        BEGIN
          IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = '#{row.name}') THEN
            CREATE TYPE #{row.name} AS (#{row.attributes});
          END IF;
        END
        $$;
      SQL
    end

    def functions_in_file(file_name, function_content)
      function_file_path = Rails.root.join('db', 'functions')
      file_name = function_file_path.join("#{file_name}.sql")
      FileUtils.mkdir_p function_file_path unless function_file_path.exist?
      File.open(file_name, "w") {} unless File.exist?(file_name)
      File.open(file_name, 'a') do |file|
        function_content = function_content.gsub(/\n+/, "\n")
                                   .gsub(/^\s+/m, '')
                                   .strip
        formatted_sql = function_content.gsub(/(?=\b(BEGIN|END|LANGUAGE|SET|WHERE)\b)/, "\n")
        file.write(formatted_sql + ";")
        file.puts
        file.puts
      end
    end

    def types_in_file(type_content)
      file_name = Rails.root.join('db', 'others', "types.sql")
      File.open(file_name, 'a') do |file|
        type_content = type_content.gsub(/\n+/, "\n")
                                     .gsub(/^\s+/m, '')
                                     .strip
        formatted_sql = type_content.gsub(/(?=\b(AS|BEGIN|END|LANGUAGE|CREATE)\b)/, "\n")
        file.write(formatted_sql + ";")
        file.puts
        file.puts
      end
    end

    def extract_fts_configurations(fts_content)
      file_name = Rails.root.join('db', 'others', "fts.sql")
      File.open(file_name, 'a') do |file|
        fts_content = fts_content.strip
        formatted_sql = fts_content.gsub(/(?=\b(AS|BEGIN|END|LANGUAGE|CREATE)\b)/, "\n")
        file.write(formatted_sql + ";")
        file.puts
        file.puts
      end
    end

    def aggregates_in_file(aggregate_content)
      file_name = Rails.root.join('db', 'others', "aggregates.sql")
      File.open(file_name, 'a') do |file|
        aggregate_content = sanitize_aggregate_definition(aggregate_content)
        formatted_sql = aggregate_content.gsub(/(?=\b(AS|BEGIN|END|LANGUAGE|CREATE)\b)/, "\n")
        file.write(formatted_sql + ";")
        file.puts
        file.puts
      end
    end

    def sanitize_aggregate_definition(sql)
      # Remove invalid or empty clauses completely
      sql = sql.gsub(/,\s*FINALFUNC\s*=\s*[^,\)\n]*/, '')
               .gsub(/,\s*FINALFUNC_MODIFY\s*=\s*[^,\)\n]*/, '')
               .gsub(/,\s*MFINALFUNC_MODIFY\s*=\s*[^,\)\n]*/, '')
               .gsub(/,\s*COMBINEFUNC\s*=\s*[^,\)\n]*/, '')
               .gsub(/,\s*SERIALFUNC\s*=\s*[^,\)\n]*/, '')
               .gsub(/,\s*DESERIALFUNC\s*=\s*[^,\)\n]*/, '')

      # Remove dangling empty clauses
      sql = sql.gsub(/\b(FINALFUNC|FINALFUNC_MODIFY|MFINALFUNC_MODIFY|COMBINEFUNC|SERIALFUNC|DESERIALFUNC)\s*=\s*[^,\)\n]*/, '')

      # Add missing commas between SFUNC and STYPE
      sql.gsub!(/(SFUNC\s*=\s*[^\s,]+)\s+(STYPE\s*=\s*[^\s,]+)/, '\1, \2')

      # Remove trailing commas before closing parentheses
      sql.gsub!(/,\s*\)/, ')')

      # Remove unnecessary semicolons
      sql.gsub!(/;;$/, ';')

      # Ensure proper formatting by removing extra spaces
      sql.gsub!(/\s{2,}/, ' ')  # Replace multiple spaces with a single space

      # Final cleanup
      sql.strip
    end
  end
end
