desc '####################### Init archives'
task init_archives: :environment do
  puts 'Executing...'

  now = Time.now

  require 'aws-sdk'


  h_archive_status = {}
  ArchiveStatus.all.map{|e| h_archive_status[e.name] = e}
  
  puts h_archive_status.to_json

  s3_settings_file = Pathname.new(Rails.root) + 'config' + '.s3.json'
  h_s3_settings = JSON.parse(File.read(s3_settings_file))

   s3b = {
    :key => '20000-af8a16d143d9920a26869b30700c3da4',
    :endpoint => 'https://s3.epfl.ch',
    :region => 'us-west-2'
  }
  

  h_res = {}
  
  
  Aws.config.update({
                      :endpoint => s3b[:endpoint],
                      :region => s3b[:region],
                      :access_key_id => h_s3_settings[s3b[:key]]["rw"][0],
                      :secret_access_key => h_s3_settings[s3b[:key]]["rw"][1]
                    })
  
  # list buckets in Amazon S3
  s3 = Aws::S3::Client.new
  
  response = s3.list_objects({
                               bucket: s3b[:key],
                               max_keys: 1000
                             })
  
#  puts response
  puts response.to_h[:contents].to_json
  
  h_projects_in_s3 = {}
  response.to_h[:contents].map{|e| h_projects_in_s3[e[:key]] = e[:size] }

  page = 1
  while response.next_page? do
    response = response.next_page
    page+=1
    # Use the response data here...
    response.to_h[:contents].each do |e|                                                               \
      response.to_h[:contents].map{|e| h_projects_in_s3[e[:key]] = e[:size] }
    end
  end
  
  puts h_projects_in_s3.keys.to_json
  puts "Number projects in asap: " + Project.where(:archive_status_id => h_archive_status['archived'].id).count.to_s
  puts "Number projects on s3: " + h_projects_in_s3.keys.size.to_s
  

  
  Project.where(:archive_status_id => h_archive_status['archived'].id, :user_id => 1).all.each do |p|
#  Project.where( :key => '2m192r').all.each do |p|

    user_dir = Pathname.new(APP_CONFIG[:user_data_dir]) + p.user_id.to_s
 
    puts p.key

    metadata = {:key => p.key}
    filepath = user_dir + "#{p.key}.tgz"
    if File.exist? filepath
      
      cmd = "gzip -v -t #{filepath.to_s} 2>&1"
      #puts cmd 
      res = `#{cmd}`

      cmd2 = "gunzip -c #{filepath.to_s} | tar -t 2>&1"
      res2 = `#{cmd2}`

      #gunzip: unexpected end of file
      #tar: short read
      #puts res.to_json
      t = res2.split(/\n/) & ["tar: short read", "gunzip: unexpected end of file"]
      if res == '' and t.size == 0
        #        puts "SUCCESS: " + m
        ## delete
        if File.size(filepath) == h_projects_in_s3[p.key]
          puts "Project #{p.key} can be deleted"
	  File.delete(filepath)
        else
          puts "Project not deleted"
        end
      else
        puts "FAILED!!!" 
        puts "RES: " + res
        puts "RES2: " + t.to_json
      end
      
    
      #begin	   
      #  Basic.write_file_on_s3 s3b, filepath, metadata
      #rescue Exception => e
      #  puts "ERROR: " + e.message + "!!!!!!!!!!!!!!!!!!!!!!!!!!!"
      #end
    end
  end

end
