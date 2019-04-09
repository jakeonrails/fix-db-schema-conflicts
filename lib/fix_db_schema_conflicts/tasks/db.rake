require 'shellwords'
require_relative '../autocorrect_configuration'

Rake::Task['db:schema:dump'].enhance do
  puts 'Dumping database schema with fix-db-schema-conflicts gem'

  # Copied from active_record/railties/databases.rake
  filename = ENV['SCHEMA'] || File.join(ActiveRecord::Tasks::DatabaseTasks.db_dir, 'schema.rb')

  autocorrect_config = FixDBSchemaConflicts::AutocorrectConfiguration.load
  rubocop_yml = File.expand_path("../../../../#{autocorrect_config}", __FILE__)
  rubocop_options = '--only Layout,Style --safe-auto-correct  --format quiet'

  `bundle exec rubocop  #{rubocop_options} --config #{rubocop_yml} #{filename.shellescape}`
end
