module FixDBSchemaConflicts
  class AutocorrectConfiguration
    def self.load
      new.load
    end

    def load
      if less_than_rubocop?("0.49.0")
        '.rubocop_schema.yml'
      elsif less_than_rubocop?("0.53.0")
        '.rubocop_schema.0-49-0.yml'
      elsif less_than_rubocop?("1.0.0")
        '.rubocop_schema.0-53-0.yml'
      else
        '.rubocop_schema.1-0-0.yml'
      end
    end

    private

    def less_than_rubocop?(ver)
      Gem.loaded_specs['rubocop'].version < Gem::Version.new(ver)
    end
  end
end
