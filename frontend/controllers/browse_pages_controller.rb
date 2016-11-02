class BrowsePagesController < ApplicationController
  set_access_control "view_repository" => [:index, :update]

  def index
	render "browse_pages/index"
  end

  def update
  	response = JSONModel::HTTP::post_form("/repositories/#{session[:repo_id]}/browse_pages")

    if response.code == '200'
      render :json => ASUtils.json_parse(response.body)
    else
      render :status => 500
    end
  end	

end
