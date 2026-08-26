class TypesenseService
  class << self
    def create_schema
      TYPESENSE_CLIENT.collections.create(
        name: 'metrics',
        fields: [
          { name: 'user_id', type: 'int32' },
          { name: 'time', type: 'int32' },
          { name: 'distance', type: 'float' },
          { name: 'date', type: 'int64' }
        ],
        default_sorting_field: 'date'
      )
    end

    def get_schema
      TYPESENSE_CLIENT.collections['metrics'].retrieve
    end

    def delete_schema
      TYPESENSE_CLIENT.collections['metrics'].delete
    end

    def export_documents
      TYPESENSE_CLIENT.collections['metrics'].documents.export
    end

    def retrieve_document(id)
      TYPESENSE_CLIENT.collections['metrics'].documents[id.to_s].retrieve
    end

    def index_metric(metric)
      TYPESENSE_CLIENT.collections['metrics'].documents.upsert(document_for(metric))
    end

    def update_metric(metric)
      TYPESENSE_CLIENT.collections['metrics'].documents[metric.id.to_s].update(
        document_for(metric).except(:id)
      )
    end

    def delete_metric(metric)
      TYPESENSE_CLIENT.collections['metrics'].documents[metric.id.to_s].delete
    end

    def search_metrics_by_date(user, range, options = {})
      start_at, end_at = parse_date_range(range, user)
      return { 'hits' => [] } if start_at.nil? || end_at.nil?

      TYPESENSE_CLIENT.collections['metrics'].documents.search(
        q: '*',
        filter_by: "user_id:=#{user.id} && date:[#{start_at.to_i}..#{end_at.to_i}]",
        sort_by: 'date:desc',
        per_page: options[:per_page] || 250,
        page: options[:page] || 1
      )
    end

    def documents_count
      get_schema['num_documents']
    end

    private

    def document_for(metric)
      {
        id: metric.id.to_s,
        user_id: metric.user_id.to_i,
        time: metric.time.to_i,
        distance: metric.distance.to_f,
        date: metric.date.to_i
      }
    end

    def parse_date_range(range, user)
      from, to = range.to_s.split(' - ').map(&:strip)

      Time.use_zone(zone_for(user)) do
        start_at = parse_time(from)
        end_at = parse_time(to)
        [start_at&.beginning_of_day, end_at&.end_of_day]
      end
    end

    def zone_for(user)
      user&.time_zone.presence || Time.zone.name
    end

    def parse_time(value)
      return if value.blank?

      begin
        Time.zone.strptime(value, '%m/%d/%Y')
      rescue ArgumentError
        Time.zone.parse(value)
      end
    end
  end
end
