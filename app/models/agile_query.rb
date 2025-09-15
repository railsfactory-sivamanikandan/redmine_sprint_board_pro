class AgileQuery < Query
  self.queried_class = Issue

  def initialize(attributes=nil, *args)
    super attributes
    self.filters ||= {}
  end

  def initialize_available_filters
    super

    # Add status filter specifically for agile board
    add_available_filter "status_id",
      type: :list_status,
      name: l(:field_status),
      values: lambda {
        project_statuses = @project ? @project.rolled_up_statuses : IssueStatus.sorted
        project_statuses.collect { |s| [s.name, s.id.to_s] }
      }

    add_available_filter "sprint_id",
      type: :list,
      name: l(:label_sprint),
      values: lambda {
        sprints = @project ? @project.sprints.order(start_date: :desc) : Sprint.all
        sprints.map { |s| [s.name, s.id.to_s] }
      }
  end

  def available_columns
    return @available_columns if @available_columns
    @available_columns = [
      QueryColumn.new(:id, sortable: "#{Issue.table_name}.id"),
      QueryColumn.new(:subject, sortable: "#{Issue.table_name}.subject"),
      QueryColumn.new(:status, sortable: "#{IssueStatus.table_name}.position"),
      QueryColumn.new(:assigned_to, sortable: lambda {User.fields_for_order_statement}),
      QueryColumn.new(:priority, sortable: "#{IssuePriority.table_name}.position"),
      QueryColumn.new(:story_points),
    ]
  end

  def default_columns_names
    [:id, :subject, :status, :assigned_to, :story_points]
  end

  # Card field preferences
  def card_fields
    column_names.present? ? column_names.map(&:to_s) : default_card_fields
  end

  def default_card_fields
    %w[id subject priority assigned_to story_points]
  end

  def update_card_fields(fields)
    self.column_names = fields.is_a?(Array) ? fields.map(&:to_sym) : []
    save
  end

  def filtered_statuses
    return nil unless has_filter?('status_id')
    values = values_for('status_id')
    return nil if values.blank?
    values.map(&:to_i)
  end

  def base_scope
    Issue.visible.joins(:status, :project).where(project: @project)
  end

  # Simple build method that avoids problematic visibility handling
  def build_from_params(params, user_can_save_queries = false)
    # Clear existing filters to avoid carrying over previous values
    self.filters = {}

    # Redmine uses params[:op], params[:v] for filters
    if params[:op] && params[:v]
      params[:op].each do |field, operator|
        # Only process if there are actual values for this field
        field_values = params[:v][field]
        next unless field_values.present?

        # Clean up the values - reject blank/empty strings
        values = Array(field_values).reject(&:blank?)

        # Only add filter if there are actual non-blank values
        if available_filters.key?(field) && values.any?
          add_filter(field, operator, values)
        end
      end
    end

    # Handle sprint_id separately and only if it has a value
    if params[:sprint_id].present? && params[:sprint_id] != ""
      add_filter('sprint_id', '=', [params[:sprint_id].to_s])
    end

    # Handle card field configuration
    if params[:c].present?
      self.column_names = Array(params[:c]).map(&:to_sym)
    end

    # Save basic attributes
    if user_can_save_queries && params[:query]
      self.name = params[:query][:name] if params[:query][:name].present?
      self.visibility = params[:query][:visibility].to_i if params[:query][:visibility].present?
    end

    self
  end

  # Override statement to handle our custom filtering
  def statement
    filters_clauses = []

    filters.each do |field, options|
      next if field == 'status_id' # This is handled in the controller
      next unless options.is_a?(Hash)

      operator = options[:operator]
      values = options[:values]
      next if values.blank?

      begin
        sql = sql_for_field(field, operator, values, queried_table_name, field)
        filters_clauses << sql if sql.present?
      rescue => e
        Rails.logger.error "Error building SQL for field #{field}: #{e.message}"
      end
    end

    filters_clauses.reject!(&:blank?)
    filters_clauses.any? ? filters_clauses.join(' AND ') : nil
  end
end