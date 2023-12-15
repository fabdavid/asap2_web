desc '####################### Fix aliases of annots'
task fix_aliases_annots: :environment do
  puts 'Executing...'

  now = Time.now
  
  Project.all.each do |p|
    
    p.annots.select{|a| a.cat_aliases_json and a.cat_aliases_json.match(/wrap/)}.each do |a|
     h_cats = Basic.safe_parse_json(a.cat_aliases_json, {})
    # puts h_cats.to_json
      new_h_cats = {'names' => {}, 'user_ids' => {}}
      ['names', 'user_ids'].each do |l|
        h_cats[l].each_key do |k|
          if m = k.match(/<div class="wrap">(\w+)<\/div>/)
           # puts m[1]
            new_h_cats[l][m[1]] = h_cats[l][k]
          end	
        end
      end
      puts new_h_cats.to_json
      a.update_attribute(:cat_aliases_json, new_h_cats.to_json)
    end
    
  end
  
end
