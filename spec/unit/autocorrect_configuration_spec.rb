require 'spec_helper'
require 'fix_db_schema_conflicts/autocorrect_configuration'

RSpec.describe FixDBSchemaConflicts::AutocorrectConfiguration do
  subject(:autocorrect_config) { described_class }

  it 'for versions up to 0.49.0' do
    allow(Gem).to receive_message_chain(:loaded_specs, :[], :version)
      .and_return(Gem::Version.new('0.38.0'))

    expect(autocorrect_config.load).to eq('.rubocop_schema.yml')
  end

  it 'for versions 0.49.0 and above' do
    allow(Gem).to receive_message_chain(:loaded_specs, :[], :version)
      .and_return(Gem::Version.new('0.49.0'))

    expect(autocorrect_config.load).to eq('.rubocop_schema.49.yml')
  end
end
