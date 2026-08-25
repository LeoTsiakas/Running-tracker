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
      TYPESENSE_CLIENT.collections['metrics'].documents.create(document_for(metric))
    end

    def update_metric(metric)
      TYPESENSE_CLIENT.collections['metrics'].documents[metric.id.to_s].update(
        document_for(metric).except(:id)
      )
    end

    def delete_metric(metric)
      TYPESENSE_CLIENT.collections['metrics'].documents[metric.id.to_s].delete
    end

    def search_metrics(query, options = {})
      search_params = {
        q: query,
        query_by: 'user_id,time,distance,date',
        sort_by: 'date:desc',
        per_page: options[:per_page] || 10,
        page: options[:page] || 1
      }

      TYPESENSE_CLIENT.collections['metrics'].documents.search(search_params)
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
  end
end
