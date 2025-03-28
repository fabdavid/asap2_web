desc '####################### Update organism tags'
task update_organism_tag: :environment do

  puts 'Executing...'

  dev_null = Logger.new("/dev/null")
  Rails.logger = dev_null
  ActiveRecord::Base.logger = dev_null
  
  start = Time.now

  ## Download file
  kegg_file = "/data/asap2/kegg_species/kegg_species.txt"
  `wget -O #{kegg_file} 'http://rest.kegg.jp/list/organism'`

  ActiveRecord::Base.transaction do

    File.open(kegg_file, "r") do |f|
      while (l = f.gets) do 
        t = l.split("\t")
        #t2 = t[1].split(";")
        #        t3 = t2[0].split(",")
        #	if t3.size > 2
        
        #puts t3[0] + " = " + t3[2] 
        #	  if o = Organism.where(:tax_id => t3[2]).first
        if m = t[2].match(/(.+?) \(.+?\)$/)
          o = Organism.where(:name => m[1]).first
          o = Organism.where(:short_name => m[2]).first if !o
          if o and o.name and t[1]
            o.update_attribute(:tag, t[1]) if !o.tag
            puts o.name + "->" + t[1]
          else
            puts "#{l} Not found"
          end
        end
      end
    end
  #end
  
  end

end
