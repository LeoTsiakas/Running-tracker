require 'test_helper'

class MetricTest < ActiveSupport::TestCase
  test 'should not save metric without distance' do
    metric = Metric.new(time: 2600, date: Date.today, distance: nil, user_id: users(:one).id)
    assert_not metric.save
  end
end
