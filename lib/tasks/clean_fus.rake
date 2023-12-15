desc '####################### Clean File uploads'
task clean_fus: :environment do
  puts 'Executing...'
  
  now = Time.now

  fus_dir = Pathname.new(APP_CONFIG[:data_dir]) + 'fus'

  h_md5 = {}

  i = 0
  Dir.glob("**/*", base: fus_dir).sort.each do |f|
   # puts f
   filepath = fus_dir + f
    if !File.directory?(filepath) and !File.symlink?(filepath) and !f.match(/\.(json|log)$/)
      #  puts "#{filepath} is a file (not a directory and not a symlink)"	
      cmd = "md5sum \"#{filepath}\""    ##{Shellwords.escape(filepath)}"
      puts cmd
      md5 = `#{cmd}`.split(/\s+/)[0]
      puts "#{filepath} => #{md5}"
      if !h_md5[md5]
        h_md5[md5] = filepath
      else
        puts "delete file #{filepath}"
        File.delete(filepath)
        puts "create symlink"
        File.symlink(h_md5[md5], filepath)
      end
      i+=1
      
    end
#    exit if i == 1000
  end
  #    if File.directory?(f)
#  Dir.entries(fus_dir).map{|e| !e.directory? and !e.symlink?}.each do |f|
  #    puts "#{}This is a file!"
  #  end				   
end
