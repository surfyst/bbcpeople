People::Application.routes.draw do
  root :to => 'meta#root'

  get 'articles/:id/related'      => 'articles#related'
  scope '/profiles' do
    get '/'     => 'profiles#index'
    constraints :name => /[%A-Za-z0-9()\._\-,]+/ do
      get '/:name' => 'profiles#show', :as => 'show_profile', :format => false
      get '/:name/read' => 'profiles#read', :as => 'read_profile'
      get '/:name/listen/schedules' => 'profiles#radio_schedules', :as => 'radio_schedules'
      get '/:name/listen/player' => 'profiles#listen', :as => 'listen_profile'
      get '/:name/listen' => 'profiles#listen_all'
      get '/:name/watch/schedules' => 'profiles#tv_schedules', :as => 'tv_schedules'
      get '/:name/watch/player' => 'profiles#watch', :as => 'watch_profile'
      get '/:name/watch' => 'profiles#watch_all'
      get '/:name/edit'     => 'profiles#edit', :as => 'edit_profile'
      put '/:name/update'   => 'profiles#update'
      post '/:name/follow' => 'profiles#follow'
      post '/:name/unfollow' => 'profiles#unfollow'
    end
  end

  get '/meta'              => 'meta#index'
  get '/meta/chrome'       => 'meta#chrome', :as => 'chrome'
  get '/meta/chrome-extension' => 'meta#chrome_extension', :as => 'chrome_extension'
  get '/meta/:action' => 'meta#:action'

  resources :users do
  end

  match "/auth/:provider/callback" => "sessions#create"
end
