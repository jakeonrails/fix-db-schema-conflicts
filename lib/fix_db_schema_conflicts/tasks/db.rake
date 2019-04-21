require 'shellwords'
require_relative '../autocorrect_configuration'

Rake::Task['db:schema:dump'].enhance do
  puts "Dumping database schema with fix-db-schema-conflicts gem"

  schema_filename = ENV['SCHEMA'] || if defined? ActiveRecord::Tasks::DatabaseTasks
    File.join(ActiveRecord::Tasks::DatabaseTasks.db_dir, 'schema.rb')
  else
    "#{Rails.root}/db/schema.rb"
  end
  autocorrect_config = FixDBSchemaConflicts::AutocorrectConfiguration.load
  rubocop_yml = File.expand_path("../../../../#{autocorrect_config}", __FILE__)
  `bundle exec rubocop --auto-correct --config #{rubocop_yml} #{schema_filename.shellescape}`
end
