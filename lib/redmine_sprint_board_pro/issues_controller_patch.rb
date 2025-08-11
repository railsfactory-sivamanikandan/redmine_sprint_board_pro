module RedmineSprintBoardPro
  module IssuesControllerPatch
    def self.included(base)
      base.class_eval do
        before_action :save_tags, only: [:create, :update]

        private
        def save_tags
          if params[:issue] && params[:issue][:tag_list]
            @issue.tag_list = params[:issue][:tag_list]
          end
        end
      end
    end
  end
end