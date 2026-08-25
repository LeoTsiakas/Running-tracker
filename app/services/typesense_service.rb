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

    def export_documents
      TYPESENSE_CLIENT.collections['metrics'].documents.export
    end

    def retrieve_document(id)
      TYPESENSE_CLIENT.collections['metrics'].documents[id.to_s].retrieve
    end

    def index_metric(metric)
      TYPESENSE_CLIENT.collections['metrics'].documents.create(
        {
          id: metric.id.to_s,
          user_id: metric.user_id.to_i,
          time: metric.time.to_i,
          distance: metric.distance.to_f,
          date: metric.date.to_i
        }
      )
    end

    def documents_count
      get_schema['num_documents']
    end
  end
end
