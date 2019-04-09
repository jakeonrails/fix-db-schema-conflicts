require 'shellwords'
require_relative '../autocorrect_configuration'

Rake::Task['db:schema:dump'].enhance do
  # Copied from active_record/railties/databases.rake
  filename = ENV['SCHEMA'] || File.join(ActiveRecord::Tasks::DatabaseTasks.db_dir, 'schema.rb')

  puts 'Dumping database schema with fix-db-schema-conflicts gem'

  autocorrect_config = FixDBSchemaConflicts::AutocorrectConfiguration.load
  rubocop_yml = File.expand_path("../../../../#{autocorrect_config}", __FILE__)
  `bundle exec rubocop --auto-correct --config #{rubocop_yml} #{filename.shellescape}`
end
