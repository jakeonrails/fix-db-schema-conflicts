# fix-db-schema-conflicts

It prevents db/schema.rb conflicts in your Rails projects when working with multiple team members.

## Installation

Add this line to your application's Gemfile in your development group:

```ruby
gem 'fix-db-schema-conflicts'
```

And then execute:

    $ bundle

## Usage

You don't have to do anything different. It should just work. Simply run `rake db:migrate` or `rake db:schema:dump` as you would before and `fix-db-schema-conflicts` will do the rest.

## How it works

This gem sorts the table, index, and foreign key names before outputting them to the schema.rb file. Additionally it runs Rubocop with the auto-correct flag to ensure a consistent output format. Then it runs `sed` to cleanup additional horizontal whitespace inserted by Rails.

## Contributing

1. Fork it ( https://github.com/[my-github-username]/fix-db-schema-conflicts/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request
