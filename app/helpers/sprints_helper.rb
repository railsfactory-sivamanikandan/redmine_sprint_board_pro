module SprintsHelper
  require 'csv'

  # Generate CSV export for sprints
  def sprints_to_csv(sprints)
    CSV.generate(headers: true) do |csv|
      csv << ['ID', 'Name', 'Start Date', 'End Date', 'Completed', 'Issues Count']
      sprints.each do |sprint|
        csv << [
          sprint.id,
          sprint.name,
          format_date(sprint.start_date),
          format_date(sprint.end_date),
          sprint.completed? ? 'Yes' : 'No',
          sprint.issues.count
        ]
      end
    end
  end

  # Generate plain text for PDF export (you can enhance this with Prawn later)
  def sprints_to_pdf(sprints)
    pdf = Redmine::Export::PDF::ITCPDF.new(User.current)
    pdf.SetTitle("Sprints List")
    pdf.AddPage

    pdf.SetFontStyle('B', 12)
    pdf.Cell(0, 10, "Sprints", 0, 1, 'L')
    pdf.SetFontStyle('', 10)

    sprints.each do |sprint|
      status = sprint.completed? ? 'Completed' : 'Active'
      pdf.Cell(0, 8, "#{sprint.name} (#{sprint.start_date} - #{sprint.end_date}) - #{status}", 0, 1)
    end

    pdf.Output("", "S")
  end

  def filename_for_export(entity, extension)
    project_part = @project.present? ? "#{@project.identifier}-" : ''
    timestamp = Time.now.strftime('%Y-%m-%d')
    "sprints-#{project_part}#{entity}-#{timestamp}.#{extension}"
  end
end
