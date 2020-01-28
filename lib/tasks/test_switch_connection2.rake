desc '####################### Clean'
task test_switch_connection2: :environment do
  puts 'Executing...'

  now = Time.now
  
  (1 .. 1000).each do |i|
    puts "Number of projects: " + Project.count().to_s
  end	
end
