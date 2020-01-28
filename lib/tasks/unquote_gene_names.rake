desc '####################### Clean'
task unquote_gene_names: :environment do

  puts 'Executing...'

  dev_null = Logger.new("/dev/null")
  Rails.logger = dev_null
  ActiveRecord::Base.logger = dev_null
  
  start = Time.now

  def dt t, start
    d = (t - start).to_i
#    return "#{d/60}:#{d%60}"
     Time.at(d).strftime "%H:%M:%S"
  end

  def unquote txt
    txt.strip!	
    if txt[0] == "'" and txt[-1] == "'"
      txt = txt[1..-2]
    end
    return txt
  end

  ActiveRecord::Base.transaction do
    Gene.where("alt_names ~ ''''").all.each do |g|
      puts g.alt_names
       unquoted_alt_names = g.alt_names.split(",").map{|e| unquote(e)}.uniq.join(",")
       puts unquoted_alt_names + " UNQUOTED"
      g.update_attribute(:alt_names, unquoted_alt_names)
    end
  end

  ActiveRecord::Base.transaction do
    Gene.where("obsolete_alt_names ~ ''''").all.each do |g|
#      puts g.obsolete_alt_names
       unquoted_obsolete_alt_names = g.obsolete_alt_names.split(",").map{|e| unquote(e)}.join(",")
#       puts unquoted_obsolete_alt_names + " UNQUOTED"
      g.update_attribute(:obsolete_alt_names, unquoted_obsolete_alt_names)
    end
  end
  
end
