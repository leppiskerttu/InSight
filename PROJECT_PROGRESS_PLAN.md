# Project Progress Plan: AI-Assisted Survey Research Platform

## Objective
Ship a small Ruby on Rails survey platform portfolio project with a real end-to-end workflow and one meaningful AI feature.

## Phase 0: Product Decision
Decide and lock these before implementation:

- product name
- Rails version
- auth approach
- background jobs approach
- deployment target
- AI provider

Recommended default choices:

- product name: `InsightPulse`
- Rails: latest stable Rails version
- auth: Devise
- jobs: Solid Queue first, Sidekiq if needed
- deploy: Render or Fly.io
- AI provider: whichever Ruby integration is simplest and easiest to explain

## Phase 1: App Foundation
Set up the base application.

Deliverables:

- create Rails app with PostgreSQL
- configure authentication
- set a simple layout and navigation
- create home/dashboard page
- configure test framework
- add environment variable handling for AI integration

Definition of done:

- app boots locally
- sign up/sign in works
- authenticated user reaches dashboard

## Phase 2: Survey Management
Build internal survey management.

Deliverables:

- create survey
- edit survey
- list surveys
- delete/archive survey if wanted
- add survey status:
  - draft
  - published
  - closed

Definition of done:

- a signed-in user can fully manage surveys from the UI

## Phase 3: Question Builder
Add question management within a survey.

Deliverables:

- create questions inside a survey
- support question types:
  - multiple choice
  - scale 1-5
  - open text
- add option management for multiple choice questions
- reorder questions if easy, otherwise skip for MVP

Definition of done:

- one survey can contain a valid mix of question types

## Phase 4: Public Response Flow
Build the responder-facing flow without login.

Deliverables:

- public survey page via tokenized or slug-based link
- answer submission flow
- success/thank-you page
- prevent submissions to closed surveys

Definition of done:

- an external user can complete a published survey and answers are stored correctly

## Phase 5: Results Dashboard
Show useful survey results to the internal user.

Deliverables:

- response count
- multiple choice distribution
- scale summary
- open text answer list
- survey detail dashboard

Definition of done:

- internal user can inspect results from one place without checking raw database data

## Phase 6: AI Summary
Add the core AI-assisted feature.

Deliverables:

- collect open text answers for a survey
- send them to an LLM through a background job
- store generated analysis in `AiReport`
- display:
  - key themes
  - sentiment overview
  - executive summary
- allow re-running the summary

Definition of done:

- user can trigger AI analysis and later view the stored result in the UI

## Phase 7: Polish
Improve usability and presentation without expanding scope too much.

Deliverables:

- cleaner dashboard layout
- loading states and empty states
- status badges
- basic validations and error messages
- better seed data for demos
- improved README

Definition of done:

- app feels coherent and demo-ready

## Phase 8: Testing and Deployment
Make the project credible as a portfolio piece.

Deliverables:

- tests for core models
- request or system tests for main flows
- deployment configuration
- production environment variables documented
- screenshots or demo instructions in README

Definition of done:

- project runs locally from README
- project is deployed or deployment-ready

## Suggested Build Order
Build in this order to keep momentum and reduce rework:

1. app setup
2. authentication
3. surveys
4. questions
5. public responses
6. results dashboard
7. AI summary
8. polish
9. tests and deploy

## Suggested MVP Demo Script
Use this when the app is ready:

1. sign in as project manager
2. create a survey
3. add one multiple choice question
4. add one scale question
5. add one open text question
6. publish the survey
7. open the public link and submit a response
8. return to the dashboard and inspect results
9. run AI summary
10. show the generated insights

## Time-Conscious Scope Control
If time gets tight, keep these at all costs:

- survey CRUD
- three question types
- public response flow
- results dashboard
- one working AI summary feature

Cut these first if needed:

- question reordering
- export features
- extra roles
- visual polish beyond basics
- secondary AI features

## Final Portfolio Checklist
Before presenting the project, confirm:

- the product has a clear name
- the README explains the use case
- setup instructions work
- sample data exists
- the UI has no broken flows
- the AI feature is easy to demo
- the code reflects deliberate scope choices
