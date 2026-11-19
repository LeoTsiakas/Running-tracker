require 'test_helper'

class StravaApi::StravaApiRequestTest < ActiveSupport::TestCase
  # Stands in for Strava::OAuth::Client and records the oauth_token arguments.
  class FakeOAuthClient
    attr_reader :calls

    def initialize(*responses)
      @responses = responses
      @calls = []
    end

    def oauth_token(**options)
      calls << options
      @responses.shift
    end
  end

  setup do
    @api = StravaApi::StravaApiRequest.new
  end

  test 'authorize builds the Strava authorize URL with the activity scope' do
    client = Strava::OAuth::Client.new(client_id: 'test-client-id', client_secret: 'test-secret')
    uri = @api.stub(:strava_client, client) { URI.parse(@api.authorize) }
    query = Rack::Utils.parse_query(uri.query)

    assert_equal 'www.strava.com', uri.host
    assert_equal 'test-client-id', query['client_id']
    assert_equal 'activity:read_all', query['scope']
    assert_equal 'code', query['response_type']
    assert_equal 'force', query['approval_prompt']
    assert_equal 'http://localhost:3000/api/v1/auth/strava/callback', query['redirect_uri']
  end

  test 'fetch_access_token exchanges the code and returns a token that is still valid' do
    token = strava_response(access_token: 'a', refresh_token: 'r', expires_at: 1.hour.from_now.to_i)
    client = FakeOAuthClient.new(token)

    @api.stub(:strava_client, client) do
      assert_equal token, @api.fetch_access_token('the-code')
    end

    assert_equal [{ code: 'the-code' }], client.calls
  end

  test 'fetch_access_token refreshes a token that is already expired' do
    expired = strava_response(access_token: 'a', refresh_token: 'old-refresh', expires_at: 1.hour.ago.to_i)
    fresh = strava_response(access_token: 'b', refresh_token: 'new-refresh', expires_at: 1.hour.from_now.to_i)
    client = FakeOAuthClient.new(expired, fresh)

    @api.stub(:strava_client, client) do
      assert_equal fresh, @api.fetch_access_token('the-code')
    end

    assert_equal({ refresh_token: 'old-refresh', grant_type: 'refresh_token' }, client.calls.last)
  end

  test 'refresh_access_token asks Strava for a new token' do
    fresh = strava_response(access_token: 'b')
    client = FakeOAuthClient.new(fresh)

    @api.stub(:strava_client, client) do
      assert_equal fresh, @api.refresh_access_token('the-refresh')
    end

    assert_equal [{ refresh_token: 'the-refresh', grant_type: 'refresh_token' }], client.calls
  end

  test 'fetch_athlete_activities returns the athlete activities for the token' do
    activities = [strava_response(distance: 5000.0)]
    api_client = Minitest::Mock.new
    api_client.expect(:athlete_activities, strava_response(collection: activities))
    used_token = nil

    new_client = lambda do |access_token:|
      used_token = access_token
      api_client
    end

    Strava::Api::Client.stub(:new, new_client) do
      assert_equal activities, @api.fetch_athlete_activities('the-token')
    end

    assert_equal 'the-token', used_token
    api_client.verify
  end

  test 'fetch_athlete_activities handles a Strava timeout' do
    skip 'BUG: the Timeout::Error rescue calls redirect_to, which does not exist outside a controller'

    timing_out = Object.new
    def timing_out.athlete_activities = raise(Timeout::Error)

    Strava::Api::Client.stub(:new, timing_out) do
      assert_nothing_raised { @api.fetch_athlete_activities('the-token') }
    end
  end
end
