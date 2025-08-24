class SprintsController < ApplicationController
  before_action :find_project
  before_action :find_sprint, only: %i[
    show edit update destroy toggle_completed dashboard
  ]

  include SprintsHelper
  include SprintEmailHelper

  def index
    scope = filtered_sprints(@project.sprints.order(created_at: :desc))

    respond_to do |format|
      format.html { paginate_sprints(scope) }
      format.csv  { export_csv(scope) }
      format.pdf  { export_pdf(scope) }
    end
  end

  def show; end

  def new
    @sprint = Sprint.new
  end

  def create
    @sprint = @project.sprints.build(sprint_params)
    if @sprint.save
      assign_issues_to_sprint
      redirect_to project_sprints_path(@project), notice: l(:text_sprint_created)
    else
      render :new
    end
  end

  def edit; end

  def update
    if @sprint.update(sprint_params)
      assign_issues_to_sprint
      redirect_to project_sprints_path(@project), notice: l(:text_sprint_updated)
    else
      render :edit
    end
  end

  def destroy
    @sprint.destroy
    redirect_to project_sprints_path(@project), notice: l(:text_sprint_deleted)
  end

  def toggle_completed
    @sprint.toggle!(:completed)
    send_sprint_completed_email(@sprint) if @sprint.completed?
    redirect_to project_sprints_path(@project)
  end

  def dashboard
    render_403 unless User.current.allowed_to?(:view_agile_board, @project)

    @velocity = SprintService.new(@sprint).velocity_metrics

    params[:chart_type] == 'difficulty' ? load_difficulty_charts : load_normal_charts
  end

  private

  # ----------------------
  # Filters
  # ----------------------
  def find_project
    @project = Project.find(params[:project_id])
  end

  def find_sprint
    @sprint = @project.sprints.find(params[:id])
  end

  def sprint_params
    params.require(:sprint).permit(:name, :start_date, :end_date, :completed)
  end

  # ----------------------
  # Helpers
  # ----------------------
  def assign_issues_to_sprint
    (params[:issue_ids] || []).each do |id|
      Issue.where(id: id).update_all(sprint_id: @sprint.id)
    end
  end

  def filtered_sprints(scope)
    scope = case params[:status]
            when 'active'    then scope.where(completed: false)
            when 'completed' then scope.where(completed: true)
            else scope
            end

    if params[:tag].present?
      scope = scope.joins(:issues).merge(Issue.tagged_with(params[:tag])).distinct
    end

    scope
  end

  def paginate_sprints(scope)
    @sprint_count = scope.count
    @limit        = per_page_option
    @sprint_pages = Paginator.new(@sprint_count, @limit, params[:page])
    @offset       = @sprint_pages.offset
    @sprints      = scope.offset(@offset).limit(@limit)
  end

  def export_csv(scope)
    send_data sprints_to_csv(scope),
              type: 'text/csv; header=present',
              filename: "#{filename_for_export(@project, 'sprints')}.csv"
  end

  def export_pdf(scope)
    send_data sprints_to_pdf(scope),
              type: 'application/pdf',
              disposition: 'attachment',
              filename: "#{filename_for_export(@project, 'sprints')}.pdf"
  end

  def load_normal_charts
    service = SprintService.new(@sprint)
    @burndown     = service.burndown_series
    @cfd          = service.cfd_series
    @team         = service.team_contribution
    @issue_types  = service.issue_type_breakdown
    @open_closed  = service.open_closed_counts
  end

  def load_difficulty_charts
    service = DifficultyAnalyticsService.new(@sprint)
    @velocity_by_difficulty   = service.velocity_by_difficulty
    @planned_vs_completed     = service.planned_vs_completed
    @burndown_by_difficulty   = service.burndown_by_difficulty
    @difficulty_distribution  = service.difficulty_distribution
    @difficulty_trend         = service.difficulty_trend
    @team_contribution_diff   = service.team_contribution_by_difficulty
    @difficulty_vs_cycle_time = service.difficulty_vs_cycle_time
    @difficulty_vs_bugs       = service.difficulty_vs_bugs
    @developer_difficulty_points = service.developer_difficulty_points
  end
end