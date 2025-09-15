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
    all_status_ids = IssueStatus.pluck(:id)

    # Check if all statuses are selected (equivalent to no filter)
    if filtered_status_ids.present? && filtered_status_ids.sort != all_status_ids.sort
      # Show only selected statuses in the specified order
      @statuses = IssueStatus.where(id: filtered_status_ids).sorted
      selected_statuses = @statuses
    else
      # Show all statuses if no filter is applied or all are selected
      @statuses = IssueStatus.sorted
      selected_statuses = @statuses
      # Clear the filter if all statuses are selected to avoid confusion
      filtered_status_ids = nil if filtered_status_ids.present? && filtered_status_ids.sort == all_status_ids.sort
    end

    # Build base scope for issues
    issue_scope = @selected_sprint ? @project.issues.where(sprint_id: @selected_sprint&.id) : @project.issues

    # Apply status filter if specified
    if filtered_status_ids.present?
      issue_scope = issue_scope.where(status_id: filtered_status_ids)
    end

    # Apply additional filters from query parameters
    issue_scope = apply_filters(issue_scope)

    # Get issues and group by status
    issues = issue_scope.order(:board_position)
                      .includes(:assigned_to, :status, :priority, :tracker)

    # Group issues by their status first
    issues_by_status = issues.group_by(&:status)

    # Only show statuses that have issues after filtering
    # If additional filters are applied (beyond status), only show columns with issues
    has_additional_filters = has_non_status_filters?

    if has_additional_filters
      if issues_by_status.any?
        # Only show statuses that have matching issues after applying all filters
        @statuses = issues_by_status.keys.select { |status| selected_statuses.include?(status) }.sort_by(&:position)
        @issues = {}
        @statuses.each { |status| @issues[status] = issues_by_status[status] || [] }
      else
        # No issues match the additional filters - show empty state
        @statuses = []
        @issues = {}
      end
    else
      # Only status filter (or no filters) - show all selected statuses with their issues
      @statuses = selected_statuses
      @issues = {}

      # Initialize all selected statuses with empty arrays
      selected_statuses.each { |status| @issues[status] = [] }

      # Fill in the issues for each status
      issues_by_status.each do |status, status_issues|
        @issues[status] = status_issues if selected_statuses.include?(status)
      end
    end

    # Calculate allowed transitions
    @allowed_transitions = {}
    @issues.values.flatten.each do |issue|
      @allowed_transitions[issue.id] = issue.new_statuses_allowed_to(User.current).map(&:id)
    end

    # Set selected card fields from query
    @selected_card_fields = @query.card_fields
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

  def save_card_preferences
    if params[:card_fields].present?
      # Find or create a query for this user and project for card preferences
      query_name = "Card Preferences - #{@project.name}"
      query = AgileQuery.where(user: User.current, project: @project, name: query_name).first_or_initialize

      query.update_card_fields(params[:card_fields])
      query.visibility = 0 # Private query

      if query.save
        render json: { success: true, message: 'Card preferences saved successfully' }
      else
        render json: { error: 'Failed to save card preferences' }, status: :unprocessable_entity
      end
    else
      render json: { error: 'No card fields specified' }, status: :unprocessable_entity
    end
  end

  private

  def find_project
    @project = Project.find(params[:project_id])
  end

  def find_issue
    @issue = @project.issues.find(params[:id])
  end

  def apply_filters(scope)
    # Apply priority filter
    if params.dig(:v, :priority_id).present?
      priority_ids = Array(params[:v][:priority_id]).reject(&:blank?)
      scope = scope.where(priority_id: priority_ids) if priority_ids.any?
    end

    # Apply tracker filter
    if params.dig(:v, :tracker_id).present?
      tracker_ids = Array(params[:v][:tracker_id]).reject(&:blank?)
      scope = scope.where(tracker_id: tracker_ids) if tracker_ids.any?
    end

    # Apply assignee filter
    if params.dig(:v, :assigned_to_id).present?
      assignee_ids = Array(params[:v][:assigned_to_id]).reject(&:blank?)
      if assignee_ids.include?('') # Include unassigned
        scope = scope.where('assigned_to_id IS NULL OR assigned_to_id IN (?)', assignee_ids)
      else
        scope = scope.where(assigned_to_id: assignee_ids)
      end
    end

    # Apply story points filter
    if params.dig(:v, :story_points).present?
      story_points_values = Array(params[:v][:story_points]).reject(&:blank?)
      if story_points_values.any?
        operator = params.dig(:op, :story_points) || '='
        case operator
        when '='
          scope = scope.where(story_points: story_points_values.first.to_f)
        when '>='
          scope = scope.where('story_points >= ?', story_points_values.first.to_f)
        when '<='
          scope = scope.where('story_points <= ?', story_points_values.first.to_f)
        when '><'
          if story_points_values.length >= 2
            scope = scope.where('story_points BETWEEN ? AND ?',
                               story_points_values.first.to_f,
                               story_points_values.second.to_f)
          end
        when '!*'
          scope = scope.where('story_points IS NULL OR story_points = 0')
        when '*'
          scope = scope.where('story_points IS NOT NULL AND story_points > 0')
        end
      end
    end

    # Apply difficulty filter
    if params.dig(:v, :difficulty).present?
      difficulty_values = Array(params[:v][:difficulty]).reject(&:blank?)
      scope = scope.where(difficulty: difficulty_values) if difficulty_values.any?
    end

    scope
  end

  def has_non_status_filters?
    # Check if any filters other than status are applied
    # Need to check for actual non-blank values, not just presence
    return true if params.dig(:v, :priority_id).present? && Array(params[:v][:priority_id]).reject(&:blank?).any?
    return true if params.dig(:v, :tracker_id).present? && Array(params[:v][:tracker_id]).reject(&:blank?).any?
    return true if params.dig(:v, :assigned_to_id).present? && Array(params[:v][:assigned_to_id]).reject(&:blank?).any?
    return true if params.dig(:v, :story_points).present? && Array(params[:v][:story_points]).reject(&:blank?).any?
    return true if params.dig(:v, :difficulty).present? && Array(params[:v][:difficulty]).reject(&:blank?).any?

    false
  end

  def build_query
    @query = AgileQuery.new(project: @project)

    # Handle existing query loading
    if params[:query_id].present?
      existing_query = AgileQuery.find_by(id: params[:query_id])
      if existing_query&.project == @project
        @query = existing_query
        # Don't load card fields from saved queries - keep them separate
        load_user_card_preferences unless params[:c].present?
      end
    else
      # Load user's card preference query if no explicit fields specified
      load_user_card_preferences unless params[:c].present?
    end

    # Build query from parameters (including card fields)
    @query.build_from_params(params, User.current.allowed_to?(:save_queries, @project))

    # Save query if requested (but exclude card fields from saved queries)
    if params[:save_query] && params[:query] && params[:query][:name].present?
      # Temporarily remove card fields for saving
      temp_columns = @query.column_names
      @query.column_names = []

      @query.user = User.current
      @query.project = @project
      @query.save

      # Restore card fields for current use
      @query.column_names = temp_columns
    end
  end

  def load_user_card_preferences
    preference_query = AgileQuery.where(
      user: User.current,
      project: @project,
      name: "Card Preferences - #{@project.name}"
    ).first

    if preference_query
      @query.column_names = preference_query.column_names
    end
  end
end