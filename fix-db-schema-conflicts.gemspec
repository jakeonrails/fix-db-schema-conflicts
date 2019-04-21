# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'fix_db_schema_conflicts/version'

Gem::Specification.new do |spec|
  spec.name          = 'fix-db-schema-conflicts'
  spec.version       = FixDBSchemaConflicts::VERSION
  spec.authors       = ['Jake Moffatt']
  spec.email         = ['jakeonrails@gmail.com']
  spec.summary       = %q{Helps prevent unneeded db/schema.rb conflicts}
  spec.description   = %q{Ensures consistent output of db/schema.rb despite local differences in the database}
  spec.homepage      = 'https://github.com/jakeonrails/fix-db-schema-conflicts'
  spec.license       = 'MIT'

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ['lib']

  spec.add_development_dependency 'appraisal', '~>2.2'
  spec.add_development_dependency 'bundler', '~> 2.0'
  spec.add_development_dependency 'rails', '~> 5.0'
  spec.add_development_dependency 'rake', '~> 12.3'
  spec.add_development_dependency 'rspec', '~>3.8'
  spec.add_development_dependency 'sqlite3', '~> 1.3', '< 1.4'

  spec.add_dependency 'rubocop', '>= 0.38.0'

  spec.required_ruby_version = '~> 2.4'
end
