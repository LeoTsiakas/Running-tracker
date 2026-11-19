require 'test_helper'

class MetricTest < ActiveSupport::TestCase
  def build_metric(**attrs)
    Metric.new({ time: 2600, date: Date.today, distance: 5.0, user: users(:one) }.merge(attrs))
  end

  test 'is valid with valid attributes' do
    assert build_metric.valid?
  end

  test 'is invalid without distance' do
    metric = build_metric(distance: nil)
    assert_not metric.valid?
    assert_includes metric.errors[:distance], "can't be blank"
  end

  test 'is invalid without time' do
    metric = build_metric(time: nil)
    assert_not metric.valid?
    assert_includes metric.errors[:time], "can't be blank"
  end

  test 'is invalid without date' do
    metric = build_metric(date: nil)
    assert_not metric.valid?
    assert_includes metric.errors[:date], "can't be blank"
  end

  test 'is invalid without a user' do
    metric = build_metric(user: nil)
    assert_not metric.valid?
    assert_includes metric.errors[:user], 'must exist'
  end

  test 'is invalid with a non-numeric distance' do
    metric = build_metric(distance: 'abc')
    assert_not metric.valid?
    assert_includes metric.errors[:distance], 'is not a number'
  end

  test 'is invalid with zero distance' do
    metric = build_metric(distance: 0)
    assert_not metric.valid?
    assert_includes metric.errors[:distance], 'must be greater than 0'
  end

  test 'is invalid with negative distance' do
    metric = build_metric(distance: -3.5)
    assert_not metric.valid?
    assert_includes metric.errors[:distance], 'must be greater than 0'
  end

  test 'is invalid with a date in the future' do
    metric = build_metric(date: 1.day.from_now)
    assert_not metric.valid?
    assert_includes metric.errors[:date], "can't be in the future"
  end

  test 'is valid with a date in the past' do
    assert build_metric(date: 1.week.ago).valid?
  end

  test 'is valid when the wall-clock date has already passed in the user time zone' do
    travel_to Time.utc(2026, 10, 15, 12, 0) do
      # 18:00 is still ahead in UTC, but in Tokyo (UTC+9) 18:00 was 09:00 UTC.
      users(:one).time_zone = 'Tokyo'
      assert build_metric(date: Time.utc(2026, 10, 15, 18, 0)).valid?
    end
  end

  test 'is invalid when the wall-clock date is still ahead in the user time zone' do
    travel_to Time.utc(2026, 10, 15, 12, 0) do
      # 06:00 has passed in UTC, but in Hawaii (UTC-10) 06:00 is 16:00 UTC.
      users(:one).time_zone = 'Hawaii'
      metric = build_metric(date: Time.utc(2026, 10, 15, 6, 0))
      assert_not metric.valid?
      assert_includes metric.errors[:date], "can't be in the future"
    end
  end

  test 'checks a future date in the app time zone when there is no user' do
    travel_to Time.utc(2026, 10, 15, 12, 0) do
      metric = build_metric(user: nil, date: Time.utc(2026, 10, 15, 13, 0))
      assert_not metric.valid?
      assert_includes metric.errors[:date], "can't be in the future"
    end
  end

  test 'ordered returns metrics oldest first' do
    assert_equal [metrics(:two), metrics(:one)], users(:one).metrics.ordered.to_a
  end

  test 'indexes the date in Typesense as epoch seconds so range filters can compare it' do
    metric = build_metric(date: Time.utc(2026, 10, 1, 7, 30))

    document = Metric.typesense_settings.get_attributes(metric)

    assert_equal Time.utc(2026, 10, 1, 7, 30).to_i, document['date']
    assert_equal({ 'user_id' => users(:one).id, 'time' => 2600, 'distance' => 5.0 }, document.except('date'))
  end
end
