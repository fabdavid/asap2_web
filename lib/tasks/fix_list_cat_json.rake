desc '####################### Fix list_cat_json'
task fix_list_cat_json: :environment do
  puts 'Executing...'

  now = Time.now

  Project.all.each do |p|
    p.annots.map{|a|
      categories = Basic.safe_parse_json(a.categories_json, {})
      if categories and categories.is_a? Hash
        nber_int = categories.keys.select{|k| k.match(/^-?\d+$/)}.size
          nber_float = categories.keys.select{|k| k.match(/^-?\d*\.\d+$/)}.size
        if nber_int == categories.keys.size
          list_cats = categories.keys.map{|e| [e.to_i, e]}.sort{|a,b| a[0] <=> b[0]}.map{|e| e[1]}.to_json
        elsif  nber_float == categories.keys.size
            list_cats = categories.keys.map{|e| [e.to_f,e]}.sort{|a,b| a[0] <=> b[0]}.map{|e| e[1]}.to_json
        else
          list_cats = categories.keys.sort.to_json
        end
      end
      a.update_attributes({:list_cat_json => list_cats})
    }
  end
  
end
