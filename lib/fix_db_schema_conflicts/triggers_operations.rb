# frozen_string_literal: true
require 'delegate'

module FixDBSchemaConflicts
  class TriggersOperations
    def initialize(connection)
      @connection = connection
      @reset_done = false
    end

    def triggers_creation(table_name, stream, *args)
      triggers = @connection.triggers(table_name)
      unless triggers.empty?
        triggers.each do |trigger|
          add_triggers_in_file(table_name, trigger.definition)
        end
        stream.puts("\ttrigger_file = Rails.root.join('db', 'triggers', \"#{table_name}.sql\")")
        stream.puts("\tfile_content = File.read(trigger_file)")
        stream.puts("\texecute file_content")
      end
    end

    def reset_triggers_folder
      return if @reset_done

      dir_path = Rails.root.join('app', 'triggers')
      FileUtils.rm_rf Dir.glob("#{dir_path}/*") if dir_path.present?
      @reset_done = true
    end

    private

    def add_triggers_in_file(file_name, trigger_content)
      triggers_path = Rails.root.join('db', 'triggers')
      FileUtils.mkdir_p triggers_path unless triggers_path.exist?
      file_path = triggers_path.join("#{file_name}.sql")
      File.open(file_path, "w") {}
      File.open(file_path, 'a') do |file|
        formatted_sql = format_trigger(trigger_content)
        file.write(formatted_sql + ";")
        file.puts
        file.puts
      end
    end

    def format_trigger(trigger_content)
      trigger_content = trigger_content.gsub(/\n+/, "\n") # Remove extra blank lines
                                       .gsub(/^\s+/m, '') # Trim leading spaces for each line
                                       .strip # Remove leading/trailing blank lines
      trigger_content.gsub(/(?=\b(AFTER|BEFORE|FOR EACH ROW|WHEN|EXECUTE FUNCTION)\b)/, "\n")
    end
  end
end
