require File.expand_path('../boot', __FILE__)

require "rails"
# Pick the frameworks you want:
require "active_model/railtie"
require "active_job/railtie"
require "active_record/railtie"
require "action_controller/railtie"
require "action_mailer/railtie"
require "action_view/railtie"
require "sprockets/railtie"
# require "rails/test_unit/railtie"

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module BusmapServer
  class Application < Rails::Application
    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration should go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded.

    # Set Time.zone default to the specified zone and make Active Record auto-convert to this zone.
    # Run "rake -D time" for a list of tasks for finding time zone names. Default is UTC.
    # config.time_zone = 'Central Time (US & Canada)'

    # The default locale is :en and all translations from config/locales/*.rb,yml are auto loaded.
    # config.i18n.load_path += Dir[Rails.root.join('my', 'locales', '*.{rb,yml}').to_s]
    # config.i18n.default_locale = :de

    # Do not swallow errors in after_commit/after_rollback callbacks.
    config.active_record.raise_in_transactional_callbacks = true

    config.i18n.load_path += Dir[Rails.root.join('config', 'locales', '**', '*.{rb,yml}').to_s]
    config.i18n.default_locale = :ja
    config.time_zone = 'Tokyo'
    config.action_view.field_error_proc = proc { |html_tag, instance| "<div class='has-error'>#{html_tag}</div>".html_safe }
    config.paths.add "app/api", glob: "**/*.rb"
    config.autoload_paths += %W(#{config.root}/app/api/*)
    config.middleware.use(Rack::Config) do |env|
      env['api.tilt.root'] = Rails.root.join "app", "views", "api"
    end

    config.middleware.insert_before 0, "Rack::Cors" do
      allow do
        origins '*'
        resource '/api/app/*',
                 :headers => :any,
                 :methods => [:get, :post, :delete, :patch, :options],
                 :expose => ['UID', 'Access-Token', 'Client', 'Expiry']
        resource '/api/auth*',
                 :headers => :any,
                 :methods => [:get, :post, :delete, :patch, :options],
                 :expose => ['UID', 'Access-Token', 'Client', 'Expiry']
      end
    end
  end
end
