RedmineApp::Application.routes.draw do
  resources :projects do
    get 'agile_board', to: 'agile_board#index'
    post 'agile_board/update_status', to: 'agile_board#update_status'
    resources :sprints do
      member do
        patch :toggle_completed
        get :burndown
        get :velocity
      end
    end
  end
  post 'projects/:project_id/agile_board/update_sprint', to: 'agile_board#update_sprint', as: 'update_sprint_project_agile_board'
end