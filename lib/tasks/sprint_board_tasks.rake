namespace :sprint_board_pro do
  desc "Send monthly sprint report"
  task monthly_report: :environment do
    include SprintEmailHelper

    # Calculate last month's date range
    report_period_start = Date.today.prev_month.beginning_of_month
    report_period_end   = Date.today.prev_month.end_of_month

    Project.active.each do |project|
      manager = project.members.find { |m| m.roles.any? { |r| r.name == 'Manager' } }&.user
      next unless manager

      report_data = generate_report_for(project, report_period_start, report_period_end)
      send_monthly_report_email(project, report_data.merge(
        period_start: report_period_start,
        period_end: report_period_end
      ))
    end
  end

  def generate_report_for(project, period_start, period_end)
    sprints = project.sprints.where(start_date: period_start..period_end)

    closed_issues_count = Issue
      .joins(:sprint)
      .where(sprints: { id: sprints.ids })
      .where(status_id: IssueStatus.where(is_closed: true).select(:id))
      .count

    story_points_done = Issue
      .joins(:sprint)
      .where(sprints: { id: sprints.ids })
      .sum(:story_points)

    {
      sprints: sprints.count,
      completed_sprints: project.sprints.completed.where(end_date: period_start..period_end).count,
      open_sprints: project.sprints.open.where(start_date: period_start..period_end).count,
      issues_resolved: project.issues.closed.where(closed_on: period_start..period_end).count,
      closed_issues: closed_issues_count,
      story_points_done: story_points_done
    }
  end
end