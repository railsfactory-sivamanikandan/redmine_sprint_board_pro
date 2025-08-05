Rails.application.config.assets.paths << File.expand_path('../assets/stylesheets', __FILE__)
Rails.application.config.assets.paths << File.expand_path('../assets/javascripts', __FILE__)
Redmine::Plugin.register :redmine_sprint_board_pro do
  name 'Redmine Sprint Board Pro plugin'
  author 'sivamanikandan'
  description 'Redmine Sprint Board Pro plugin is a powerful plugin for Redmine that brings Agile project management features like Sprint Planning, Trello-style Agile Boards, Burndown Charts, Smart Backlog Suggestions, and more.'
  version '0.0.1'
  url 'https://github.com/railsfactory-sivamanikandan/redmine_sprint_board_pro.git'
  author_url 'https://github.com/railsfactory-sivamanikandan/redmine_sprint_board_pro.git'

  requires_redmine version_or_higher: '5.0.0'

  project_module :agile_board do
    permission :view_agile_board, { agile_board: [:index] }, public: true
    permission :edit_agile_board, { agile_board: [:update_status] }
    permission :manage_sprints, { sprints: [:new, :create, :index, :edit, :update, :destroy, :show] }
  end

  menu :project_menu, :agile_board, { controller: 'agile_board', action: 'index' }, caption: 'Agile Board', after: :activity, param: :project_id
  menu :project_menu, :sprints, { controller: 'sprints', action: 'index' }, caption: 'Manage Sprints', after: :agile_board, param: :project_id
end
require_dependency 'project'
require_relative 'lib/project_patch'
Project.send(:include, RedmineSprintBoardPro::ProjectPatch)
require_relative 'hooks/view_issues_form_details_bottom_hook'
require_relative 'hooks/view_issues_show_hook'
require_relative 'lib/issue_patch'
Issue.send(:include, RedmineSprintBoardPro::IssuePatch)
