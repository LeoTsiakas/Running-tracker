class DateParser
  class << self
    def parse_date_range(range, user)
      start_at, end_at = range.split(' - ')

      Time.use_zone(zone_for(user)) { [parse_time(start_at), parse_time(end_at)] }
    end

    def zone_for(user)
      user.time_zone || Time.zone.name
    end

    def parse_time(value)
      return if value.blank?

      begin
        Time.zone.strptime(value, '%m/%d/%Y')
      rescue ArgumentError
        nil
      end
    end
  end
end
