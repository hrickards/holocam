# This file is copied to spec/ when you run 'rails generate rspec:install'
ENV['RAILS_ENV'] ||= 'test'
require 'spec_helper'
require File.expand_path('../../config/environment', __FILE__)
require 'rspec/rails'
require 'capybara/rspec'
require 'capybara/poltergeist'
# Add additional requires below this line. Rails is not loaded until this point!

# Requires supporting ruby files with custom matchers and macros, etc, in
# spec/support/ and its subdirectories. Files matching `spec/**/*_spec.rb` are
# run as spec files by default. This means that files in spec/support that end
# in _spec.rb will both be required and run as specs, causing the specs to be
# run twice. It is recommended that you do not name files matching this glob to
# end with _spec.rb. You can configure this pattern with the --pattern
# option on the command line or in ~/.rspec, .rspec or `.rspec-local`.
#
# The following line is provided for convenience purposes. It has the downside
# of increasing the boot-up time by auto-requiring all files in the support
# directory. Alternatively, in the individual `*_spec.rb` files, manually
# require only the support files necessary.
#
# Dir[Rails.root.join('spec/support/**/*.rb')].each { |f| require f }

# Checks for pending migrations before tests are run.
# If you are not using ActiveRecord, you can remove this line.
ActiveRecord::Migration.maintain_test_schema!

RSpec.configure do |config|
  # Remove this line if you're not using ActiveRecord or ActiveRecord fixtures
  config.fixture_path = "#{::Rails.root}/spec/fixtures"

	# Doesn't play well with our Redis queue
  config.use_transactional_fixtures = false

  # RSpec Rails can automatically mix in different behaviours to your tests
  # based on their file location, for example enabling you to call `get` and
  # `post` in specs under `spec/controllers`.
  #
  # You can disable this behaviour by removing the line below, and instead
  # explicitly tag your specs with their type, e.g.:
  #
  #     RSpec.describe UsersController, :type => :controller do
  #       # ...
  #     end
  #
  # The different available types are documented in the features, such as in
  # https://relishapp.com/rspec/rspec-rails/docs
  config.infer_spec_type_from_file_location!

	config.before(:suite) do
		# Clean any leftover data
    DatabaseCleaner.clean_with(:truncation)
  end

  config.before(:each) do
		DatabaseCleaner[:active_record].strategy = :transaction
		DatabaseCleaner[:redis].strategy = :truncation
  end

  config.before(:each, :js => true) do
		DatabaseCleaner[:active_record].strategy = :truncation
		DatabaseCleaner[:redis].strategy = :truncation
  end

  config.before(:each) do
    DatabaseCleaner.start
  end

  config.after(:each) do
    DatabaseCleaner.clean
  end
end

# Mock OmniAuth twitter authentication
OmniAuth.config.test_mode = true
OmniAuth.config.add_mock(:twitter, { uid: SecureRandom.uuid, nickname: Faker::Internet.user_name })
OmniAuth.config.add_mock(:facebook, { uid: SecureRandom.uuid, nickname: Faker::Internet.user_name })
OmniAuth.config.add_mock(:google, { uid: SecureRandom.uuid, nickname: Faker::Internet.user_name })

# Use phantomjs for JS testing
Capybara.javascript_driver = :poltergeist