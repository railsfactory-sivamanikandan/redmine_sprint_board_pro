module SprintEmailHelper
  # Sends email only if Agile Board module is enabled
  def send_sprint_email(mailer_class, method, *args)
    if async_enabled? && mailer_class.respond_to?(:deliver_later)
      mailer_class.public_send(method, *args).deliver_later
    else
      mailer_class.public_send(method, *args).deliver_now
    end
  end

  # Common logic to check module & send sprint completed mail
  def send_sprint_completed_email(sprint)
    project = sprint.project
    return unless project.module_enabled?(:agile_board)
    return unless Setting.plugin_redmine_sprint_board_pro['notify_on_sprint_completed'] == '1'

    manager = project.manager # Ensure you have this relation in Project model
    return unless manager&.mail.present?
    send_sprint_email(SprintMailer, :sprint_completed, sprint.id, manager.mail)
  end

  # Common logic to send monthly report
  def send_monthly_report_email(project, report_data)
    return unless project.module_enabled?(:agile_board)
    return unless Setting.plugin_redmine_sprint_board_pro['monthly_report_enabled'] == '1'

    manager = project.manager
    recipients = manager.mail.present? ? [manager.mail] : []
    Setting.plugin_redmine_sprint_board_pro['monthly_report_receivers'].split(',').each do |email|
      recipients << email.strip
    end
    return unless recipients.present?
    send_sprint_email(SprintMailer, :monthly_report, project, manager, report_data)
  end

  def async_enabled?
    # Check if ActiveJob is configured to a real queue
    adapter = ActiveJob::Base.queue_adapter
    adapter.present? && !adapter.is_a?(ActiveJob::QueueAdapters::InlineAdapter)
  end
end