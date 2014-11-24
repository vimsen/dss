Rails.application.routes.draw do

  get 'clustering/select'

  post 'clustering/confirm'

  post 'clustering/save'

  resources :connection_types

  resources :building_types

  resources :energy_prices

  resources :energy_types

  resources :day_ahead_hours

  resources :day_aheads

  resources :data_points

  resources :intervals

  get 'intellen_mock/getdata'
  get 'intellen_mock/getdayahead'

  devise_for :users
  resources :clusters
  resources :users
  resources :roles

  get 'stream/:id/addevent' => 'stream#addevent'

  get 'stream/:id/realtime' => 'stream#realtime'
  get 'stream/:id/prosumer' => 'stream#prosumer'
  get 'stream/:id/clusterfeed' => 'stream#clusterfeed'

  patch 'prosumers/:id/removefromcluster' => 'prosumers#removefromcluster'
  patch 'clusters/:id/addprosumer' => 'clusters#addprosumer'

  resources :measurements

  resources :prosumers

  #login page
  get 'login' => 'login#index'
  get 'login/index' => 'login#index'
  post 'login/signin' => 'login#signin'
  get 'login/signout' => 'login#signout'

  get 'home' => 'home#index'
  get 'home/energyType' => 'home#energyType'
  get 'home/energyPrice' => 'home#energyPrice'
  get 'home/totalProsumption' => 'home#totalProsumption'
  get 'home/top5Producers' => 'home#top5Producers'
  get 'home/top5Consumption' => 'home#top5Consumers'


  resources :machines
  

  root :to => 'home#index'
 # devise_scope :user do
 #   root :to => 'devise/sessions#new'
 # end

# The priority is based upon order of creation: first created -> highest priority.
# See how all your routes lay out with "rake routes".

# You can have the root of your site routed with "root"
# root 'welcome#index'

# Example of regular route:
#   get 'products/:id' => 'catalog#view'

# Example of named route that can be invoked with purchase_url(id: product.id)
#   get 'products/:id/purchase' => 'catalog#purchase', as: :purchase

# Example resource route (maps HTTP verbs to controller actions automatically):
#   resources :products

# Example resource route with options:
#   resources :products do
#     member do
#       get 'short'
#       post 'toggle'
#     end
#
#     collection do
#       get 'sold'
#     end
#   end

# Example resource route with sub-resources:
#   resources :products do
#     resources :comments, :sales
#     resource :seller
#   end

# Example resource route with more complex sub-resources:
#   resources :products do
#     resources :comments
#     resources :sales do
#       get 'recent', on: :collection
#     end
#   end

# Example resource route with concerns:
#   concern :toggleable do
#     post 'toggle'
#   end
#   resources :posts, concerns: :toggleable
#   resources :photos, concerns: :toggleable

# Example resource route within a namespace:
#   namespace :admin do
#     # Directs /admin/products/* to Admin::ProductsController
#     # (app/controllers/admin/products_controller.rb)
#     resources :products
#   end
end
