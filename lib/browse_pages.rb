# encoding: utf-8

require 'date'
require 'sequel'
require 'time'

class BrowsePages

  def initialize
  end

  def self.locate_new_collections
    update_job_enum = EnumerationValue.filter(:value => "update_browse_pages_job").get(:id)
    update_jobs = Job.filter(:job_type_id => update_job_enum, :status => "completed")
    if update_jobs.count > 0
      last_update = update_jobs.map(:create_time).max
    else
      last_update = Time.at(0)
    end

    browse_pages_db = Sequel.connect(AppConfig[:browse_page_db_url])
    create_browse_table(browse_pages_db)
    browse_pages_table = browse_pages_db[:browse_pages]
    browse_page_ids_and_titles = browse_pages_table.to_hash(:id, :title)
    browse_page_new_page_colls = browse_pages_table.filter(:status => "new").or(:status => "updated").to_hash(:id, :title)
    browse_pages_db.disconnect

    aspace_colls = CrudHelpers.scoped_dataset(Resource, {:publish => true})
    aspace_colls_ids_and_titles = aspace_colls.to_hash(:id, :title)

    new_colls = aspace_colls_ids_and_titles.reject {|k, v| browse_page_ids_and_titles.include?(k)}
    deleted_colls = browse_page_ids_and_titles.reject {|k, v| aspace_colls_ids_and_titles.include?(k)}    
    updated_colls = aspace_colls.where{user_mtime > last_update}.to_hash(:id, :title).reject { |k, v| new_colls.include?(k)}
    updates = browse_page_new_page_colls.merge(updated_colls)


    {
      "new_colls" => new_colls, 
      "updated_colls" => updates, 
      "deleted_colls" => deleted_colls, 
      "last_update" => last_update,
      "last_update_formatted" => last_update.strftime("%B %d, %Y")
    }

  end

  def self.create_new_entries(colls_to_add)
    rows = make_rows(colls_to_add)
    browse_pages_db = Sequel.connect(AppConfig[:browse_page_db_url])
    browse_pages_db[:browse_pages].multi_insert(rows)
    browse_pages_db.disconnect
  end

  def self.update_existing_entries(colls_to_update)
    rows = make_rows(colls_to_update)
    browse_pages_db = Sequel.connect(AppConfig[:browse_page_db_url])
    browse_pages_db[:browse_pages].filter(:id => colls_to_update).delete
    browse_pages_db[:browse_pages].multi_insert(rows)
    browse_pages_db.disconnect
  end

  def self.remove_entries(colls_to_delete)
    browse_pages_db = Sequel.connect(AppConfig[:browse_page_db_url])
    browse_pages_db[:browse_pages].filter(:id => colls_to_delete).delete
    browse_pages_db.disconnect

  end

  def self.make_rows(coll_ids)
    rows = Array.new
    coll_ids.each do |coll_id|
      json = Resource.to_jsonmodel(coll_id)
      last_revision = last_revision(json[:revision_statements])
      revision_count = json[:revision_statements].length
      new_or_updated = new_or_updated(last_revision, revision_count)
      creator = creator(json[:linked_agents])
      classification = classification(json[:user_defined])
      sort = sort(creator, json[:title])
      page = page(sort)
      display = display(creator, json[:title])

      row = {
        :id => coll_id,
        :ead_id => json[:ead_id],
        :display => display,
        :sort => sort,
        :page => page,
        :classification => classification,
        :status => new_or_updated,
        :title => json[:title],
        :revision_count => revision_count,
        :last_revision => last_revision,
        :creator => creator
      }

      rows.push(row)
    end

    rows
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

    display.gsub("’", "'").gsub("&amp;","&").gsub(/<.*?>/,"").strip
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

  def self.classification(user_defined)
    classifications = Array.new

    unless user_defined.nil?
      [1, 2, 3].each do |i|
        if user_defined.has_key?("enum_#{i}")
          classifications << user_defined["enum_#{i}"]
        end
      end
    end

    if classifications.length > 0
      if classifications.include?("UA") and classifications.length == 1
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

  def self.create_browse_table(browse_pages_db)
    browse_pages_db.create_table?(:browse_pages) do 
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
