require 'test_helper'

class MetricsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:one)
  end

  # Index goes through Typesense. Record what the controller asks for and hand
  # back plain records, the same shape typesense-rails returns without a
  # pagination backend.
  def stub_search(results = @user.metrics.to_a)
    calls = []
    search = lambda do |*args|
      calls << args
      results
    end

    Metric.stub(:search, search) { yield calls }
  end

  def metric_params(**overrides)
    {
      distance: 5.5,
      date: 1.day.ago.strftime('%Y-%m-%dT%H:%M'),
      duration_hours: 1,
      duration_minutes: 2,
      duration_seconds: 3
    }.merge(overrides)
  end

  # --- authentication -------------------------------------------------------

  test 'redirects guests to sign in' do
    get metrics_path
    assert_redirected_to new_user_session_path

    get new_metric_path
    assert_redirected_to new_user_session_path

    assert_no_difference('Metric.count') { post metrics_path, params: { metric: metric_params } }
    assert_redirected_to new_user_session_path

    assert_no_difference('Metric.count') { delete metric_path(metrics(:one)) }
    assert_redirected_to new_user_session_path
  end

  # --- index ----------------------------------------------------------------

  test 'index lists only the current user metrics, oldest first' do
    sign_in @user

    stub_search do |calls|
      get metrics_path

      assert_response :success
      assert_select '.card', 2

      query, query_by, options = calls.sole
      assert_equal '*', query
      assert_equal '', query_by
      assert_equal "user_id:=#{@user.id}", options[:filter_by]
      assert_equal 'date:asc', options[:sort_by]
      assert_equal 250, options[:per_page]
    end
  end

  test 'index filters by the selected date range in the user time zone' do
    @user.update_column(:time_zone, 'Athens')
    sign_in @user

    stub_search do |calls|
      get metrics_path, params: { selected_date_range: '10/01/2026 - 10/31/2026' }

      assert_response :success
      athens = Time.find_zone('Athens')
      start_at = athens.local(2026, 10, 1).to_i
      end_at = athens.local(2026, 10, 31).to_i
      assert_equal "user_id:=#{@user.id} && date:[#{start_at}..#{end_at}]", calls.sole.last[:filter_by]
    end
  end

  test 'index passes per_page through to the search' do
    sign_in @user

    stub_search do |calls|
      get metrics_path, params: { per_page: '10' }

      assert_equal '10', calls.sole.last[:per_page]
    end
  end

  test 'index paginates the search results' do
    sign_in @user
    results = Array.new(25) { |i| Metric.new(id: i + 1, user: @user, time: 60, distance: 1, date: i.days.ago) }

    stub_search(results) do
      get metrics_path

      assert_select '.card', Pagy::DEFAULT[:limit]
    end
  end

  test 'index page links keep the selected date range' do
    sign_in @user
    results = Array.new(25) { |i| Metric.new(id: i + 1, user: @user, time: 60, distance: 1, date: i.days.ago) }

    stub_search(results) do
      get metrics_path, params: { selected_date_range: '10/01/2026 - 10/31/2026' }

      page_two = css_select('a').map { |a| a['href'] }.find { |href| href.to_s.include?('page=2') }
      assert page_two, 'expected a link to page 2'
      assert_equal '10/01/2026 - 10/31/2026', Rack::Utils.parse_query(URI.parse(page_two).query)['selected_date_range']
    end
  end

  test 'index card shows the date and the duration as hh:mm:ss' do
    sign_in @user
    metric = Metric.new(id: 1, user: @user, time: 3723, distance: 5.5, date: Time.utc(2026, 10, 1, 7, 30))

    stub_search([metric]) do
      get metrics_path

      assert_select '.card', text: /2026-10-01/
      assert_select '.card span', text: '01:02:03'
      assert_select '.card span', text: '5.5'
    end
  end

  test 'index sends every search result to the charts, not just the current page' do
    sign_in @user
    results = Array.new(25) { |i| Metric.new(id: i + 1, user: @user, time: 60, distance: 1, date: i.days.ago) }

    stub_search(results) do
      get metrics_path

      chart_data = JSON.parse(css_select('[data-controller="bar-chart"]').sole['data-bar-chart-metrics-value'])
      assert_equal results.map(&:id), chart_data.pluck('id')
    end
  end

  test 'index renders the metrics as JSON' do
    skip 'BUG: respond_to runs before @metrics is assigned, so the JSON body is "null"'

    sign_in @user

    stub_search do
      get metrics_path(format: :json)

      assert_response :success
      assert_equal @user.metrics.pluck(:id).sort, response.parsed_body.pluck('id').sort
    end
  end

  # --- new ------------------------------------------------------------------

  test 'new renders the metric form' do
    sign_in @user

    get new_metric_path

    assert_response :success
    assert_select 'form[action=?]', metrics_path
    assert_select 'select[name=?]', 'metric[duration_hours]'
  end

  # --- create ---------------------------------------------------------------

  test 'create saves a metric for the current user and converts the duration to seconds' do
    sign_in @user

    assert_difference('@user.metrics.count', 1) do
      post metrics_path, params: { metric: metric_params }
    end

    assert_redirected_to root_path
    metric = @user.metrics.order(:id).last
    assert_equal 3723, metric.time
    assert_equal 5.5, metric.distance
  end

  test 'create ignores a user_id in the params' do
    sign_in @user

    post metrics_path, params: { metric: metric_params(user_id: users(:two).id) }

    assert_equal @user, Metric.order(:id).last.user
  end

  test 'create re-renders the form when the metric is invalid' do
    sign_in @user

    assert_no_difference('Metric.count') do
      post metrics_path, params: { metric: metric_params(distance: 0) }
    end

    assert_response :unprocessable_entity
    assert_select 'div', text: 'Distance must be greater than 0'
  end

  test 'create rejects a date in the future' do
    sign_in @user

    assert_no_difference('Metric.count') do
      post metrics_path, params: { metric: metric_params(date: 1.day.from_now.strftime('%Y-%m-%dT%H:%M')) }
    end

    assert_response :unprocessable_entity
  end

  test 'create re-renders the form when the duration fields are missing' do
    skip 'BUG: metrics_params calls nil * 3600 when duration_* params are absent (NoMethodError -> 500)'

    sign_in @user

    assert_no_difference('Metric.count') do
      post metrics_path, params: { metric: { distance: 5, date: 1.day.ago } }
    end

    assert_response :unprocessable_entity
  end

  # --- destroy --------------------------------------------------------------

  test 'destroy deletes the current user metric' do
    sign_in @user

    assert_difference('Metric.count', -1) { delete metric_path(metrics(:one)) }

    assert_redirected_to root_path
  end

  test 'destroy does not delete a metric that belongs to another user' do
    other_metric = users(:two).metrics.create!(time: 600, distance: 2, date: 1.day.ago)
    sign_in @user

    assert_no_difference('Metric.count') { delete metric_path(other_metric) }

    assert_redirected_to root_path
  end

  test 'destroy redirects when the metric does not exist' do
    sign_in @user

    delete metric_path(id: 0)

    assert_redirected_to root_path
  end
end
