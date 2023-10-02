source 'https://rubygems.org'

git_source(:github) do |repo_name|
  repo_name = "#{repo_name}/#{repo_name}" unless repo_name.include?('/')
  "https://github.com/#{repo_name}.git"
end

# Looking to use the Edge version? gem 'rails', github: 'rails/rails'
#gem 'rails', '~> 5.2.0', github: "palkan/rails", branch: "fix/actioncable-confirmation-race-condition"
gem 'rails', '~> 5.2.0'

# Use Puma as the app server
gem 'puma', '~> 3.11'

# Use Rack Timeout. Read more: https://github.com/heroku/rack-timeout
#gem 'rack-timeout', '~> 0.4'

# Build JSON APIs with ease. Read more: https://github.com/rails/jbuilder
gem 'jbuilder', '~> 2.5'

# Use PostgreSQL as the database for Active Record
gem 'pg', '~> 1.0'
#gem 'db-switch'
#gem 'ar-octopus', '0.0.12', :require => "octopus"
#gem 'rails-sharding'

# Use Redis Rails to set up a Redis backed Cache and / or Session
gem 'redis-rails', '~> 5.0'

# Use Sidekiq as a background job processor through Active Job
gem 'sidekiq', '~> 5.1'

# Use Clockwork for recurring background tasks without needing cron
# gem 'clockwork', '~> 2.0'

# Use Kaminari for pagination
# gem 'kaminari', '~> 1.0'

# Use SCSS for stylesheets
gem 'sass-rails', '~> 5.0'

# Use Uglifier as the compressor for JavaScript assets
gem 'uglifier', '>= 1.3.0'

# Use jQuery as the JavaScript library
gem 'jquery-rails', '~> 4.3'

# Use Turbolinks. Read more: https://github.com/turbolinks/turbolinks
gem 'turbolinks', '~> 5'

# Use Bootstrap SASS for Bootstrap support
#gem 'bootstrap-sass', '~> 3.3'
gem 'bootstrap', '~> 4.1.3'
gem "bootstrap-switch-rails"

# Use Font Awesome Rails for Font Awesome icons
#gem 'font-awesome-rails', '~> 4.7'
gem 'fontawesome5-rails'

# Use Bootsnap to improve startup times
# gem 'bootsnap', '>= 1.1.0', require: false

gem 'devise'
gem 'aws-sdk'
#gem 'therubyracer'
gem 'jquery-ui-rails'
gem 'daemons'
gem 'delayed_job_active_record'
gem 'jquery-datatables-rails'
gem 'descriptive_statistics'
gem 'sys-proctable'
gem 'rails4-autocomplete'
gem 'jquery-fileupload-rails'
gem 'mimemagic'
gem 'paperclip'#, "6.0.0"
gem 'multipart-parser'
#gem 'haml'
gem "haml", ">= 5.0.0"
gem 'activerecord-session_store'
#gem 'hdf5'
#gem 'get_process_mem'
gem 'zlib'
gem 'biomart'
gem 'parallel'
gem 'mechanize'
gem 'hpricot'
#gem 'caxlsx_rails'
#gem 'axlsx', '~> 2.1.0.pre'
#gem 'axlsx' #, git: 'https://github.com/randym/axlsx.git', ref: 'c8ac844'
#gem 'caxlsx_rails'
#gem 'rubyzip', '= 1.1.0'
#gem 'axlsx', '= 2.1.0'
#gem 'axlsx_rails'
#gem 'shellwords'
gem 'sunspot_rails'
gem 'sunspot_solr' 

group :development, :test do
  # Call 'byebug' anywhere in your code to drop into a debugger console
  gem 'byebug', platform: :mri
end

group :test do
  # Adds support for Capybara system testing and selenium driver
  # gem 'capybara', '>= 2.15', '< 4.0'
  # gem 'selenium-webdriver'
  # Easy installation and use of chromedriver to run system tests with Chrome
  # gem 'chromedriver-helper'
end

group :development do
  # Enable a debug toolbar to help profile your application
#  gem 'rack-mini-profiler', '~> 1.0'

  # Access an IRB console on exception pages or by using <%= console %>
  gem 'web-console', '~> 3.3.0'

  # Get notified of file changes. Read more: https://github.com/guard/listen
  gem 'listen', '>= 3.0.5', '< 3.2'

  # Use Spring. Read more: https://github.com/rails/spring
  gem 'spring'
  gem 'spring-watcher-listen', '~> 2.0.0'
end

# Windows does not include zoneinfo files, so bundle the tzinfo-data gem
gem 'tzinfo-data'
