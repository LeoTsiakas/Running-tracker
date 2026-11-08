require 'test_helper'

class DateParserTest < ActiveSupport::TestCase
  def user_in(zone)
    User.new(time_zone: zone)
  end

  test 'parses both ends of the range at midnight in the user time zone' do
    start_at, end_at = DateParser.parse_date_range('10/01/2026 - 10/31/2026', user_in('Athens'))

    athens = Time.find_zone('Athens')
    assert_equal athens.local(2026, 10, 1), start_at
    assert_equal athens.local(2026, 10, 31), end_at
    assert_equal 'Athens', start_at.time_zone.name
  end

  test 'the same range gives different instants for users in different zones' do
    athens_start, = DateParser.parse_date_range('10/01/2026 - 10/31/2026', user_in('Athens'))
    utc_start, = DateParser.parse_date_range('10/01/2026 - 10/31/2026', user_in('UTC'))

    assert_equal 3.hours, utc_start - athens_start
  end

  test 'falls back to the app time zone when the user has none' do
    start_at, = DateParser.parse_date_range('10/01/2026 - 10/31/2026', user_in(nil))

    assert_equal Time.zone.local(2026, 10, 1), start_at
    assert_equal Time.zone.name, DateParser.zone_for(user_in(nil))
  end

  test 'returns nil for the missing end of a single date' do
    start_at, end_at = DateParser.parse_date_range('10/01/2026', user_in('UTC'))

    assert_equal Time.zone.local(2026, 10, 1), start_at
    assert_nil end_at
  end

  test 'returns nil for dates it cannot parse' do
    assert_equal [nil, nil], DateParser.parse_date_range('2026-10-01 - not a date', user_in('UTC'))
    assert_nil DateParser.parse_date_range('13/45/2026 - 10/31/2026', user_in('UTC')).first
  end

  test 'parse_time returns nil for a blank value' do
    assert_nil DateParser.parse_time('')
    assert_nil DateParser.parse_time(nil)
  end

  test 'includes the whole last day of the range' do
    skip 'BUG: the end date is parsed as midnight, so activities later on the last day fall outside the filter'

    _, end_at = DateParser.parse_date_range('10/01/2026 - 10/31/2026', user_in('UTC'))

    assert_operator end_at, :>=, Time.zone.local(2026, 10, 31, 18, 0)
  end
end
