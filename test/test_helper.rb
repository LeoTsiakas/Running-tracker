ENV['RAILS_ENV'] ||= 'test'
require_relative '../config/environment'
require 'rails/test_help'
require 'minitest/mock'
require 'sidekiq/testing'

Sidekiq::Testing.fake!

module ActiveSupport
  class TestCase
    # Run tests in parallel with specified workers
    parallelize(workers: :number_of_processors)

    # Setup all fixtures in test/fixtures/*.yml for all tests in alphabetical order.
    fixtures :all

    # Turn off Typesense auto-indexing for tests that don't need it
    setup { Metric.typesense_without_auto_index_scope = true }
    teardown { Metric.typesense_without_auto_index_scope = false }

    # Stand-in for the objects strava-ruby-client returns (token responses and
    # activities), which only need to answer a few readers.
    def strava_response(**attrs)
      Struct.new(*attrs.keys, keyword_init: true).new(**attrs)
    end
  end
end

module ActionDispatch
  class IntegrationTest
    include Devise::Test::IntegrationHelpers
  end
end
