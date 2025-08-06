class AgileBoardController < ApplicationController
  before_action :find_project
  before_action :find_issue, only: [:update_issue, :update_sprint]

  def index
    @sprints = Sprint.where(project_id: @project.id).order(start_date: :desc)
    @selected_sprint = Sprint.find_by(id: params[:sprint_id]) || @sprints.first
    @statuses = IssueStatus.sorted
    @issues = @project.issues.where(sprint_id: @selected_sprint&.id).order(:board_position).includes(:assigned_to, :status).group_by(&:status)
    @allowed_transitions = {}

    @issues.values.flatten.each do |issue|
      @allowed_transitions[issue.id] = issue.new_statuses_allowed_to(User.current).map(&:id)
    end
  end

  def update_issue
    @issue.init_journal(User.current)

    @issue.status_id = params[:status_id] if params[:status_id].present? && @issue.status_id.to_s != params[:status_id].to_s
    @issue.board_position = params[:board_position] if params[:board_position].present?

    if @issue.changed?
      @issue.lock_version = params[:lock_version] if params[:lock_version]
      if @issue.save
        render json: { success: true, lock_version: @issue.lock_version }
      else
        render json: { error: @issue.errors.full_messages.join(", ") }, status: :unprocessable_entity
      end
    else
      render json: { success: true, lock_version: @issue.lock_version }
    end
  end

  def update_sprint
    @issue.init_journal(User.current)
    @issue.sprint_id = params[:sprint_id]
    @issue.save
    head :ok
  end

  private

  def find_project
    @project = Project.find(params[:project_id])
  end

  def find_issue
    @issue = @project.issues.find(params[:id])
  end
end