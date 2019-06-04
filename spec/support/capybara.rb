require "capybara/rspec"

chrome_bin = ENV.fetch("GOOGLE_CHROME_SHIM", nil)
chrome_opts = chrome_bin ? { "chromeOptions" => { "binary" => chrome_bin } } : { "chromeOptions" => { "args" => %w[headless no-sandbox] } }

Capybara.register_driver :headless_chrome do |app|
  options = ::Selenium::WebDriver::Chrome::Options.new
  options.add_argument 'headless'
  Capybara::Selenium::Driver.new app, browser: :chrome, options: options, desired_capabilities: Selenium::WebDriver::Remote::Capabilities.chrome(chrome_opts)
end

Capybara.configure do |config|
  config.default_driver = :rack_test
  config.javascript_driver = :headless_chrome
end
