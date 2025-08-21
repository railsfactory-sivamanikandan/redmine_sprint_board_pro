module RedmineSprintBoardPro
  module Hooks
    class ViewHooks < Redmine::Hook::ViewListener
      def view_layouts_base_sidebar(context = {})
        if context[:controller].is_a?(AgileBoardController)
          context[:controller].send(:render_to_string, {
            partial: 'agile_board/sidebar',
            locals: context
          })
        end
      end
    end
  end
end
