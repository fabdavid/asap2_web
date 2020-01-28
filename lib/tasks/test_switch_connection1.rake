desc '####################### Clean'
task test_switch_connection1: :environment do
  puts 'Executing...'

  now = Time.now
  
  ConnectionSwitch.with_db(:data_with_version, 4) do
    (1 .. 100000).each do |i|
      
      all_gene_set_items = GeneSetItem.where("identifier ~ '124'").all
      puts all_gene_set_items.first(10).to_json
    end
  end
  
end
