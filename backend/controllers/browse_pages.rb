class ArchivesSpaceService < Sinatra::Base

	Endpoint.post('/repositories/:repo_id/browse_pages')
		.description("Export Finding Aid browse pages data")
		.params(["repo_id", :repo_id])
		.permissions(["view_repository"])
		.returns([200, "OK"]) \
	do
		colls = CrudHelpers.scoped_dataset(Resource, {:publish => true})
		rows = Array.new
		colls.each do |coll|
			json = Resource.to_jsonmodel(coll[:id])

			last_revision = BrowsePages.last_revision(json[:revision_statements])
			revision_count = json[:revision_statements].length
			new_or_updated = BrowsePages.new_or_updated(last_revision, revision_count)
			creator = BrowsePages.creator(json[:linked_agents])
			classification = BrowsePages.classification(json[:classifications])
			sort = BrowsePages.sort(creator, coll[:title])
			page = BrowsePages.page(sort)
			display = BrowsePages.display(creator, coll[:title])

			row = {
				:id => coll[:id],
				:ead_id => coll[:ead_id],
				:display => display,
				:sort => sort,
				:page => page,
				:classification => classification,
				:status => new_or_updated,
				:title => coll[:title],
				:revision_count => revision_count,
				:last_revision => last_revision,
				:creator => creator
			}

			rows.push(row)
		end

		browse_pages_db = BrowsePages.connect_to_browse_page_db
		BrowsePages.drop_browse_table(browse_pages_db)
		BrowsePages.create_browse_table(browse_pages_db)
		browse_pages_db[:browse_pages].multi_insert(rows)
		browse_pages_db.disconnect

		json_response(:updates => "Updated #{rows.length} rows")
	end
end
