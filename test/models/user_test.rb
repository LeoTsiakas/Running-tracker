require 'test_helper'

class UserTest < ActiveSupport::TestCase
  def build_user(**attrs)
    User.new({ username: 'runner', email: 'runner@example.com', password: 'secret123', time_zone: 'UTC' }.merge(attrs))
  end

  test 'is valid with valid attributes' do
    assert build_user.valid?
  end

  test 'is invalid without email' do
    user = build_user(email: nil)
    assert_not user.valid?
    assert_includes user.errors[:email], "can't be blank"
  end

  test 'is invalid with a malformed email' do
    user = build_user(email: 'not-an-email')
    assert_not user.valid?
    assert_includes user.errors[:email], 'is invalid'
  end

  test 'is invalid with an email that is already taken' do
    user = build_user(email: users(:one).email.upcase)
    assert_not user.valid?
    assert_includes user.errors[:email], 'has already been taken'
  end

  test 'is invalid without password' do
    user = build_user(password: nil)
    assert_not user.valid?
    assert_includes user.errors[:password], "can't be blank"
  end

  test 'is invalid with a too short password' do
    user = build_user(password: '12345')
    assert_not user.valid?
    assert_includes user.errors[:password], 'is too short (minimum is 6 characters)'
  end

  test 'is invalid when password confirmation does not match' do
    user = build_user(password_confirmation: 'different')
    assert_not user.valid?
    assert_includes user.errors[:password_confirmation], "doesn't match Password"
  end

  test 'is invalid without time zone' do
    user = build_user(time_zone: '')
    assert_not user.valid?
    assert_includes user.errors[:time_zone], "can't be blank"
  end

  test 'normalizes an IANA time zone to its ActiveSupport name' do
    user = build_user(time_zone: 'Europe/Athens')
    user.valid?
    assert_equal 'Athens', user.time_zone
  end

  test 'keeps a time zone that is already an ActiveSupport name' do
    user = build_user(time_zone: 'Athens')
    user.valid?
    assert_equal 'Athens', user.time_zone
  end

  test 'normalizes a blank time zone to nil' do
    user = build_user(time_zone: '   ')
    user.valid?
    assert_nil user.time_zone
  end

  test 'builds metric by registered_at' do
    user = users(:one)
    metric1 = metrics(:one)
    metric2 = metrics(:two)

    expected_hash = {
      metric1.date.utc => metric1,
      metric2.date.utc => metric2
    }

    assert_equal expected_hash, user.metrics_by_registered_at
  end
end
