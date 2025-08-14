class SprintMailer < ActionMailer::Base
  helper :application
  default from: Setting.mail_from
  before_action :set_host

  def sprint_completed(sprint_id, recipients)
    @sprint = Sprint.find_by(id: sprint_id)
    return unless @sprint

    @project = @sprint.project
    @metrics = RedmineSprintBoardPro::SprintReportService.new(@sprint) rescue nil
    mail to: recipients, subject: "[#{@project.name}] Sprint completed: #{@sprint.name}"
  end

  def monthly_report(project, recipients, summary)
    @project = project
    @summary = summary

    return unless @project

    mail to: recipients, subject: "[#{@project.name}] Monthly sprint report (#{summary[:period_start].strftime('%b %Y')} to #{summary[:period_end].strftime('%b %Y')})"
  end

  private

  # Ensure host is set for URL helpers in emails
  def set_host
    self.default_url_options[:host] = Setting.host_name
  end
end