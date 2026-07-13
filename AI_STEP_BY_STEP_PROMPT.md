# Step-by-step prompt for continuing InsightPulse

You are continuing development of a Ruby on Rails portfolio project called `InsightPulse`.

## Project Summary
InsightPulse is an AI-assisted survey research platform. A project manager can:

- sign in
- create surveys
- add questions of different types
- publish a survey
- share a public link
- collect anonymous responses
- view results and AI-generated summaries

The app already exists in the workspace and should be extended, not rebuilt.

## Current State
Already implemented:

- Rails 8 app with PostgreSQL
- authentication with sessions and passwords
- dashboard for signed-in users
- survey CRUD
- nested question CRUD
- question types:
  - multiple choice
  - scale
  - text
- public response flow without login
- response storage using `ResponseSession` and `Answer`
- results dashboard on the survey show page
- AI summary generation via `AiReportGenerator`, which now calls a real LLM (`AiSummary::AnthropicProvider`, Anthropic Messages API) when `ANTHROPIC_API_KEY` is set, and automatically falls back to a deterministic local heuristic (`AiSummary::HeuristicProvider`) if the key is missing or the call fails. See `README.md` "AI Summary Provider" section.
- tests and Rubocop were green as of the last verified run on a machine with the correct Ruby/bundler toolchain (3.3.11). NOTE: the most recent change (LLM provider integration, plus new tests in `test/services/ai_summary/anthropic_provider_test.rb` and `test/services/ai_report_generator_test.rb`) was only syntax-checked, not run through `bin/rails test` / `bin/rubocop`, because that was done from a sandboxed environment without a working Rails toolchain or network access to install gems. Run both before trusting this is still green.

## Main Goal
Continue improving the product in small, controlled steps without breaking the existing flow.

## Important Constraints
- Keep the app Rails-native.
- Do not introduce React or extra frontend complexity unless absolutely necessary.
- Keep the UI polished but practical.
- Prefer shipping one complete slice at a time.
- Preserve the existing working flows.
- Do not remove the current demo data or make breaking schema changes unless required.

## What to Do Next
Work in this order:

### 1. Understand the current code first
- Read the models, controllers, routes, and views related to:
  - `Survey`
  - `Question`
  - `ResponseSession`
  - `Answer`
  - `AiReport`
  - `PublicSurveysController`
  - `SurveysController`
  - `QuestionsController`
- Inspect the existing tests before making changes.
- Identify the smallest safe improvement that adds product value.

### 2. Improve the AI summary feature
Done: the AI summary is now backed by a real LLM (Anthropic Messages API) with an automatic heuristic fallback. Don't redo this.

Remaining improvement options here:
- add loading/status handling in the UI while a report is generating (currently synchronous via `perform_now`; consider a real background job + polling/Turbo Stream if async matters for the demo)
- show the most recent report and its timestamp more clearly, and surface report history (see item 4 in "concrete next task" below)
- surface which provider generated a given report more prominently (already stored in `provider_model`, just needs better UI treatment)

### 3. Improve survey results
The results section should continue to become more useful.

Good next additions:
- response counts per question
- better layout for open text answers
- show when a survey has no data yet
- make multiple choice and scale summaries easier to scan

### 4. Add small product polish
Only after the core flow is stable:
- better empty states
- clearer publish/closed states
- copy improvements
- tiny UI refinements
- simple export options if they fit naturally

## Recommended Implementation Style
- Make one focused change per iteration.
- Update tests alongside code.
- Verify with Rubocop and test suite after each meaningful change.
- If you change a user-visible flow, verify it in the browser too.
- Prefer server-rendered Rails views and simple helper methods.

## If You Need a Concrete Next Task
1. connect the AI summary to a real LLM provider — DONE, see Current State above
2. improve the survey results dashboard
3. add CSV export of survey responses
4. add a better report history view for `AiReport`

Pick 2, 3, or 4. Before starting, run `bin/rails test` and `bin/rubocop` to confirm the repo is actually green on this machine, since the last change couldn't be verified in a full toolchain.

## Example Output Expectations
When you continue, do not give generic advice. Actually make the change, verify it, and then report:

- what changed
- what was verified
- what the next logical step is

## Tone
Keep the project practical, polished, and portfolio-ready. This should feel like a real internal survey tool, not a demo toy.
