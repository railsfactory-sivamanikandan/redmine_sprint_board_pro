module RedmineSprintBoardPro
  module ProjectPatch
    def self.included(base)
      Rails.logger.info '[SprintBoardPro] ProjectPatch being applied to Project model' if defined?(Rails)
      base.class_eval do
        # Add association to sprints
        has_many :sprints, dependent: :destroy, class_name: 'Sprint'
        # Add any additional project-related methods here
        def active_sprints
          sprints.where(status: 'active')
        end
        def completed_sprints
          sprints.where(status: 'completed')
        end

        def manager
          manager_role = Role.find_by(name: 'Manager')
          return nil unless manager_role
          member = members.joins(:roles).find_by(roles: { id: manager_role.id })
          member&.user
        end
      end
      Rails.logger.info '[SprintBoardPro] ProjectPatch successfully applied' if defined?(Rails)
    end
  end
end