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
			@job.write_output("Updating finding aid browse pages")
			updates_count = BrowsePages.update_browse_pages

			@job.write_output("Updated #{updates_count} records")
		end
	rescue Exception => e
          terminal_error = e
          @job.write_output(terminal_error.message)
          @job.write_output(terminal_error.backtrace)
          raise Sequel::Rollback
    end
  end

end
