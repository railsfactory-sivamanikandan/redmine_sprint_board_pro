class AgileBoardController < ApplicationController
  before_action :find_project

  def index
    @sprints = Sprint.where(project_id: @project.id).order(start_date: :desc)
    @selected_sprint = Sprint.find_by(id: params[:sprint_id]) || @sprints.first
    @statuses = IssueStatus.sorted
    @issues = @project.issues.where(sprint_id: @selected_sprint&.id).includes(:assigned_to, :status).group_by(&:status)
  end

  def update_status
    issue = Issue.find(params[:id])
    issue.init_journal(User.current)
    issue.status_id = params[:status_id] if params[:status_id].present?
    issue.save!
    head :ok
  end

  def update_sprint
    @issue = Issue.find(params[:id])
    @issue.init_journal(User.current)
    @issue.sprint_id = params[:sprint_id]
    @issue.save
    head :ok
  end

  private

  def find_project
    @project = Project.find(params[:project_id])
  end
end