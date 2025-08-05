module RedmineSprintBoardPro
  module ProjectPatch
    def self.included(base)
      Rails.logger.info '[SprintBoardPro] ProjectPatch loaded' if defined?(Rails)
      base.class_eval do
        has_many :sprints, dependent: :destroy
      end
    end
  end
end