class MetricDecorator < ApplicationDecorator
  delegate_all

  def time
    hours = object.time / 3600 > 0 ? "#{object.time / 3600}h" : ""

    if hours.to_i >= 1
      remaining_minutes = object.time % 3600
      minutes           = remaining_minutes / 60 > 0 ? "#{remaining_minutes / 60}min" : ""
      seconds           = remaining_minutes % 60 > 0 ? "#{remaining_minutes % 60}sec" : ""
    else
      minutes = object.time / 60 > 0 ? "#{object.time / 60}min" : ""
      seconds = object.time % 60 > 0 ? "#{object.time % 60}sec" : ""
    end

    "#{hours} #{minutes} #{seconds}"
  end

  def distance
    "#{object.distance} km"
  end
end