require 'spec_helper'
require 'fix_db_schema_conflicts/autocorrect_configuration'

RSpec.describe FixDBSchemaConflicts::AutocorrectConfiguration do
  subject(:autocorrect_config) { described_class }

  it 'for versions up to 0.49.0' do
    installed_rubocop(version: '0.39.0')

    expect(autocorrect_config.load).to eq('.rubocop_schema.yml')
  end

  it 'for versions 0.49.0 and above' do
    installed_rubocop(version: '0.49.0')

    expect(autocorrect_config.load).to eq('.rubocop_schema.0-49-0.yml')
  end

  it 'for versions 0.53.0 and above' do
    installed_rubocop(version: '0.53.0')

    expect(autocorrect_config.load).to eq('.rubocop_schema.0-53-0.yml')
  end

  it 'for versions 1.0.0 and above' do
    installed_rubocop(version: '1.0.0')

    expect(autocorrect_config.load).to eq('.rubocop_schema.1-0-0.yml')
  end

  def installed_rubocop(version:)
    allow(Gem).to receive_message_chain(:loaded_specs, :[], :version)
      .and_return(Gem::Version.new(version))
  end
end
