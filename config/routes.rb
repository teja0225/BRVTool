Rails.application.routes.draw do
  get 'users/new'

  root	'users#new'
  
  get 'users/backup'

  get 'users/restore'
  get 'users/validate'
  resources 'users'
  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html
end
