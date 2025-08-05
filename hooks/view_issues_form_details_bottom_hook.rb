module RedmineSprintBoardPro
  module Hooks
    class ViewIssuesFormDetailsBottomHook < Redmine::Hook::ViewListener
      def view_issues_form_details_bottom(context = {})
        context[:controller].send(:render_to_string, {
          partial: 'issues/sprint_field',
          locals: { f: context[:form], project: context[:project] }
        })
      end
    end
  end
end