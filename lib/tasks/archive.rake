desc '####################### archive projects'
#task archive: :environment do
task :archive, [:project_key] => [:environment] do |t, args|
  puts 'Executing...'

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

  now = Time.now
  ## time after which the project is archived
  active_time = 7.day

  #  Project.where({:archive_status_id => 1}).all.each do |p|
 
  projects = []
  if args[:project_key]
    projects = Project.where(:key => args[:project_key]).all
  else
    projects = Project.where({:archive_status_id => 1}).all
  end

  projects.each do |p|
    base_dir =  Pathname.new(APP_CONFIG[:user_data_dir]) + p.user_id.to_s
    project_dir = base_dir + p.key
    #   ## delete tgz file if it exists
    #   File.delete "#{project_dir}.tgz" if File.exist? "#{project_dir}.tgz"
    
    if (Time.now - p.viewed_at > active_time and File.exist? project_dir) or args[:project_key]
      
      ## delete tgz file if it exists                                                                                                                         
      File.delete "#{project_dir}.tgz" if File.exist? "#{project_dir}.tgz"

      p.update_attributes(:archive_status_id => 2)
      #      project_dir =  Pathname.new(APP_CONFIG[:user_data_dir]) + p.user_id.to_s + p.key
      
      ## tar and pigz
      #      tar -cf -  -C /data/asap2/users/1 jgf9d1
      cmd = "tar -cf - -C #{base_dir} #{p.key} | pigz -9 -p 32 > #{project_dir}.tgz"
      puts cmd
      `#{cmd}`
      
      metadata = {:key => p.key}
      filepath = "#{project_dir}.tgz"
      
      in_s3 = false
      s3_obj = nil
      if File.exist?(filepath) and  File.size(filepath) > 0
        s3_obj = Basic.write_file_on_s3 s3b, filepath, metadata
        if s3_obj
          #  puts s3_obj.to_json
          #  exit
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
            if File.size(filepath) == s3_obj.content_length
              puts "Project #{p.key} can be deleted"
              File.delete(filepath)
              in_s3 = true
            else
              puts "Project not deleted"
            end
          else
            puts "FAILED!!!"
            puts "RES: " + res
            puts "RES2: " + t.to_json
          end
        end
        
        
      end

      if in_s3 == true
        p.update_attributes(:archive_status_id => 3, :disk_size_archived => s3_obj.content_length)
        #            if in_s3 == true #File.exist? "#{project_dir}.tgz" and File.size("#{project_dir}.tgz") > 0
        FileUtils.rm_r(project_dir) if File.exist? project_dir
      else
         p.update_attributes(:archive_status_id => 1)
      end	     
    end
  end
end
