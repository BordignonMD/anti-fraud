Rails.application.routes.draw do
  resources :transactions, only: %i[index] do
    collection do
      post :import
      post :analyze
    end
  end

  root 'transactions#index'
end
