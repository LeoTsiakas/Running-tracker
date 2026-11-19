require 'test_helper'

class MetricDecoratorTest < Draper::TestCase
  def decorated(time: 0, distance: 5.0)
    Metric.new(time: time, distance: distance).decorate
  end

  # The decorator joins the parts with spaces even when a part is empty, so the
  # comparisons squish the output.
  test 'formats seconds only' do
    assert_equal '45sec', decorated(time: 45).time.squish
  end

  test 'formats minutes and seconds' do
    assert_equal '2min 5sec', decorated(time: 125).time.squish
  end

  test 'leaves out zero seconds' do
    assert_equal '2min', decorated(time: 120).time.squish
  end

  test 'formats hours, minutes and seconds' do
    assert_equal '1h 2min 3sec', decorated(time: 3723).time
  end

  test 'leaves out zero minutes when there are hours' do
    assert_equal '1h 5sec', decorated(time: 3605).time.squish
    assert_equal '2h', decorated(time: 7200).time.squish
  end

  test 'formats a zero duration as blank' do
    assert_predicate decorated(time: 0).time, :blank?
  end

  test 'formats distance in kilometres' do
    assert_equal '5.5 km', decorated(distance: 5.5).distance
  end
end
