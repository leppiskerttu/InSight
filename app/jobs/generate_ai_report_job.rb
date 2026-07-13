class GenerateAiReportJob < ApplicationJob
  queue_as :default

  def perform(report_id)
    report = AiReport.find(report_id)
    AiReportGenerator.call(report)
  end
end
