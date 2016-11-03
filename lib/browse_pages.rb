# encoding: utf-8

require 'date'
require 'sequel'

class BrowsePages

	def initialize
	end

	def self.update_browse_pages
		colls = CrudHelpers.scoped_dataset(Resource, {:publish => true})
		rows = Array.new
		colls.each do |coll|
			json = Resource.to_jsonmodel(coll[:id])

			last_revision = last_revision(json[:revision_statements])
			revision_count = json[:revision_statements].length
			new_or_updated = new_or_updated(last_revision, revision_count)
			creator = creator(json[:linked_agents])
			classification = classification(json[:classifications])
			sort = sort(creator, coll[:title])
			page = page(sort)
			display = display(creator, coll[:title])

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

		@browse_pages_db = Sequel.connect(AppConfig[:browse_page_db_url])
		drop_browse_table
		create_browse_table
		@browse_pages_db[:browse_pages].multi_insert(rows)
		@browse_pages_db.disconnect

		rows.length
	end

	def self.creator(agents)
		creator_name = nil
		creators = agents.map { |a| a if a["role"] == "creator"}.compact
		if creators.length > 0
			creator = creators[0]
			creator_ref = creator["ref"]
			if creator_ref.include?("people")
				creator_id = JSONModel::JSONModel(:agent_person).id_for(creator_ref)
				creator_json = AgentPerson.to_jsonmodel(creator_id)
			elsif creator_ref.include?("corporate")
				creator_id = JSONModel::JSONModel(:agent_corporate_entity).id_for(creator_ref)
				creator_json = AgentCorporateEntity.to_jsonmodel(creator_id)
			elsif creator_ref.include?("families")
				creator_id = JSONModel::JSONModel(:agent_family).id_for(creator_ref)
				creator_json = AgentFamily.to_jsonmodel(creator_id)
			end

			creator_name = creator_json["display_name"]["sort_name"].strip
		end

		creator_name
	end

	def self.display(creator, title)
		if creator && creator.downcase.include?("bentley historical library (collector)")
			display = "#{creator}, #{title}"
		elsif creator && creator.downcase.include?("michigan historical collections") and not title.downcase.include?("michigan historical collections")
			display = "#{creator} #{title}"
		else
			display = title
		end

		display.gsub("’", "'").gsub("&amp;","&").strip
	end

	def self.last_revision(revisions)
		last_revision = nil
		if revisions.length > 0
			dates = revisions.map { |r| r["date"]}
			last_revision = dates.max
		end
		
		last_revision
	end

	def self.new_or_updated(last_revision, revision_count)
		status = nil
		if revision_count > 0
			new_or_updated = false
			today = Date.today
			this_month = Date.new(today.year, today.month, 01)
			previous_month = this_month.prev_month

			revision_parts = last_revision.split("-")
			if revision_parts.length == 1
				revision_date = Date.strptime(last_revision, "%Y")
			elsif revision_parts.length == 2
				revision_date = Date.strptime(last_revision, "%Y-%m")
			else
				revision_date = Date.strptime(last_revision, "%Y-%m-%d")
			end

			if this_month.year == previous_month.year
				if this_month.year == revision_date.year
					if (this_month.month == revision_date.month) or (previous_month.month == revision_date.month)
						new_or_updated = true
					end
				end
			elsif (previous_month.year == revision_date.year) and (previous_month.month == revision_date.month)
				new_or_updated = true
			end

			if new_or_updated
				if revision_count == 1
					status = "new"
				else
					status = "updated"
				end
			end
		end

		status
	end

	def self.classification(classifications)
		if classifications.length
			classification_refs = classifications.map { |c| c["ref"]}
			classification_numbers = classification_refs.map { |c| c.split("/")[-1]}
			if classification_numbers.include?("2") and classifications.length == 1
				classification = "UofM"
			else
				classification = "A-Z"
			end
		else
			classification = "A-Z"
		end

		classification
	end

	def self.sort(creator, title)
		if title.start_with?("[")
			title = title.slice(1..-1)
		end
		if title.end_with?("]")
			title = title.slice(0..-2)
		end

		if creator.nil?
			sort = title
		elsif creator.downcase.start_with?("university of michigan")
			sort = title
		else
			sort = creator
		end

		sort.strip
	end

	def self.page(sort)
		page = sort[0].downcase
		page
	end

	def self.drop_browse_table
		@browse_pages_db.drop_table?(:browse_pages)
	end

	def self.create_browse_table
		@browse_pages_db.create_table :browse_pages do 
			primary_key :id
			String :ead_id
			String :display
			String :sort
			String :page
			String :classification
			String :status
			String :title
			String :revision_count
			String :last_revision
			String :creator
		end	
	end
end
