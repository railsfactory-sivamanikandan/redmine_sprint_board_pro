class SprintsController < ApplicationController
  before_action :find_project
  before_action :find_sprint, only: [:show, :edit, :update, :destroy, :toggle_completed, :dashboard]
  include SprintsHelper
  def index
    status = params[:status]
    tag = params[:tag]
    @status_filter = params[:status]

    scope = @project.sprints.order(created_at: :desc)
    if status.present?
      scope = scope.where(completed: false) if @status_filter == 'active'
      scope = scope.where(completed: true) if @status_filter == 'completed'
    end

    if tag.present?
      scope = scope.joins(:issues).merge(Issue.tagged_with(tag)).distinct
    end

    respond_to do |format|
      format.html do
        @sprint_count = scope.count
        @limit = per_page_option
        @sprint_pages = Paginator.new @sprint_count, @limit, params[:page]
        @offset = @sprint_pages.offset
        @sprints = scope.offset(@offset).limit(@limit)
      end
      format.csv do
        send_data(sprints_to_csv(scope),
          type: 'text/csv; header=present',
          filename: "#{filename_for_export(@project, 'sprints')}.csv")
      end

      format.pdf do
        pdf_data = sprints_to_pdf(scope)
        send_data pdf_data,
          type: 'application/pdf',
          disposition: 'attachment',
          filename: "#{filename_for_export(@project, 'sprints')}.pdf"
      end
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
      redirect_to project_sprints_path(@project), notice: 'Sprint created successfully.'
    else
      render :new
    end
  end

  def edit; end

  def update
    if @sprint.update(sprint_params)
      assign_issues_to_sprint
      redirect_to project_sprints_path(@project), notice: 'Sprint updated successfully.'
    else
      render :edit
    end
  end

  def destroy
    @sprint.destroy
    redirect_to project_sprints_path(@project), notice: 'Sprint deleted.'
  end

  def toggle_completed
    @sprint.update(completed: !@sprint.completed)
    redirect_to project_sprints_path(@project)
  end

  def dashboard
    render_403 unless User.current.allowed_to?(:view_agile_board, @project)
    service = SprintService.new(@sprint)
    @burndown = service.burndown_series            # [[date, remaining], ...]
    @velocity = service.velocity_metrics           # { total:, closed: }
    @cfd = service.cfd_series                      # { labels: [...], datasets: [...] }
    @team = service.team_contribution              # [{user_name:, points:}, ...]
    @issue_types = service.issue_type_breakdown    # [{tracker_name:, points:}, ...]
    @open_closed = service.open_closed_counts
  end

  private

  def find_project
    @project = Project.find(params[:project_id])
  end

  def find_sprint
    @sprint = @project.sprints.find(params[:id])
  end

  def sprint_params
    params.require(:sprint).permit(:name, :start_date, :end_date, :completed)
  end

  def assign_issues_to_sprint
    issue_ids = params[:issue_ids] || []
    Issue.where(id: issue_ids).update_all(sprint_id: @sprint.id)
  end
end