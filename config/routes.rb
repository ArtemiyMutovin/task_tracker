Rails.application.routes.draw do
  mount Rswag::Ui::Engine => '/api-docs'
  mount Rswag::Api::Engine => '/api-docs'

  get "up" => "rails/health#show", as: :rails_health_check

  namespace :api do
    namespace :v1 do
      resources :tasks, only: %i[index show create update destroy] do
        resources :task_tags, only: %i[create destroy], path: 'tags'
        resources :task_occurrences, only: [:update], path: 'occurrences', param: :date
      end

      resources :occurrences, only: [:index], controller: 'task_occurrences'
      resources :tags, only: %i[index show create destroy]
    end
  end
end
