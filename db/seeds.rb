# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).
#
# Example:
#
#   ["Action", "Comedy", "Drama", "Horror"].each do |genre_name|
#     MovieGenre.find_or_create_by!(name: genre_name)
#   end
demo_user = User.find_or_create_by!(email_address: "demo@example.com") do |user|
  user.password = "password123"
end

survey = demo_user.surveys.find_or_create_by!(title: "Developer experience pulse") do |record|
  record.description = "A small seed survey for testing the initial product flow."
  record.status = :draft
end

if survey.questions.empty?
  survey.questions.create!([
    {
      prompt: "How clear is our current development workflow?",
      question_type: :scale,
      required: true,
      position: 1
    },
    {
      prompt: "Which tooling helps you most day to day?",
      question_type: :multiple_choice,
      required: true,
      position: 2
    },
    {
      prompt: "What is one improvement we should make next?",
      question_type: :text,
      required: false,
      position: 3
    }
  ])
end

multiple_choice_question = survey.questions.find_by(question_type: :multiple_choice)

if multiple_choice_question.present? && multiple_choice_question.question_options.empty?
  multiple_choice_question.question_options.create!([
    { label: "AI coding assistant", value: "ai_assistant", position: 1 },
    { label: "Automated tests", value: "automated_tests", position: 2 },
    { label: "Local scripts", value: "local_scripts", position: 3 }
  ])
end
