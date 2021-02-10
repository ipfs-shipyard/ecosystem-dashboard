Rails.application.config.middleware.insert_before 0, Rack::Cors do
  allow do
    origins '*'
    resource '*.json', headers: :any, methods: [:get, :patch]
  end
end
