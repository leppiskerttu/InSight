module SurveysHelper
  def survey_status_badge(status)
    content_tag(:span, status.humanize, class: "status-badge status-badge--#{status}")
  end
end
