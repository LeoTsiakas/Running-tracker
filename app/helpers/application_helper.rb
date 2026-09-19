module ApplicationHelper
  def build_chart_data(metrics, attribute)
    metrics.group_by_day { |metric| metric.date }.to_h do |k, metrics|
      [k, metrics.map { |metric| metric.send(attribute) }.sum]
    end
  end
end
