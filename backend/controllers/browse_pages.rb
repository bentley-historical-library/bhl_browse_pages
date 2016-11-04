class ArchivesSpaceService < Sinatra::Base

  Endpoint.post('/repositories/:repo_id/browse_pages/update')
    .description("Update Finding Aid browse pages data")
    .params(["repo_id", :repo_id])
    .permissions(["view_repository"])
    .returns([200, "OK"]) \
  do
    updates_count = BrowsePages.update_browse_pages

    json_response(:updates => "Updated #{updates_count} records")
  end

  Endpoint.get('/repositories/:repo_id/browse_pages/calculate')
  	.description("Calculate collections to be updated")
  	.params(["repo_id", :repo_id])
  	.permissions(["manage_repository"])
  	.returns([200, "OK"]) \
  do
  	update_info = BrowsePages.locate_new_collections

  	json_response(:results => update_info)
  end
end
