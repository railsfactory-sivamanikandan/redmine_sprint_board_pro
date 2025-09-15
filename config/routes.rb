RedmineApp::Application.routes.draw do
  resources :projects do
    get 'agile_board', to: 'agile_board#index'
    post 'agile_board/update_issue', to: 'agile_board#update_issue'
    post 'agile_board/update_positions', to: 'agile_board#update_positions'
    post 'agile_board/save_card_preferences', to: 'agile_board#save_card_preferences'
    resources :sprints do
      member do
        patch :toggle_completed
        get :dashboard
        post :spillover_to_next
      end
    end
  end
  get 'tags/autocomplete', to: 'tags#autocomplete'
  post 'projects/:project_id/agile_board/update_sprint', to: 'agile_board#update_sprint', as: 'update_sprint_project_agile_board'
end