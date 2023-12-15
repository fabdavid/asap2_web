desc '####################### Add shares'
task add_shares_with_many_people: :environment do
  puts 'Executing...'

  now = Time.now

#  emails_txt = "mgrace8@jhmi.edu"

  h_perm = {:export_perm => true, :analyze_perm => true}
  admin_user = User.where(:email => 'bbcf.epfl@gmail.com').first

  tmp_projects = Project.where(["name ~ 'FlyCellAtlas'"]).all.select{|p| p.shares.size > 20}
  emails_txt = tmp_projects.first.shares.map{|s| s.email}.join(",")

#  project_tag = ProjectTag.where("name = 'FCAv2'").first	   
#  projects = project_tag.projects
   projects = Project.where(:key => 'x96waq').all
  
  puts "found #{projects.size} projects..."
  puts "add #{emails_txt}"

  emails = emails_txt.downcase.split(/[,;\s]+/)

  emails.each do |email|
    user = User.where(:email => email).first
    tmp_shares = []
    projects.each do |project|
      h_share = {
        :project_id => project.id,
        :email => email,
        #        :user_id => (user) ? user.id : nil,
        :export_perm => h_perm[:export_perm],
        :analyze_perm => h_perm[:analyze_perm]
      }
      share =Share.where(h_share).first
      if !share
        puts "Create share #{h_share.to_json}"
        h_share = {
          :project_id => project.id,
          :email => email,
          :user_id => (user) ? user.id : nil,                          
          :export_perm => h_perm[:export_perm],
          :analyze_perm => h_perm[:analyze_perm]
        }

       share = Share.new(h_share)
        if share.save
          tmp_shares.push share
          #           UserMailer.invitation_mail(admin_user, share).deliver
        end
      end
    end
    if tmp_shares.size > 0
      UserMailer.batch_invitation_mail(admin_user, tmp_shares).deliver
    end

  end
end
