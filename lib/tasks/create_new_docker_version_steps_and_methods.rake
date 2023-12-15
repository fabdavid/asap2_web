desc '####################### Create new asap version'
task create_new_docker_version_steps_and_methods: :environment do
  puts 'Executing...'

  now = Time.now
  
#  new_version = Version.last
#  prev_version = new_version.id - 1

  docker_images = DockerImage.where(:name => APP_CONFIG[:asap_docker_name]).last(2)
  prev_docker_image = docker_images[0]
  new_docker_image = docker_images[1]
  
  puts "PREVIOUS_DOCKER: #{prev_docker_image.id}"
  puts "NEW_DOCKER: #{new_docker_image.id}"	
  
#  exit

  h_steps = {}  
  ## copy steps
  #  Step.where(:version_id => prev_version).order("id").all.each do |s|
  Step.where(:docker_image_id => prev_docker_image.id).order("id").all.each do |s| 
    #   new_s = Step.where(:version_id => new_version, :name => s.name).first
    new_s = Step.where(:docker_image_id => new_docker_image.id, :name => s.name).first
    h_s = s.attributes
    h_s.delete('id')
    h_s.delete('created_at')
    h_s.delete('updated_at')

    #   h_s[:version_id] = new_version.id
    h_s[:docker_image_id] = new_docker_image.id
    if !new_s
      new_s = Step.new(h_s)
      puts "Create step #{new_s.to_json}"
      new_s.save
      h_steps[s.id] = new_s.id
    end
  end
  
  ## copy std_methods  
  #  StdMethod.where(:version_id => prev_version).order("id").all.each do |s|
  StdMethod.where(:docker_image_id => prev_docker_image.id).order("id").all.each do |s| 
    #  new_s = StdMethod.where(:version_id => new_version, :step_id => s.step_id, :name => s.name).first
    new_s = StdMethod.where(:docker_image_id => new_docker_image.id, :step_id => s.step_id, :name => s.name).first  
    h_s = s.attributes
    h_s.delete('id')
    h_s.delete('created_at')
    h_s.delete('updated_at')
    #    h_s[:version_id] = new_version.id
    h_s[:docker_image_id] = new_docker_image.id
    h_s[:step_id] = h_steps[s.step_id]
    if !new_s
      new_s = StdMethod.new(h_s)
      puts "Create std_method #{new_s.to_json}"
      new_s.save
    end
  end

  

end
