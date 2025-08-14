require 'acts-as-taggable-on'
module RedmineSprintBoardPro
  module IssuePatch
    def self.included(base)
      base.class_eval do
        acts_as_taggable_on :tags
        belongs_to :sprint, optional: true
        safe_attributes 'sprint_id', 'story_points', 'board_position', 'tag_list'
        scope :closed, -> { joins(:status).where(issue_statuses: { is_closed: true }) }

        validate :difficulty_required_if_story_points_present

        private

        def difficulty_required_if_story_points_present
          if story_points.present? && difficulty.blank?
            errors.add(:difficulty, "must be selected when story points are set")
          end
        end
      end
    end
  end
end