class UpdateBrowsePagesJobRunner < JobRunner

  register_for_job_type('update_browse_pages_job')

  def run
    begin
      RequestContext.open(:repo_id => @job.repo_id) do
        @job.write_output("Updating finding aid browse pages")
        updates = BrowsePages.locate_new_collections
        colls_to_add = updates["new_colls"]
        colls_to_update = updates["updated_colls"]
        colls_to_delete = updates["deleted_colls"]

        if !colls_to_add.empty?
          BrowsePages.create_new_entries(colls_to_add.keys)
        end

        @job.write_output("Created #{colls_to_add.length} new entries")

        if !colls_to_update.empty?
          BrowsePages.update_existing_entries(colls_to_update.keys)
        end

        @job.write_output("Updated #{colls_to_update.length} entries")

        if !colls_to_delete.empty?
          BrowsePages.remove_entries(colls_to_delete.keys)
        end

        @job.write_output("Deleted #{colls_to_delete.length} entries")

        @job.write_output("Browse pages updated")
      end
    rescue Exception => e
      terminal_error = e
      @job.write_output(terminal_error.message)
      @job.write_output(terminal_error.backtrace)
      raise Sequel::Rollback
    end
  end

end