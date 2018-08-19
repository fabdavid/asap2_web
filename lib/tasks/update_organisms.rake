desc '####################### Update organisms'
task update_organisms: :environment do
  puts 'Executing...'

  now = Time.now

list_organisms = File.read("/data/asap/Genesets/go_species.txt").split("\n").map{|l| l.split("\t")}
header = list_organisms.shift
  puts list_organisms.to_json

  list_organisms.each do |organism_e|
    organism_name = organism_e[0]
    organism = Organism.where(["lower(name) = ?", organism_name.gsub("_", " ").downcase]).first
    if organism
      puts "Organism #{organism_name} found!"
      if !organism.go_short_name
        organism.update_attributes({:go_short_name => organism_e[1]})
      end
    else
      puts "Organism not found"
      t = organism_name.split("_")
      tag =  t[0].first + t[1][0 .. 1]
      i=1
      while (Organism.where(:tag => tag).first) do
        i+=1
        tag = t[0].first + t[1][0 .. 1] + i.to_s
      end
      h = {
        :name => organism_name.gsub("_", " ").capitalize,
        :tag => tag,
        :go_short_name => organism_e[1],
        :short_name => organism_e[1],
        :tax_id => organism_e[2]
      }
      puts h.to_json
      organism = Organism.new(h)
      organism.save
    end
  end

#puts list_organisms.map{|e| e.gsub("_", " ").capitalize}.join("','")
  
end
