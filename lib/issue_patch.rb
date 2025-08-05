module RedmineSprintBoardPro
  module IssuePatch
    def self.included(base)
      base.class_eval do
        belongs_to :sprint, optional: true
        safe_attributes 'sprint_id', 'story_points', 'board_position'
      end
    end
  end
end