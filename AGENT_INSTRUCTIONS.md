# Agent Instructions: AI-Assisted Survey Research Platform

## Goal
Build a small but credible Ruby on Rails portfolio project that matches a Rails-based survey/research platform role with interest in AI-assisted development and LLM tools.

The product should feel like a real internal tool, not a generic CRUD demo.

## Product Summary
Create a lightweight survey research platform where a project manager can:

- sign in
- create and manage surveys
- add multiple question types
- publish a survey
- share a public response link
- review response results
- generate an AI summary from open-ended responses

Working product name candidates:

- InsightPulse
- SurveyPilot
- FeedbackLens

Use one of these unless the user chooses another name.

## Core Product Rules
- Prioritize Rails-native patterns over unnecessary frontend complexity.
- Keep the MVP small and polished.
- Do not introduce React or microservice complexity unless explicitly requested.
- Favor server-rendered Rails views with Hotwire/Turbo where helpful.
- AI should solve a real product problem, not exist as a gimmick.
- The first version must be demoable end to end.

## MVP Scope
The MVP must include:

- authentication for internal users
- survey CRUD
- question CRUD inside surveys
- question types:
  - multiple choice
  - scale 1-5
  - open text
- survey statuses:
  - draft
  - published
  - closed
- public response flow without login
- results dashboard for a survey
- AI summary for open text answers

## Nice-to-Have Features
Only add these after the MVP is solid:

- AI-generated question suggestions from a topic prompt
- response count and simple completion stats
- lightweight activity history
- CSV export
- basic role separation such as owner/admin

## Explicit Non-Goals for V1
Do not add these in the first iteration:

- drag-and-drop builders
- advanced branching logic
- multilingual support
- email campaign automation
- file uploads
- real-time collaboration
- complex permissions matrix
- overengineered analytics

## Recommended Technical Direction
- Ruby on Rails 7 or 8
- PostgreSQL
- Devise for authentication if appropriate
- Active Job with Solid Queue or Sidekiq for AI processing
- RSpec for model and request/system coverage
- Simple charts for results visualization
- Deploy target can be Render or Fly.io

## Domain Model Guidance
Use a clean, interview-friendly domain model. Suggested entities:

- `User`
- `Survey`
- `Question`
- `QuestionOption`
- `ResponseSession`
- `Answer`
- `AiReport`

Suggested relationships:

- a `User` owns many `Survey` records
- a `Survey` has many `Question` records
- a `Question` may have many `QuestionOption` records
- a `Survey` has many `ResponseSession` records
- a `ResponseSession` has many `Answer` records
- a `Survey` may have one or many `AiReport` records depending on implementation

## UX Guidance
The app should feel like a focused B2B SaaS admin tool.

- Keep the UI calm and practical.
- Optimize for clarity over decoration.
- Make the core workflow obvious:
  - create survey
  - add questions
  - publish
  - collect responses
  - review results
  - run AI summary
- Highlight survey status clearly.
- Keep the public answer flow frictionless.

## AI Feature Guidance
The primary AI feature is:

- summarize open-ended responses into:
  - key themes
  - sentiment overview
  - concise executive summary

Implementation guidance:

- run AI analysis asynchronously
- persist the AI summary in the database
- show loading and completed states in the UI
- allow regeneration of the summary

Optional secondary AI feature:

- generate suggested survey questions from a topic prompt

## Quality Bar
Before calling the project complete, ensure:

- the main flow works end to end
- code structure is understandable for a hiring manager
- naming is clean and consistent
- validations exist where expected
- tests cover the critical flows
- README explains setup, architecture, and AI features

## Delivery Mindset
This project is meant to signal:

- Rails competence
- product thinking
- domain understanding
- practical AI integration
- ability to ship a scoped feature set cleanly

When forced to choose, prefer:

1. a smaller finished product
2. cleaner UX
3. credible AI usage

over extra incomplete features.
