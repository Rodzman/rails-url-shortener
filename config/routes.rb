Rails.application.routes.draw do
  get "up" => "rails/health#show", as: :rails_health_check

  namespace :api do
    namespace :v1 do
      resources :links, only: [ :create, :show ], param: :slug do
        get :stats, on: :member
      end
    end
  end

  get "/:slug", to: "redirects#show", as: :short, constraints: { slug: Link::SLUG_PATTERN }
end
