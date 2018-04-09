require 'spec_helper'

RSpec.describe 'Fix DB Schema Conflicts' do

  let(:expected_lines) { reference_db_schema.lines }

  it 'generates a sorted schema with no extra spacing' do

    `cd spec/test-app && rm -f db/schema.rb && rake db:migrate`

    generated_lines = File.readlines('spec/test-app/db/schema.rb')

    column_list = generated_lines.select do |line|
      line.strip.start_with?("t.")
    end

    column_names = column_list.map do |line|
      line.split(",")[0].strip.split[-1].gsub(/"/, "")
    end

    expected_names = [
      "addr1",
      "addr2",
      "city",
      "created_at",
      "name",
      "phone",
      "state",
      "updated_at",
      "zip",
      "age",
      "birthdate",
      "created_at",
      "first_name",
      "last_name",
      "updated_at"
    ]

    expect(column_names).to match expected_names
  end
end
