module RedmineSprintBoardPro
  module Hooks
    class ViewIssuesFormTagsHook < Redmine::Hook::ViewListener
      def view_issues_form_details_bottom(context = {})
          context[:controller].send(:render_to_string, {
            partial: 'issues/issue_tags',
            locals: { f: context[:form], project: context[:project] }
          })
        end
    end
  end
end