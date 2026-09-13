# config/initializers/typesense.rb
Typesense.configuration = {
  nodes: [{
    host: ENV.fetch('TYPESENSE_HOST', 'localhost'),
    port: ENV.fetch('TYPESENSE_PORT', '8108'),
    protocol: ENV.fetch('TYPESENSE_PROTOCOL', 'http')
  }],
  api_key: ENV.fetch('TYPESENSE_API_KEY', 'devkey'),
  connection_timeout_seconds: 2,
  log_level: :info
}
