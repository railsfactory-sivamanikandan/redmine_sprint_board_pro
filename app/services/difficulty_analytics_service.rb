class DifficultyAnalyticsService
  def initialize(sprint)
    @sprint = sprint
    @issues = sprint.issues
  end

  # Chart 1: Velocity by Difficulty
  def velocity_by_difficulty
    grouped = @issues.group(:difficulty).sum(:story_points)
    format_difficulty_hash(grouped)
  end

  # Chart 2: Planned vs Completed by Difficulty
  def planned_vs_completed
    planned = @issues.group(:difficulty).sum(:story_points)
    completed = @issues.closed.group(:difficulty).sum(:story_points)

    all_difficulties.each_with_object({}) do |diff, hash|
      hash[diff] = {
        planned: planned[diff] || 0,
        completed: completed[diff] || 0
      }
    end
  end

  # Chart 3: Burndown by Difficulty
  def burndown_by_difficulty
    start_date = @sprint.start_date
    end_date = @sprint.end_date
    days = (start_date..end_date).to_a

    all_difficulties.map do |diff|
      remaining_points = total_points_for(diff)
      series = days.map do |day|
        closed_points = @issues.closed.where(difficulty: diff)
                                      .where("closed_on <= ?", day)
                                      .sum(:story_points)
        [day, [remaining_points - closed_points, 0].max]
      end
      { difficulty: diff, series: series }
    end
  end

  # Chart 4: Difficulty Distribution Pie
  def difficulty_distribution
    velocity_by_difficulty
  end

  # Chart 5: Historical Difficulty Trend
  def difficulty_trend
    @sprint.project.sprints.order(:start_date).map do |s|
      {
        sprint: s.name,
        data: s.issues.group(:difficulty).sum(:story_points)
      }
    end
  end

  # Chart 6: Team Contribution by Difficulty
  def team_contribution_by_difficulty
    @issues.joins(:assigned_to)
           .group("users.login", :difficulty)
           .sum(:story_points)
           .each_with_object({}) do |((user, diff), points), hash|
      hash[user] ||= {}
      hash[user][diff] = points
    end
  end

  # Chart 7: Difficulty vs Cycle Time
  def difficulty_vs_cycle_time
    @issues.closed.map do |issue|
      {
        id: issue.id,
        difficulty: issue.difficulty || "Unspecified",
        story_points: issue.story_points || 0,
        cycle_time: (issue.closed_on - issue.created_on).to_i
      }
    end
  end

  # Chart 8: Difficulty vs Bugs Introduced
  def difficulty_vs_bugs
    bugs = @issues.joins(:tracker)
                  .where(trackers: { name: 'Bug' })
                  .group(:difficulty)
                  .count
    format_difficulty_hash(bugs)
  end

  def developer_difficulty_points
    issues = @sprint.issues.includes(:assigned_to)
    difficulties = %w[easy medium hard unspecified]

    data = Hash.new { |h, k| h[k] = Hash.new(0) }

    issues.each do |issue|
      dev_name = issue.assigned_to&.name || "Unassigned"
      diff = issue.difficulty.to_s.downcase.presence || "unspecified"
      diff = "unspecified" unless difficulties.include?(diff)

      points = issue.story_points.to_f
      data[dev_name][diff] += points
    end

    # Ensure all difficulties exist for each dev
    data.each do |_dev, diff_hash|
      difficulties.each { |d| diff_hash[d] ||= 0 }
    end

    data
  end

  private

  def all_difficulties
    %w[easy medium hard unspecified]
  end

  def total_points_for(difficulty)
    @issues.where(difficulty: difficulty).sum(:story_points)
  end

  def format_difficulty_hash(raw_hash)
    all_difficulties.index_with { |diff| raw_hash[diff] || 0 }
  end
end