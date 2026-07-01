Rails.application.routes.draw do
  get "up" => "rails/health#show", as: :rails_health_check

  namespace :v1 do
    namespace :user do
      post "check_status", to: "status#check"
    end
  end
end
