class DashboardController < ApplicationController
  def index
    @surveys = Current.user.surveys.recent_first.limit(5)
    @published_surveys_count = Current.user.surveys.published.count
    @draft_surveys_count = Current.user.surveys.draft.count
    @response_count = ResponseSession.joins(:survey).where(survey: { user_id: Current.user.id }).count
  end
end
