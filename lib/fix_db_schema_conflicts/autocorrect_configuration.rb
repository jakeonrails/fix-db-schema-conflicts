module FixDBSchemaConflicts
  class AutocorrectConfiguration
    def self.load
      new.load
    end

    def load
      if at_least_rubocop_53?
        '.rubocop_schema.53.yml'
      elsif at_least_rubocop_49?
        '.rubocop_schema.49.yml'
      else
        '.rubocop_schema.yml'
      end
    end

    private

    def at_least_rubocop_53?
      Gem::Version.new('0.53.0') <= Gem.loaded_specs['rubocop'].version
    end

    def at_least_rubocop_49?
      Gem::Version.new('0.49.0') <= Gem.loaded_specs['rubocop'].version
    end
  end
end
