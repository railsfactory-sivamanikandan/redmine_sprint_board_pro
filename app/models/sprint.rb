class Sprint < ApplicationRecord
  belongs_to :project
  has_many :issues
  validates :name, presence: true

  scope :completed, -> { where(completed: true) }
  scope :open, -> { where(completed: false) }

  def completed?
    completed
  end

  def self.smart_backlog_candidates(project, limit: 10)
    open_status_ids = IssueStatus.where(is_closed: false).pluck(:id)
    recent_sprint = project.sprints.order(end_date: :desc).first

    if recent_sprint.nil?
      return Issue.where(project_id: project.id)
                  .where(status_id: open_status_ids)
                  .where(sprint_id: nil)
                  .limit(limit)
    end

    unassigned_issues = Issue.where(project_id: project.id)
                              .where(status_id: open_status_ids)
                              .where(sprint_id: nil)

    recent_sprint_open_issues = recent_sprint.issues
                                            .where(status_id: open_status_ids)

    Issue.where(id: unassigned_issues.pluck(:id) + recent_sprint_open_issues.pluck(:id))
        .order(priority_id: :desc, updated_on: :desc)
        .limit(limit)
  end

  def completed_points
    issues.where(status: IssueStatus.where(is_closed: true)).sum(:story_points)
  end

  def total_points
    issues.sum(:story_points) || 0
  end

  def burndown_data
    return [] unless start_date.present? && end_date.present?
    # total story points at sprint start
    total_points = issues.sum(:story_points) || 0

    # Date range – inclusive
    days = (start_date.to_date..end_date.to_date).to_a

    # For performance: detect closed statuses once
    # (assumes Issue has association :status and issue_statuses table has is_closed boolean)
    days.map do |day|
      # closed story points up to and including `day`
      closed_points = issues
                      .joins(:status)
                      .where(issue_statuses: { is_closed: true })
                      .where("issues.updated_on <= ?", day.end_of_day)
                      .sum(:story_points) || 0

      remaining = total_points - closed_points
      remaining = 0 if remaining.negative?
      [day, remaining]
    end
  end

  def incomplete_issues
    issues.joins(:status).where(issue_statuses: { is_closed: false })
  end

  def next_sprint
    project.sprints.where('start_date > ?', end_date || Date.current)
                   .where(completed: false)
                   .order(:start_date)
                   .first
  end

  def spillover_to_next_sprint(issue_ids = nil)
    target_sprint = next_sprint
    return { success: false, message: 'No next sprint available' } unless target_sprint

    issues_to_move = if issue_ids.present?
                       incomplete_issues.where(id: issue_ids)
                     else
                       incomplete_issues
                     end

    return { success: false, message: 'No incomplete issues to move' } if issues_to_move.empty?

    moved_count = 0
    issues_to_move.find_each do |issue|
      if issue.update(sprint_id: target_sprint.id)
        moved_count += 1
      end
    end

    {
      success: true,
      message: "Successfully moved #{moved_count} incomplete #{moved_count == 1 ? 'issue' : 'issues'} to #{target_sprint.name}",
      moved_count: moved_count,
      target_sprint: target_sprint
    }
  end
end
