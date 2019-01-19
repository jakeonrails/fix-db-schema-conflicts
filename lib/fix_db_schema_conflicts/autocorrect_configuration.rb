module FixDBSchemaConflicts
  class AutocorrectConfiguration
    def self.load
      new.load
    end

    def load
      if less_than_rubocop_version?(49)
        '.rubocop_schema.yml'
      elsif less_than_rubocop_version?(53)
        '.rubocop_schema.49.yml'
      else
        '.rubocop_schema.53.yml'
      end
    end

    private

    def less_than_rubocop_version?(version)
      Gem.loaded_specs['rubocop'].version < Gem::Version.new("0.#{version}.0")
    end
  end
end
