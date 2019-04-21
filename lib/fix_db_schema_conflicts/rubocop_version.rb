module FixDBSchemaConflicts
  module RubocopVersion
    def less_than_rubocop?(ver)
      Gem.loaded_specs['rubocop'].version < Gem::Version.new("0.#{ver}.0")
    end
  end
end
