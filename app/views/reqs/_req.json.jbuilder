json.extract! req, :id, :created_at, :updated_at
json.url req_url(req, format: :json)
