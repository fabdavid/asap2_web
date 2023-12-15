desc '####################### Fix cloned fo'
task fix_fos2: :environment do
  puts 'Executing...'

  now = Time.now

  warnings = []
  
  TmpFo.all.each do |tmp_fo|
    if !Fo.where(:id => tmp_fo.id).first
      fo = Fo.new(tmp_fo.attributes)
      fo.save
            puts fo.to_json
    end
  end
end
