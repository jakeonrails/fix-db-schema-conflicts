namespace :db do
  namespace :schema do
    task :dump do
      puts "Dumping database schema with fix-db-schema-conflicts gem"
      filename = ENV['SCHEMA'] || File.join(ActiveRecord::Tasks::DatabaseTasks.db_dir, 'schema.rb')
      rubocop_yml = File.expand_path('../../../.rubocop_schema.yml', __FILE__)
      `rubocop --auto-correct --config #{rubocop_yml} #{filename}`
      `sed -E -e 's/, +/, /g' #{filename} > db/schema.fixed.rb`
      `mv db/schema.fixed.rb #{filename}`
    end
  end
end
