ArchivesSpace::Application.routes.draw do

	[AppConfig[:frontend_proxy_prefix], AppConfig[:frontend_prefix]].uniq.each do |prefix|

		scope prefix do
		    match('/plugins/browse_pages' => 'browse_pages#index', :via => [:get])
		    match('/plugins/browse_pages/update' => 'browse_pages#update', :via => [:post])
		end
	end
end