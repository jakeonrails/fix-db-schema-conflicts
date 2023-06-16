require 'shellwords'
require_relative '../autocorrect_configuration'

namespace :db do
  namespace :schema do
    task :dump do
      puts "Dumping database schema with fix-db-schema-conflicts gem"

      filename = ENV['SCHEMA'] || if defined? ActiveRecord::Tasks::DatabaseTasks
        File.join(ActiveRecord::Tasks::DatabaseTasks.db_dir, 'schema.rb')
      else
        "#{Rails.root}/db/schema.rb"
      end
      autocorrect_config = FixDBSchemaConflicts::AutocorrectConfiguration.load
      rubocop_yml = File.expand_path("../../../../#{autocorrect_config}", __FILE__)
      auto_correct_arg = if Gem.loaded_specs['rubocop'].version >= Gem::Version.new('1.30')
        'autocorrect'
      else
        'auto-correct'
      end

      `bundle exec rubocop --#{auto_correct_arg} --config #{rubocop_yml} #{filename.shellescape}`
    end
  end
end
