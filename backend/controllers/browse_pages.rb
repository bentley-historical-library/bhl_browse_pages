class ArchivesSpaceService < Sinatra::Base

  Endpoint.post('/repositories/:repo_id/browse_pages')
    .description("Export Finding Aid browse pages data")
    .params(["repo_id", :repo_id])
    .permissions(["view_repository"])
    .returns([200, "OK"]) \
  do
    updates_count = BrowsePages.update_browse_pages

    json_response(:updates => "Updated #{updates_count} records")
  end
end
