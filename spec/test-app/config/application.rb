require_relative "boot"

require "rails"
require "active_record/railtie"

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module TestApp
  class Application < Rails::Application
    config.load_defaults 8.1
    config.eager_load = false
  end
end
