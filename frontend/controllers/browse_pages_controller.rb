class BrowsePagesController < ApplicationController
  set_access_control "view_repository" => [:index, :update]

  def index
	@job = JSONModel(:job).new._always_valid!
	#render "browse_pages/index"
  end

  def update
    job_data ||= {}
    job_data['repo_id'] ||= session[:repo_id]
    job = Job.new("update_browse_pages_job", JSONModel(:update_browse_pages_job).from_hash(job_data), [])
    #JSONModel::HTTP::post_form("/repositories/#{session[:repo_id]}/browse_pages")
    response = job.upload
    resolver = Resolver.new(response[:uri])
    redirect_to resolver.view_uri
    #render :json => {'job_uri' => url_for(:controller => :jobs, :action => :show, :id => response['id'])}
    #redirect_to :controller => :welcome, :action => :index
    #flash[:success] = "Update job submitted"
  end	

end
