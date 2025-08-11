module RedmineSprintBoardPro
  module Hooks
    class ViewLayoutHooks < Redmine::Hook::ViewListener
      def view_layouts_base_html_head(_context = {})
        stylesheet_link_tag('select2.min', plugin: 'redmine_sprint_board_pro') +
        stylesheet_link_tag('tags', plugin: 'redmine_sprint_board_pro') +
        javascript_include_tag('select2.min', plugin: 'redmine_sprint_board_pro') +
        javascript_include_tag('tags', plugin: 'redmine_sprint_board_pro')
      end
    end
  end
end