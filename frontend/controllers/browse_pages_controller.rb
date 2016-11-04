class BrowsePagesController < ApplicationController
  set_access_control "manage_repository" => [ :index, :update]

  def index
  @job = JSONModel(:job).new._always_valid!
  @new_collections = JSONModel::HTTP::get_json("/repositories/#{session[:repo_id]}/browse_pages/calculate")
  end

  def update
    job_data ||= {}
    job_data['repo_id'] ||= session[:repo_id]
    #job_data['updates'] = @new_collections
    job = Job.new("update_browse_pages_job", JSONModel(:update_browse_pages_job).from_hash(job_data), [])
    response = job.upload
    resolver = Resolver.new(response[:uri])
    redirect_to resolver.view_uri
  end 

end
