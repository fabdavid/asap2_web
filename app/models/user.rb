class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :trackable, :validatable

  before_save :strip
  before_destroy :delete_parents
  after_save :update_shares

  has_many :jobs
  has_many :projects
  has_and_belongs_to_many :ips
  belongs_to :orcid_user, :optional => true

  private

  #  def get_name 
  #    return (self.displayed_name != '') ? self.displayed_name : self.email.split('@').first
  #  end

  def strip
    self.email.strip!
    self.displayed_name.strip!  if self.displayed_name  
    self.displayed_name = self.email.split('@').first if self.displayed_name == ''
  end

  def delete_parents    
    self.jobs.delete_all
    self.projects.delete_all
  end

  def update_shares
    Share.where(:email => self.email).update_all(:user_id => self.id)
  end

#  before_logout :empty_session

#  def empty_session
#    reset_session
#  end
end
