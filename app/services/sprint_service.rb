class SprintService
  def initialize(sprint)
    @sprint = sprint
  end

  def burndown_points
    # Example: returns array of [date, remaining_points]
    @sprint.burndown_data || []
  end

  def velocity
    {
      total: @sprint.issues.sum(:story_points),
      closed: @sprint.issues.closed.sum(:story_points)
    }
  end
end