ActionController::Routing::Routes.draw do |map|
	map.devise_for :users
	map.root :controller => "people"
	map.clinic  '/clinic', :controller => 'clinic', :action => 'index'
	map.create_remote  '/patient/create_remote',  :controller => 'people', :action => 'create_remote'
	map.admin  '/admin', :controller => 'admin', :action => 'index'
	map.login  '/login', :controller => 'sessions', :action => 'new'
	map.logout '/logout', :controller => 'sessions', :action => 'destroy'
	map.location '/location', :controller => 'sessions', :action => 'location'
	map.encounter '/encounters/new/:encounter_type', :controller => 'encounters', :action => 'new'  
	map.encounter '/encounters/new/:encounter_type/:id', :controller => 'encounters', :action => 'new'  
	map.resource :session
	map.resources :dispensations, :collection => {:quantities => :get}
	map.resources :barcodes, :collection => {:label => :get}
	map.resources :relationships, :collection => {:search => :get}
	map.resources :programs, :collection => {:exitcarestates => :get,:exitcare => :get, :locations => :get, :workflows => :get, :states => :get}
	map.resources :encounter_types
	map.resources :single_sign_on, :collection => {:get_token => [:get, :post], :load_page => [:get, :post], :single_sign_in => [:get, :post]}
	map.connect ':controller/:action/:id.:format'
	map.connect ':controller/:action/:id'
	map.connect ':controller/:action/'
end
