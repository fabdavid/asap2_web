desc '####################### Get data'
task get_data: :environment do
  
  Rails.logger = Logger.new('/dev/null')
  puts 'Executing...'

  now = Time.now

  input = STDIN.gets.strip
  puts Gene.count()
  
end
