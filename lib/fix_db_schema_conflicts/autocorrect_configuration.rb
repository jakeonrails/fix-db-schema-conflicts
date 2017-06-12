module FixDBSchemaConflicts
  class AutocorrectConfiguration
    def self.load
      new.load
    end

    def load
      at_least_rubocop_49? ? '.rubocop_schema.49.yml' : '.rubocop_schema.yml'
    end

    private

    def at_least_rubocop_49?
      Gem::Version.new('0.49.0') <= Gem.loaded_specs['rubocop'].version
    end
  end
end
