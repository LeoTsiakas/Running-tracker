TYPESENSE_CLIENT = Typesense::Client.new(
  api_key: ENV.fetch('TYPESENSE_API_KEY', 'devkey'),
  nodes: [
    {
      host: ENV.fetch('TYPESENSE_HOST', 'localhost'),
      port: ENV.fetch('TYPESENSE_PORT', 8108),
      protocol: ENV.fetch('TYPESENSE_PROTOCOL', 'http')
    }
  ],
  connection_timeout_seconds: 2
)
