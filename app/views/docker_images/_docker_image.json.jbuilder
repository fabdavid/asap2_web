json.extract! docker_image, :id, :created_at, :updated_at
json.url docker_image_url(docker_image, format: :json)
