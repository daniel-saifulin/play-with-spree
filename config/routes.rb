Rails.application.routes.draw do
  require 'sidekiq/web'
  Sidekiq::Web.app_url = '/'

  Rails.application.routes.draw do
    mount Sidekiq::Web => '/sidekiq'
  end
  # This line mounts Spree's routes at the root of your application.
  # This means, any requests to URLs such as /products, will go to
  # Spree::ProductsController.
  # If you would like to change where this engine is mounted, simply change the
  # :at option to something different.
  #
  # We ask that you don't use the :as option here, as Spree relies on it being
  # the default of "spree".
  mount Spree::Core::Engine, at: '/'

  Spree::Core::Engine.add_routes do
    namespace :admin, path: Spree.admin_path do
      namespace :products do
        namespace :csv do
          resources :imports, only: [:show, :new, :create]
        end
      end
    end
  end
end
