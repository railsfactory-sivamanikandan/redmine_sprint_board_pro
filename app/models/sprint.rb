class Sprint < ApplicationRecord
  belongs_to :project
  has_many :issues
  validates :name, presence: true

  def completed?
    completed || (end_date && end_date < Date.today)
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
end
