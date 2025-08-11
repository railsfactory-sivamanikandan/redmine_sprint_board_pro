class SprintService
  def initialize(sprint)
    @sprint = sprint
    @issues = @sprint.issues.includes(:status, :tracker, journals: :details, assigned_to: {})
    build_status_maps
  end

  # Returns array of [date_str, remaining_points]
  def burndown_series
    @sprint.burndown_data
  end

  # Returns { total: x, closed: y }
  def velocity_metrics
    total = @sprint.total_points.to_f
    closed = @issues.select { |i| issue_closed_on_or_before?(i, @sprint.end_date) }
                    .sum { |i| (i.story_points || 0).to_f }
    { total: total.round(2), closed: closed.round(2) }
  end

  # Cumulative Flow Diagram data (stacked area): { labels: [dates], datasets: [{label:, data:[], status_id:}, ...] }
  # Uses story_points per status per day; falls back to count if story_points missing.
  def cfd_series
    return { labels: [], datasets: [] } unless @sprint.start_date && @sprint.end_date
    days = (@sprint.start_date.to_date..@sprint.end_date.to_date).to_a
    labels = days.map { |d| d.strftime('%Y-%m-%d') }

    # statuses we care about (all statuses ever seen in these issues/journal status changes)
    status_ids = all_seen_status_ids
    statuses = IssueStatus.where(id: status_ids).order(:position)

    datasets = statuses.map do |status|
      data = days.map do |day|
        # sum story points of issues that existed by 'day' and whose status on that day was this status
        sum = @issues.select { |i| issue_existed_on?(i, day) && status_id_for_issue_on_date(i, day) == status.id }
                      .sum { |i| (i.story_points || 0).to_f }
        sum.round(2)
      end
      { label: status.name, data: data, status_id: status.id }
    end

    { labels: labels, datasets: datasets }
  end

  # Team contribution: sum of story_points closed during sprint by assigned_to_id
  # Returns array of { user_id:, user_name:, points: }
  def team_contribution
    closed_status_ids = closed_status_id_set
    counts = Hash.new(0.0)
    @issues.each do |issue|
      # find closure journal inside sprint range
      closure_journal = issue.journals.detect do |j|
        j.created_on && j.created_on >= @sprint.start_date.beginning_of_day &&
          j.created_on <= @sprint.end_date.end_of_day &&
          j.details.any? { |d| d.prop_key == 'status_id' && closed_status_ids.include?(d.value.to_i) }
      end
      next unless closure_journal

      user_id = issue.assigned_to_id || issue.author_id
      counts[user_id] += (issue.story_points || 0).to_f
    end

    # Map to user names
    counts.map do |user_id, pts|
      user = User.where(id: user_id).first
      { user_id: user_id, user_name: (user ? user.name : "User ##{user_id}"), points: pts.round(2) }
    end.sort_by { |h| -h[:points] }
  end

  # Issue type breakdown by tracker name (sum story points)
  # Returns array of { tracker_name:, points: }
  def issue_type_breakdown
    sums = @issues.group_by { |i| i.tracker&.name || 'Unknown' }
                  .map { |tracker_name, arr| { tracker_name: tracker_name, points: arr.sum { |i| (i.story_points || 0).to_f.round(2) } } }
    sums.sort_by { |h| -h[:points] }
  end

  # Returns { open_count:, closed_count:, open_points:, closed_points: }
  def open_closed_counts
    closed_ids = closed_status_id_set
    closed_issues = @issues.select { |i| status_closed?(i.status_id) }
    open_issues = @issues - closed_issues
    {
      open_count: open_issues.size,
      closed_count: closed_issues.size,
      open_points: open_issues.sum { |i| (i.story_points || 0).to_f }.round(2),
      closed_points: closed_issues.sum { |i| (i.story_points || 0).to_f }.round(2)
    }
  end

  private

  # Build maps for status_id -> is_closed and gather status ids seen in journals/details
  def build_status_maps
    ids = @issues.map(&:status_id).compact.uniq
    # gather historical status ids from journal details
    @issues.each do |i|
      i.journals.each do |j|
        j.details.each do |d|
          if d.prop_key == 'status_id' && d.value.present?
            ids << d.value.to_i
          end
        end
      end
    end
    ids.uniq!
    @status_map = IssueStatus.where(id: ids).pluck(:id, :is_closed, :name).index_by { |t| t[0] }
    # convert to helpful hashes:
    @status_is_closed = {}
    @status_name = {}
    @status_map.each do |id, tup|
      @status_is_closed[id] = tup[1]
      @status_name[id] = tup[2]
    end
  end

  def closed_status_id_set
    @status_is_closed.select { |k, v| v }.keys
  end

  def all_seen_status_ids
    @status_is_closed.keys
  end

  def status_closed?(status_id)
    @status_is_closed[status_id] == true
  end

  def issue_existed_on?(issue, day)
    issue.created_on && issue.created_on.to_date <= day
  end

  # Determine status id for an issue on a given day (based on journal history)
  def status_id_for_issue_on_date(issue, day)
    # find the latest journal up to day that changed status
    j = issue.journals.select { |jj| jj.created_on && jj.created_on <= day.end_of_day }.reverse.find do |jj|
      jj.details.any? { |d| d.prop_key == 'status_id' }
    end
    if j
      detail = j.details.select { |d| d.prop_key == 'status_id' }.last
      detail.value.to_i
    else
      issue.status_id
    end
  end

  # Whether the issue is closed on or before 'day' (checks status at that date)
  def issue_closed_on_or_before?(issue, day)
    sid = status_id_for_issue_on_date(issue, day)
    status_closed?(sid)
  end
end