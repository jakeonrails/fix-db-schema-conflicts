# fix-db-schema-conflicts

It prevents db/schema.rb conflicts in your Rails projects when working with multiple team members.

Specifically the situation that goes like this:

John is working on a feature, and adds a migration to create an `updated_at` timestamp to `Task`.
Sara is working on a different feature, and adds a migration to create a `name` column to `Task`.
They both run their migrations locally, and then get a new copy of master with the other's feature and migration.
Then when they run migrations again, John's `tasks` table looks like this:

    t.timestamp :updated_at
    t.string :name

And Sara's looks like this:

    t.string :name
    t.timestamp :updated_at

And every time they run migrations before committing new code, their `db/schema.rb` file will be showing a change, because they are flipping the order of the columns.

By using the fix-db-schema-conflicts gem, this problem goes away.

## How it works

This gem sorts the table, index, and foreign key names before outputting them to the schema.rb file. Additionally it runs Rubocop with the auto-correct flag to ensure a consistent output format. Then it runs `sed` to cleanup additional horizontal whitespace inserted by Rails.

## Usage

You don't have to do anything different. It should just work. Simply run `rake db:migrate` or `rake db:schema:dump` as you would before and `fix-db-schema-conflicts` will do the rest.

## Installation

Add this line to your application's Gemfile in your development group:

```ruby
gem 'fix-db-schema-conflicts'
```

And then execute:

    $ bundle

## Older versions of Rubocop:

If you wish to use a version of Rubocop `< 0.36.0` or below, use `gem 'fix-db-schema-conflicts', '~> 1.0.2'`

## Contributing

1. Fork it ( https://github.com/[my-github-username]/fix-db-schema-conflicts/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request
