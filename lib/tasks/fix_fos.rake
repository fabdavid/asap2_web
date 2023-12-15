desc '####################### Fix fos'
task fix_fos: :environment do
  puts 'Executing...'

  now = Time.now
  
  Project.where(:key => '1iser0').order("id desc").all.each do |p|
  project_dir = Pathname.new(APP_CONFIG[:data_dir]) + "users" + p.user_id.to_s + p.key
    p.fos.each do |fo|
      filename = project_dir + fo.filepath
      if !File.exist? filename 
        if run = fo.run
          if fo.ext == 'loom'
            puts "File #{filename} doesnt exist!"
            RunsController.destroy_run_call(p, run)
          end
          #        run = Run.where(:id => fo.run_id).first
          #        if !run
          #          puts "Fo #{fo.id} to delete"
          #        else
          #          puts "#{run.id} exists"
          #        end
        else
          puts "Delete Fo #{filename}"
          fo.destroy
        end
      else
        puts "File found!"
      end
    end

    p.annots.each do |a|
      filename =  project_dir + a.filepath
      if !File.exist? filename
        if run = Run.where(:id => a.store_run_id).first
          RunsController.destroy_run_call(p, run)
        else
          a.destroy
        end
      end
    end
  end
  
end
