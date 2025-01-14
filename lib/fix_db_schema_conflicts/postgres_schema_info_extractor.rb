# frozen_string_literal: true
require 'delegate'
require 'fix-db-schema-conflicts'
require 'rails'

module FixDBSchemaConflicts
  class PostgresSchemaInfoExtractor
    def initialize(connection)
      @connection = connection
    end

    def pg_functions
      query = <<-SQL
        SELECT 
            proname AS function_name,
            pg_get_function_arguments(pg_proc.oid) AS arguments,
            pg_get_function_result(pg_proc.oid) AS return_type,
            CASE
                WHEN prosrc IS NOT NULL THEN prosrc
                ELSE 'Invalid Function Body'
            END AS function_body,
            CASE provolatile
                WHEN 'i' THEN 'IMMUTABLE'
                WHEN 's' THEN 'STABLE'
                WHEN 'v' THEN 'VOLATILE'
                ELSE 'UNKNOWN'
            END AS volatility,
            pg_language.lanname AS language_name
        FROM pg_proc
        JOIN pg_namespace ON pg_namespace.oid = pg_proc.pronamespace
        JOIN pg_language ON pg_language.oid = pg_proc.prolang
        WHERE pg_language.lanname IN ('sql', 'plpgsql')
          AND pg_namespace.nspname NOT IN ('pg_catalog', 'information_schema')
          AND proname NOT LIKE 'pg_%'
        ORDER BY function_name;
      SQL

      @connection.execute(query).map do |row|
        OpenStruct.new(
          name: row['function_name'],
          arguments: row['arguments'],
          return_type: row['return_type'],
          body: row['function_body'],
          volatility: row['volatility'],
          language_name: row['language_name']
        )
      end
    end

    def fetch_enum_types
      query = <<-SQL
        SELECT t.typname AS type_name,
               string_agg(quote_literal(e.enumlabel), ', ') AS enum_values
        FROM pg_type t
        JOIN pg_enum e ON t.oid = e.enumtypid
        WHERE t.typcategory = 'E'
        GROUP BY t.typname;
      SQL

      @connection.execute(query).map do |row|
        OpenStruct.new(
          name: row['type_name'],
          enum_values: row['enum_values']
        )
      end
    end

    def fts_configurations
      query = <<-SQL
        SELECT
          nspname AS schema_name,
          cfgname AS configuration_name
        FROM
          pg_ts_config
        JOIN
          pg_namespace ON pg_ts_config.cfgnamespace = pg_namespace.oid
        ORDER BY
          schema_name, configuration_name;
      SQL

      @connection.execute(query).map do |row|
        OpenStruct.new(schema: row['schema_name'], name: row['configuration_name'])
      end
    end

    def aggregates
      query = <<-SQL
          SELECT
              p.proname AS name,
              format_type(a.aggtranstype, NULL) AS state_type,
              (SELECT proname FROM pg_proc WHERE oid = a.aggtransfn) AS transition_function,
              (SELECT proname FROM pg_proc WHERE oid = a.aggfinalfn) AS final_function,
              (SELECT proname FROM pg_proc WHERE oid = a.aggcombinefn) AS combine_function,
              (SELECT proname FROM pg_proc WHERE oid = a.aggserialfn) AS serialize_function,
              (SELECT proname FROM pg_proc WHERE oid = a.aggdeserialfn) AS deserialize_function,
              a.agginitval AS initial_value,
              a.aggfinalmodify AS finalfunc_modify,
              a.aggmfinalmodify AS mfinalfunc_modify,
              a.aggkind AS aggregate_kind
          FROM
              pg_aggregate a
          JOIN
              pg_proc p ON a.aggfnoid = p.oid
          JOIN
              pg_namespace n ON p.pronamespace = n.oid
          WHERE
              n.nspname = 'wizville'
          ORDER BY
              p.proname;
        SQL

      @connection.execute(query).map do |row|
        # Start building the SQL string dynamically
        sql_parts = []
        sql_parts << "CREATE AGGREGATE public.#{row['name']} (#{row['state_type']}) ("
        sql_parts << "SFUNC = #{row['transition_function']}"
        sql_parts << "STYPE = #{row['state_type']}"

        # Add optional clauses only if valid
        sql_parts << "FINALFUNC = #{row['final_function']}" unless row['final_function'] == "-"
        sql_parts << "FINALFUNC_MODIFY = #{row['finalfunc_modify']}" if row['finalfunc_modify']
        sql_parts << "MFINALFUNC_MODIFY = #{row['mfinalfunc_modify']}" if row['mfinalfunc_modify']
        sql_parts << "COMBINEFUNC = #{row['combine_function']}" unless row['combine_function'] == "-"
        sql_parts << "SERIALFUNC = #{row['serialize_function']}" unless row['serialize_function'] == "-"
        sql_parts << "DESERIALFUNC = #{row['deserialize_function']}" unless row['deserialize_function'] == "-"
        sql_parts << "INITCOND = '#{row['initial_value']}'" if row['initial_value']

        # Close the SQL statement
        sql_parts << ");"

        # Join all parts into a single string
        create_aggregate_sql = sql_parts.join("\n  ")

        # Sanitize or validate the SQL if needed
        sanitized_sql = sanitize_aggregate_definition(create_aggregate_sql)

        OpenStruct.new(name: row['name'], definition: sanitized_sql)
      end
    end

    def sanitize_aggregate_definition(sql)
      # Remove invalid or empty clauses
      sql = sql.gsub(/, FINALFUNC =\s*\w*/, '')
               .gsub(/, FINALFUNC_MODIFY =\s*\w*/, '')
               .gsub(/, MFINALFUNC_MODIFY =\s*\w*/, '')
               .gsub(/, COMBINEFUNC =\s*\w*/, '')
               .gsub(/, SERIALFUNC =\s*\w*/, '')
               .gsub(/, DESERIALFUNC =\s*\w*/, '')

      # Remove trailing commas and clean up the SQL
      sql.gsub!(/,\s*\)/, ')')
      sql.strip
    end
  end
end
