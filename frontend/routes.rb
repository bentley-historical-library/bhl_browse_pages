ArchivesSpace::Application.routes.draw do

  match('/browse_pages/update' => 'browse_pages#update',
        :via => [:post])

end