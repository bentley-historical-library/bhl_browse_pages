class BrowsePagesJobRunner < JobRunner
 
  def self.instance_for(job)
	if job.job_type == "update_browse_pages_job"
		self.new(job)
	else
		nil
	end
  end

  def run
    super
    begin

	RequestContext.open(:repo_id => @job.repo_id) do
		@job.write_output("Testing testing")
	end
    end
  end

end
