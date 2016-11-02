class BrowsePagesController < ApplicationController
  set_access_control "update_accession_record" => [:import, :preview, :index]

  def index
	render "browse_pages/index"
  end

end
