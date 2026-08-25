namespace :typesense do
  task export_metrics: :environment do
    Metric.find_each do |metric|
      TypesenseService.index_metric(metric)
    end
  end
end
