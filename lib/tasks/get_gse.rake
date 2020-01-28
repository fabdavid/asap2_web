desc '####################### Get GSE'
task :get_gse, [:gse] => [:environment] do |t, args|
  puts 'Executing...'

  require 'mechanize'

  now = Time.now

  Fetch.fetch_gse(args[:gse])
  
end
