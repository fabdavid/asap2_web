class StdRun < ApplicationRecord

  belongs_to :std_method
  belongs_to :step
  belongs_to :project

  NewRun = Struct.new(:std_run) do
    def perform
      std_run.run
    end

    def error(job, exception)
      if job.last_error
        lines = job.last_error.split("\n")
        lines = lines.join("\\n")
        step = std_run.step #Step.where(:name => 'gene_filtering').first
        project_step = ProjectStep.where(:project_id => project.id, :step_id => step.id).first
        project_step.update_attributes(:error_message => lines, :status_id => 4)
        std_run.update_attributes(:status_id => 4)
      end
    end
  end


  def run
    require 'run'

    logger.debug("BLA!!!!!")
    start_time = Time.now
    self.update_attributes(:status_id => 2)
    project_step = ProjectStep.where(:project_id => self.id, :step_id => 2).first
    project_step.update_attributes(:status_id => 2)

    require "csv"
  end

end
