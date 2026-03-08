# frozen_string_literal: true

Sentry.init do |config|
  config.dsn = 'https://d51bf28b14cdeb40f107b27f7e2dc8a0@o4510075954200576.ingest.de.sentry.io/4510075956691024'
  config.breadcrumbs_logger = [:active_support_logger, :http_logger]

  # Add data like request headers and IP for users,
  # see https://docs.sentry.io/platforms/ruby/data-management/data-collected/ for more info
  config.send_default_pii = true

  config.enabled_environments = %w[development production staging]
end
