class DirtyStatusChangeJob < ActiveJob::Base
  after_perform do |job|
    # invoke another job at your time of choice
    self.class.set(:wait => 3.seconds).perform_later(job.arguments.first)
  end

  def perform( project )
    project.status_id = rand(1..5)
    project.save!(validate: false)
  end
end