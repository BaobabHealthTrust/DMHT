class ClinicController < GenericClinicController
  def reports_tab
    @reports = [
      ["DM Report", "/cohort_tool/dm_cohort_report_options"]
    ]

    render :layout => false
  end
end
