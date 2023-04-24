 include Rails.application.routes.url_helpers

 class UserMailer < ApplicationMailer
   default from: 'from@example.com'
   layout 'mailer'
   add_template_helper(ApplicationHelper)

   def invitation_mail(user, share)
     @user = user
     @share = share
     @project = @share.project
     mail(:from => "ASAP_Team<noreply@epfl.ch>",
          :to => share.email,
          :subject => "ASAP invitation")
   end
   
   def batch_invitation_mail(user, shares)
     @user = user
     @shares = shares
     @projects = Project.where(:id => @shares.map{|s| s.project_id}).all
     mail(:from => "ASAP_Team<noreply@epfl.ch>",
          :to => shares.first.email,
          :subject => "ASAP invitations")
   end


 end
