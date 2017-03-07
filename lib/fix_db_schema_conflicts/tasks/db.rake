require 'shellwords'

namespace :db do
  namespace :schema do
    task :dump do
      puts "Dumping database schema with fix-db-schema-conflicts gem"
      filename = ENV['SCHEMA'] || if defined? ActiveRecord::Tasks::DatabaseTasks
        File.join(ActiveRecord::Tasks::DatabaseTasks.db_dir, 'schema.rb')
      else
        "#{Rails.root}/db/schema.rb"
      end
      rubocop_yml = File.expand_path('../../../../.rubocop_schema.yml', __FILE__)
      `bundle exec rubocop --auto-correct --config #{rubocop_yml} #{filename.shellescape}`
    end
  end
end
