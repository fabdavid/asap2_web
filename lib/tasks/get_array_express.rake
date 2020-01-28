desc '####################### Get GSE'
task :get_array_express, [:array_express_id] => [:environment] do |t, args|
  puts 'Executing...'

  require 'mechanize'

  now = Time.now

  Fetch.fetch_array_express(args[:array_express_id])
  
end
