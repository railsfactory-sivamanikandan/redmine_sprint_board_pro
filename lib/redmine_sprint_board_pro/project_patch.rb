module RedmineSprintBoardPro
  module ProjectPatch
    def self.included(base)
      base.class_eval do
        has_many :sprints, dependent: :destroy
      end
    end
  end
end