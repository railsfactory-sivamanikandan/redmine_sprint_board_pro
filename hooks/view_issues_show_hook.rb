module RedmineSprintBoardPro
  class ViewIssuesShowHook < Redmine::Hook::ViewListener
    render_on :view_issues_show_details_bottom, partial: 'issues/issue_extra_fields'
  end
end