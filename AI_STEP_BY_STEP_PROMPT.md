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
- CSV export of survey responses: `Survey#responses_to_csv`, wired up via `GET /surveys/:id/export_responses.csv` (`SurveysController#export_responses`), with an "Export CSV" link on the survey show page next to "Generate AI summary". One row per `ResponseSession`, one column per question (ordered by position); multiple-choice cells show the option label, scale cells the numeric value, text cells the raw answer; unanswered questions render as a blank cell. Tests in `test/models/survey_test.rb` and `test/controllers/surveys_controller_test.rb`.
- AI question enhancement: an "Enhance with AI" button on the question new/edit form (`app/views/questions/_form.html.erb`) rewrites a rough draft question via `QuestionEnhancer`, and also surfaces 1-3 short "Ideas to make it even better" suggestions (e.g. switch to multiple choice, add a follow-up question) under the field when a real LLM produced them. Default provider is `QuestionEnhancement::OpenAiProvider` (OpenAI Chat Completions API, `OPENAI_API_KEY` / `OPENAI_MODEL`, default model `gpt-4o-mini`), with automatic fallback to `QuestionEnhancement::HeuristicProvider` (capitalize + ensure trailing "?", no suggestions) if the key is missing or the call fails — same fallback pattern as the AI summary feature, but a separate provider/key: summaries stay on Anthropic, question enhancement uses OpenAI. `QuestionEnhancement::Result#suggestions` defaults to `[]` if a provider doesn't supply any. Implemented server-rendered (no JS/Turbo wiring): the "Enhance" button is a second submit button (`name="enhance_prompt"`) on the same create/update form; the controller detects it, calls the enhancer, and re-renders the form with the improved prompt (and `@ai_suggestions`) instead of saving. See `README.md` "Question Enhancement" section. Tests in `test/services/question_enhancement/`, `test/services/question_enhancer_test.rb`, `test/controllers/questions_controller_test.rb`.
- local secrets (`OPENAI_API_KEY`, `ANTHROPIC_API_KEY`, and their `*_MODEL` overrides) load from a gitignored `.env` via the `dotenv-rails` gem (`:development, :test` Gemfile group only — never production). `.env.example` is the committed, secret-free template; copy it to `.env` and fill in real keys. **Important**: `.env.test` is also committed on purpose and blanks both AI keys for the `test` environment — this is required, not optional, because `dotenv-rails` loads the base `.env` for every environment by default, and without this override the test suite would silently make real, billed API calls using whatever is in a developer's local `.env`. This was caught and fixed in this session (two controller tests failed by getting real OpenAI output instead of the expected heuristic output, which is exactly how the leak was noticed). If you ever see `test/controllers/questions_controller_test.rb`'s enhance tests fail with real-looking AI text instead of `"Favorite coding language?"`, check `.env.test` still exists and still blanks both keys.
- AI report generation is now async with a live-updating UI, no polling or manual refresh: `AiReportsController#create` creates the `AiReport` synchronously as `pending` and redirects immediately; `GenerateAiReportJob` (Active Job, `:async` adapter in dev — in-process, no separate worker needed, confirmed via `Rails.application.config.active_job.queue_adapter`) does the LLM call via `AiReportGenerator` (now takes an existing report, not a survey — `AiReportGenerator.call(report)`) and updates it to `completed`/`failed`; `AiReport#after_update_commit` broadcasts a Turbo Stream replace of the `#ai_summary` DOM node (partial extracted to `app/views/surveys/_ai_summary.html.erb`) to a stream scoped to the survey (`turbo_stream_from @survey` in `show.html.erb`). This required bootstrapping a JS pipeline that didn't exist before (the app was 100% server-rendered, zero `<script>` tags, no `config/importmap.rb`, no `app/javascript/`, despite `turbo-rails`/`stimulus-rails`/`importmap-rails` already sitting unused in the Gemfile) — ran `bin/rails importmap:install` then `bin/rails turbo:install`, and manually added `mount ActionCable.server => "/cable"` to `config/routes.rb` (the turbo:install generator did not add it automatically here). Verified as a genuine live push (not a lucky fast redirect) by loading the survey page, confirming `<turbo-cable-stream-source connected="">` in the DOM, then triggering generation via `fetch()` with `redirect: 'manual'` from the browser console so the tab's `window.location` never changed, and observing the `#ai_summary` timestamp update in place. Tests: `test/jobs/generate_ai_report_job_test.rb` (new), `test/services/ai_report_generator_test.rb` (updated call signature), `test/controllers/surveys_controller_test.rb` (updated — asserts `pending` immediately after the request, `completed` after `perform_enqueued_jobs`). `test/test_helper.rb` now includes `ActiveJob::TestHelper` (needed for `assert_enqueued_with`/`perform_enqueued_jobs`, not included by default).
- tests and Rubocop are green as of 2026-07-13, run on this machine with Ruby 3.3.11 via rbenv (`~/.rbenv/versions/3.3.11`, not on PATH by default — as of this session `~/.zshrc` now permanently activates it, see below). `bin/rails test`: 69 runs, 0 failures. `bin/rubocop`: 84 files, no offenses.
- Three toolchain fixes were needed to get here and are now in place: (1) minitest 6.x dropped `Object#stub`/`Minitest::Mock` out of core — added `gem "minitest-mock"` to the `:test` group in `Gemfile` and `require "minitest/mock"` in `test/test_helper.rb`. (2) `csv` is being removed from Ruby's default gems starting 3.4 — added `gem "csv"` to `Gemfile` explicitly (used by CSV export) to avoid a future load failure. (3) `dotenv-rails` added for local secret loading — see `.env.test` note above for the gotcha it introduced and how it's handled.
- `~/.zshrc` (outside the repo) now has rbenv's init lines appended, so a fresh interactive terminal gets Ruby 3.3.11 automatically — `bin/dev` etc. no longer need the manual `export PATH=...` prefix. Only applies to this specific machine, not something to redo per-session.
- Known pre-existing bug, not yet fixed: if a multiple-choice question fails to save (no options given), `QuestionsController#save_question_with_options` re-renders the form, but the `option_list` textarea shows `question.options_text` (from the DB-backed association) instead of what the user just typed, silently discarding their input. Noticed but out of scope when CSV export/AI features were the focus — see README "Near-Term Build Plan".

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
Done: the AI summary is now backed by a real LLM (Anthropic Messages API) with an automatic heuristic fallback. Also done: async generation with a live-updating UI via Turbo Streams (no more `perform_now`, no polling). Don't redo either of these.

Remaining improvement options here:
- show report history, not just the latest (see item 4 in "concrete next task" below)
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
3. add CSV export of survey responses — DONE, see Current State above
4. add a better report history view for `AiReport`
5. fix the multiple-choice `option_list` re-render bug — see Current State above
6. AI question enhancement with suggestions — DONE, see Current State above
7. async AI report generation with live UI updates — DONE, see Current State above

Pick 2, 4, or 5 next. Run `bin/rails test` and `bin/rubocop` before starting to confirm the repo is still green.

## Example Output Expectations
When you continue, do not give generic advice. Actually make the change, verify it, and then report:

- what changed
- what was verified
- what the next logical step is

## Tone
Keep the project practical, polished, and portfolio-ready. This should feel like a real internal survey tool, not a demo toy.
