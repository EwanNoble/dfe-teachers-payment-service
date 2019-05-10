Rails.application.routes.draw do
  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html
  root "claims#new"

  constraints slug: /qts-year|claim-school|full-name|address|address-combined|dob/ do
    resources :claims, only: [:new, :create, :show, :update], param: :slug
  end
end
