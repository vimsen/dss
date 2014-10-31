Rails.application.routes.draw do

  devise_for :users
  resources :clusters
  resources :users
  resources :roles

  get 'stream/:id/addevent' => 'stream#addevent'

  get 'stream/:id/realtime' => 'stream#realtime'
  get 'stream/:id/clusterfeed' => 'stream#clusterfeed'

  patch 'prosumers/:id/removefromcluster' => 'prosumers#removefromcluster'
  patch 'clusters/:id/addprosumer' => 'clusters#addprosumer'
  
  patch 'roles/:id/adduser' => 'roles#adduser'
  patch 'roles/:id/removeuser' => 'roles#removeuser'
  
  patch 'users/:id/addrole' => 'users#addrole'
  patch 'users/:id/removerole' => 'users#removerole'

  resources :measurements

  resources :prosumers

  #login page
  get 'login' => 'login#index'
  get 'login/index' => 'login#index'
  post 'login/signin' => 'login#signin'
  get 'login/signout' => 'login#signout'

  resources :home
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
