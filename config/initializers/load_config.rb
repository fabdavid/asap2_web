raw_config = File.read("#{Rails.root}/config/config.yml")
APP_CONFIG = YAML.load(raw_config)[Rails.env].symbolize_keys if YAML.load(raw_config)[Rails.env]
APP_CONFIG ||= YAML.load(raw_config)['development'].symbolize_keys
