ENV["RAILS_ENV"] ||= "test"
if ENV["TEST_COVERAGE"] && !ENV["TEST_COVERAGE"].empty?
  require "simplecov"
  require "simplecov-lcov"
  SimpleCov::Formatter::LcovFormatter.config.report_with_single_file = true
  SimpleCov::Formatter::LcovFormatter.config do |config|
    config.output_directory = "coverage"
    config.lcov_file_name = "lcov.info"
  end
  SimpleCov.formatter = SimpleCov::Formatter::LcovFormatter
  SimpleCov.start("rails")
end
require File.expand_path("../../config/environment", __FILE__)
abort("The Rails environment is running in production mode!") if Rails.env.production?

require "rspec/rails"
require "spec_helper"
require "custom_spec_helper"
require "capybara/rails"
require "capybara/rspec"
require "selenium/webdriver"
require "view_component/test_helpers"

module ViewComponent
  module TestHelpers
    def sign_in(user)
      allow(controller).to receive(:current_user).and_return(user)
    end

    def within(...)
      raise "`within` doesn't work in component tests. Use `page.find` instead."
    end
  end
end

RSpec.configure do |config|
  config.include ViewComponent::TestHelpers, type: :component
end

Rails.application.load_tasks if Rake::Task.tasks.empty?

include Warden::Test::Helpers
Warden.test_mode!

ActiveRecord::Migration.maintain_test_schema!

RSpec.configure do |config|
  config.infer_spec_type_from_file_location!
  config.after do
    Warden.test_reset!
  end
end

FactoryBot.use_parent_strategy = false

Capybara.register_driver :headless_chrome do |app|
  capabilities = Selenium::WebDriver::Remote::Capabilities.chrome(
    "goog:chromeOptions" => {
      args: %W[headless no-sandbox window-size=1200,800 proxy-server=#{Capybara.app_host}:#{Capybara::Webmock.port_number}]
    }
  )

  Capybara::Selenium::Driver.new(
    app,
    browser: :chrome,
    capabilities: capabilities
  )
end

Capybara.exact = true
Capybara.enable_aria_label = true
Capybara.disable_animation = true

OmniAuth.config.test_mode = true

def with_subdomain(subdomain, &block)
  app_host = Capybara.app_host

  begin
    Capybara.app_host = "http://#{subdomain}.lvh.me"
    block.call
  ensure
    Capybara.app_host = app_host
  end
end
