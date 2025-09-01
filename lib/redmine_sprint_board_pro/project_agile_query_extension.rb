module RedmineSprintBoardPro
  module ProjectAgileQueryExtension
    def self.included(base)
      base.class_eval do
        has_many :agile_queries, -> { where(type: 'AgileQuery') },
                class_name: 'AgileQuery',
                dependent: :delete_all
      end
    end
  end
end

Project.include(RedmineSprintBoardPro::ProjectAgileQueryExtension) unless Project.included_modules.include?(RedmineSprintBoardPro::ProjectAgileQueryExtension)