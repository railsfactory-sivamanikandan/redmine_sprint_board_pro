class Sprint < ApplicationRecord
  belongs_to :project
  has_many :issues
  validates :name, presence: true

  def completed?
    completed || (end_date && end_date < Date.today)
  end

  def self.smart_backlog_candidates(project, limit: 10)
    recent_sprint = project.sprints.order(end_date: :desc).first

    Issue
      .where(project: project)
      .where(status: IssueStatus.where(is_closed: false))
      .where('due_date <= ?', 1.week.from_now)
      .or(Issue.where(id: recent_sprint.issues.where(status: IssueStatus.where(is_closed: false)).pluck(:id)))
      .order(priority_id: :desc, updated_on: :desc)
      .limit(limit)
  end

  def completed_points
    issues.where(status: IssueStatus.where(is_closed: true)).sum(:story_points)
  end
end
