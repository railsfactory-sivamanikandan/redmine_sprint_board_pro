class AgileBoardController < ApplicationController
  before_action :find_project
  before_action :find_issue, only: [:update_issue, :update_sprint]
  before_action :build_query, only: [:index]

  def index
    @sprints = Sprint.where(project_id: @project.id).order(start_date: :desc)
    if @query.has_filter?('sprint_id')
      sprint_ids = @query.values_for('sprint_id').map(&:to_i)
      @selected_sprint = Sprint.where(id: sprint_ids).first
    else
      @selected_sprint = params[:sprint_id] ? Sprint.find_by(id: params[:sprint_id]) : nil
    end

    # Handle status filtering
    filtered_status_ids = @query.filtered_statuses
    if filtered_status_ids.present?
      # Show only selected statuses in the specified order
      @statuses = IssueStatus.where(id: filtered_status_ids).sorted
      selected_statuses = @statuses
    else
      # Show all statuses if no filter is applied
      @statuses = IssueStatus.sorted
      selected_statuses = @statuses
    end

    # Build base scope for issues
    issue_scope = @selected_sprint ? @project.issues.where(sprint_id: @selected_sprint&.id) : @project.issues

    # Apply status filter if specified
    if filtered_status_ids.present?
      issue_scope = issue_scope.where(status_id: filtered_status_ids)
    end

    # Get issues and group by status
    issues = issue_scope.order(:board_position)
                      .includes(:assigned_to, :status, :priority)
    @issues = {}
    # Initialize empty arrays for all selected statuses
    selected_statuses.each { |status| @issues[status] = [] }

    # Group issues by their status
    issues.group_by(&:status).each do |status, status_issues|
      @issues[status] = status_issues if selected_statuses.include?(status)
    end

    # Calculate allowed transitions
    @allowed_transitions = {}
    @issues.values.flatten.each do |issue|
      @allowed_transitions[issue.id] = issue.new_statuses_allowed_to(User.current).map(&:id)
    end
  end

  def save_query
    @query.save if request.post? && @query.valid?
    redirect_to agile_board_index_path(project_id: @project, query_id: @query.id)
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
  def build_query
    @query = AgileQuery.new(project: @project)
    # Handle existing query loading
    if params[:query_id].present?
      existing_query = AgileQuery.find_by(id: params[:query_id])
      @query = existing_query if existing_query&.project == @project
    end
    # Build query from parameters
    @query.build_from_params(params, User.current.allowed_to?(:save_queries, @project))
    # Save query if requested
    if params[:save_query] && params[:query] && params[:query][:name].present?
      @query.user = User.current
      @query.project = @project
      @query.save
    end
  end
end