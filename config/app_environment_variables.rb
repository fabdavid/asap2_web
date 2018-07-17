# This is used by Docker Compose to set up prefix names for Docker images,
# containers, volumes and networks. This ensures that everything is named
# consistently regardless of your folder structure.
ENV['COMPOSE_PROJECT_NAME']='asap2'

# What Rails environment are we in?
ENV['RAILS_ENV']='development'

# Rails log level.
#   Accepted values: debug, info, warn, error, fatal, or unknown
ENV['LOG_LEVEL']='debug'

# You would typically use `rails secret` to generate a secure token. It is
# critical that you keep this value private in production.
ENV['SECRET_TOKEN']='asecuretokenwouldnormallygohere'

# More details about these Puma variables can be found in config/puma.rb.
# Which address should the Puma app server bind to?
ENV['BIND_ON']='0.0.0.0:3000'

# Puma supports multiple threads but in development mode you'll want to use 1
# thread to ensure that you can properly debug your application.
ENV['RAILS_MAX_THREADS']=1

# Puma supports multiple workers but you should stick to 1 worker in dev mode.
ENV['WEB_CONCURRENCY']=1

# Requests that exceed 5 seconds will be terminated and dumped to a stacktrace.
# Feel free to modify this value to fit the needs of your project, but if you
# have any request that takes more than 5 seconds you probably need to re-think
# what you are doing 99.99% of the time.
ENV['REQUEST_TIMEOUT']=5

# Required by the Postgres Docker image. This sets up the initial database when
# you first run it.
ENV['POSTGRES_USER']='postgres'
ENV['POSTGRES_PASSWORD']='yourpassword'
ENV['POSTGRES_DB']='asap2'

# The database name will automatically get the Rails environment appended to it
# such as: asap2_development or asap2_production.
ENV['DATABASE_URL']='postgresql://postgres:yourpassword@postgres:5432/asap2?encoding=utf8&pool=5&timeout=5000'

# The full Redis URL for the Redis cache. The last segment is the namespace.
ENV['REDIS_CACHE_URL']='redis://:yourpassword@redis:6379/0/cache'

# Action mailer (e-mail) settings.
# You will need to enable less secure apps in your Google account if you plan
# to use GMail as your e-mail SMTP server.
# You can do that here: https://www.google.com/settings/security/lesssecureapps
ENV['SMTP_ADDRESS']='smtp.gmail.com'
ENV['SMTP_PORT']=587
ENV['SMTP_DOMAIN']='gmail.com'
ENV['SMTP_USERNAME']='you@gmail.com'
ENV['SMTP_PASSWORD']='yourpassword'
ENV['SMTP_AUTH']='plain'
ENV['SMTP_ENABLE_STARTTLS_AUTO']=true

# Not running Docker natively? Replace 'localhost' with your Docker Machine IP
# address, such as: 192.168.99.100:3000
ENV['ACTION_MAILER_HOST']='localhost:3000'
ENV['ACTION_MAILER_DEFAULT_FROM']='you@gmail.com'
ENV['ACTION_MAILER_DEFAULT_TO']='you@gmail.com'

# Google Analytics universal ID. You should only set this in non-development
# environments. You wouldn't want to track development mode requests in GA.
# GOOGLE_ANALYTICS_UA='xxx'

# The full Redis URL for Active Job.
ENV['ACTIVE_JOB_URL']='redis://:yourpassword@redis:6379/0
'
# The queue prefix for all Active Jobs. The Rails environment will
# automatically be added to this value.
ENV['ACTIVE_JOB_QUEUE_PREFIX']='asap2:jobs'

# The full Redis URL for Action Cable's back-end.
ENV['ACTION_CABLE_BACKEND_URL']='redis://:yourpassword@redis:6379/0'

# The full WebSocket URL for Action Cable's front-end.
# Not running Docker natively? Replace 'localhost' with your Docker Machine IP
# address, such as: ws://192.168.99.100:28080
ENV['ACTION_CABLE_FRONTEND_URL']='ws://localhost:28080'

# Comma separated list of RegExp origins to allow connections from.
# These values will be converted into a proper RegExp, so omit the / /.
#
# Examples:
#   http:\/\/localhost*
#   http:\/\/example.*,https:\/\/example.*
#
# Not running Docker natively? Replace 'localhost' with your Docker Machine IP
# address, such as: http:\/\/192.168.99.100*
ENV['ACTION_CABLE_ALLOWED_REQUEST_ORIGINS']='http:\/\/localhost*'
