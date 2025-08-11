module RedmineSprintBoardPro
  module IssuePatch
    def self.included(base)
      base.class_eval do
        belongs_to :sprint, optional: true
        safe_attributes 'sprint_id', 'story_points', 'board_position'
        scope :closed, -> { joins(:status).where(issue_statuses: { is_closed: true }) }
      end
    end
  end
end