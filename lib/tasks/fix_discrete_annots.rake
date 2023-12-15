desc '####################### Fix discrete annots'
task fix_discrete_annots: :environment do
  puts 'Executing...'

  now = Time.now

  Project.all.each do |p|
    p.annots.select{|a| a.data_class_ids}.each do |a|
      t = a.data_class_ids.split(",").map{|e| e.to_i}
      if a.dim == 1 and a.data_type_id == 3 and !t.include? 6
        puts "Fix annot! #{a.id} #{a.name} #{a.data_class_ids}"
 	t.push(6)
	new_data_class_ids = t.sort.join(",")
	puts new_data_class_ids
	a.update_attributes(:data_class_ids => new_data_class_ids)
      end
    end
  end
  
end
