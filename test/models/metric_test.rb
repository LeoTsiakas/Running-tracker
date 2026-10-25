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
end
