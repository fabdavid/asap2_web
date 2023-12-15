desc '####################### Fix dashboard steps'
task fix_dashboard_steps: :environment do
  puts 'Executing...'

  now = Time.now

  Step.all.each do |s|
    
    tmp = s.dashboard_card_json
    to_del = ["{ \"key\" : \"exec_stdout\"}",
              "{ \"key\" : \"exec_stderr\"}"
             ]
    to_del.each do |e|
      tmp.gsub!(/#{e}/, '')      
    end
    tmp.gsub!(/[\,\s]+[\]]/, "\n  ]")
    puts tmp
    s.update_columns({:dashboard_card_json => tmp})
  end

end
