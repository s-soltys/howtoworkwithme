# Implementation Plan: How to Work With Me - Employee Questionnaire & Profile App

**Branch**: `001-an-app-which` | **Date**: 2025-10-08 | **Spec**: [spec.md](./spec.md)
**Input**: Feature specification from `/specs/001-an-app-which/spec.md`

**Note**: This template is filled in by the `/speckit.plan` command. See `.specify/templates/commands/plan.md` for the execution workflow.

## Summary

An application enabling new employees to complete customizable questionnaires and generate shareable "How to work with me" profiles. Employers configure organizations with categorized questions (free text, multiple choice, yes/no), employees fill questionnaires via unique links, and results are shareable via profile links plus viewable in an employer dashboard. The data model centers around a Questionnaire model with hierarchical relationships: Organization → Questionnaire → Category → Question, with Employee → Response → Profile for answer tracking.

## Technical Context

**Language/Version**: Ruby 3.3+ / Rails 8.0.3
**Primary Dependencies**: Rails 8.0.3, Turbo Rails, Stimulus, Tailwind CSS 4.3 with DaisyUI, SQLite3 (development), Propshaft (asset pipeline)
**Storage**: SQLite3 (development/test), PostgreSQL (production - NEEDS CLARIFICATION on deployment target)
**Testing**: Minitest (Rails default), RSpec (NEEDS CLARIFICATION - constitution requires RSpec but Gemfile shows Minitest), Capybara + Selenium WebDriver for system tests
**Target Platform**: Web application (server-rendered HTML with Hotwire)
**Project Type**: Web application (single Rails monolith with traditional MVC structure)
**Performance Goals**: Profile links load in <2s, employer dashboard handles 100 employees without pagination, questionnaire completion in <10 minutes for 20 questions
**Constraints**: <200ms p95 for page loads, support 100 employees per organization, 95% first-time profile generation success rate
**Scale/Scope**: MVP supporting unlimited organizations, 100 employees per org, 5-10 categories per questionnaire, 20-30 questions per questionnaire

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

### Principle I: Rails Convention Over Configuration
**Status**: ✅ PASS
**Assessment**: Feature follows Rails conventions - models will be singular (Organization, Questionnaire, Category, Question, Employee, Response, Profile), controllers plural with Controller suffix, routes plural snake_case, tables plural snake_case. Service objects will be namespaced (e.g., `Questionnaires::GenerateEmployeeLink`).

### Principle II: Thin Controllers, Service Objects for Logic
**Status**: ✅ PASS
**Assessment**: Multi-step operations identified for service objects: questionnaire configuration workflow, profile generation with unique link creation, draft save/restore mechanism, employer dashboard aggregation. Controllers will handle only HTTP concerns.

### Principle III: Test-First Development (MANDATORY)
**Status**: ✅ PASS
**Assessment**: Feature specification includes comprehensive acceptance scenarios that translate directly to system tests. Model validations, associations, and business logic will be tested first. TDD workflow will be enforced during implementation.

### Principle IV: DaisyUI Component Consistency
**Status**: ✅ PASS
**Assessment**: UI requirements map to DaisyUI components: forms (form-control, input, textarea, checkbox for question types), cards (for questionnaire display), tables (table-zebra for employer dashboard), buttons (btn-primary, btn-error), alerts (for validation errors).

### Principle V: Hotwire-First Interactivity
**Status**: ✅ PASS
**Assessment**: Questionnaire form submission, draft autosave, and employer dashboard updates are ideal Turbo Frame/Stream use cases. Dynamic question type rendering (text/multiple choice/yes-no) will use Stimulus controllers. No full page reloads required.

### Principle VI: Database Integrity & Performance
**Status**: ✅ PASS
**Assessment**: Migrations will include foreign key indexes, unique constraints on category names per organization, proper null constraints. N+1 query prevention required for employer dashboard (includes on responses/questions) and profile display (includes on categories/questions/responses).

### Principle VII: Simplicity & YAGNI
**Status**: ✅ PASS
**Assessment**: Implements only explicitly requested MVP features. No authentication/authorization per MVP scope. Service objects only where complexity justified (multi-step workflows). Caching deferred until performance measured.

**GATE RESULT**: ✅ ALL CHECKS PASS - Proceed to Phase 0

## Project Structure

### Documentation (this feature)

```
specs/[###-feature]/
├── plan.md              # This file (/speckit.plan command output)
├── research.md          # Phase 0 output (/speckit.plan command)
├── data-model.md        # Phase 1 output (/speckit.plan command)
├── quickstart.md        # Phase 1 output (/speckit.plan command)
├── contracts/           # Phase 1 output (/speckit.plan command)
└── tasks.md             # Phase 2 output (/speckit.tasks command - NOT created by /speckit.plan)
```

### Source Code (repository root)

```
app/
├── controllers/
│   ├── organizations_controller.rb
│   ├── questionnaires_controller.rb
│   ├── categories_controller.rb
│   ├── questions_controller.rb
│   ├── employees_controller.rb
│   ├── responses_controller.rb
│   └── profiles_controller.rb
├── models/
│   ├── organization.rb
│   ├── questionnaire.rb
│   ├── category.rb
│   ├── question.rb
│   ├── employee.rb
│   ├── response.rb
│   └── profile.rb
├── services/
│   ├── questionnaires/
│   │   ├── generate_employee_link.rb
│   │   └── lock_configuration.rb
│   ├── responses/
│   │   ├── save_draft.rb
│   │   └── submit_final.rb
│   └── profiles/
│       └── generate_shareable_link.rb
├── views/
│   ├── organizations/
│   ├── questionnaires/
│   ├── categories/
│   ├── questions/
│   ├── employees/
│   ├── responses/
│   └── profiles/
├── javascript/
│   └── controllers/
│       ├── questionnaire_controller.js
│       ├── draft_autosave_controller.js
│       └── question_type_controller.js
└── helpers/
    ├── questionnaires_helper.rb
    └── profiles_helper.rb

test/
├── models/
├── controllers/
├── services/
├── system/
│   ├── employer_questionnaire_configuration_test.rb
│   ├── employee_questionnaire_completion_test.rb
│   └── profile_sharing_test.rb
└── fixtures/

db/
└── migrate/
    ├── [timestamp]_create_organizations.rb
    ├── [timestamp]_create_questionnaires.rb
    ├── [timestamp]_create_categories.rb
    ├── [timestamp]_create_questions.rb
    ├── [timestamp]_create_employees.rb
    ├── [timestamp]_create_responses.rb
    └── [timestamp]_create_profiles.rb
```

**Structure Decision**: Standard Rails web application monolith. All feature code lives in `app/` following Rails conventions. Service objects in `app/services/` namespaced by domain (Questionnaires, Responses, Profiles). Hotwire JavaScript controllers in `app/javascript/controllers/` for client-side behavior. Testing follows Rails structure with model, controller, service, and system tests.

## Complexity Tracking

*Fill ONLY if Constitution Check has violations that must be justified*

**No violations** - All design decisions align with constitution principles.

## Post-Design Constitution Re-Check

*GATE: Re-evaluated after Phase 1 design completion*

### Principle I: Rails Convention Over Configuration
**Status**: ✅ PASS
**Assessment**: Data model strictly follows Rails conventions. All models singular CamelCase (Organization, Questionnaire, Category, Question, QuestionOption, Employee, Response, Answer, Profile). Routes use plural snake_case. Service objects namespaced properly.

### Principle II: Thin Controllers, Service Objects for Logic
**Status**: ✅ PASS
**Assessment**: Service objects identified for all complex workflows:
- `Questionnaires::GenerateEmployeeLink` - Link generation logic
- `Questionnaires::LockConfiguration` - Questionnaire locking on first submission
- `Responses::SaveDraft` - Draft save logic with validation
- `Responses::SubmitFinal` - Submission workflow with profile creation
- `Profiles::GenerateShareableLink` - Profile link generation
Controllers handle only HTTP concerns.

### Principle III: Test-First Development (MANDATORY)
**Status**: ✅ PASS
**Assessment**: Implementation plan includes TDD workflow. Quickstart guide documents test-first approach. System tests map directly to acceptance scenarios in spec. Model tests will cover all validations and associations.

### Principle IV: DaisyUI Component Consistency
**Status**: ✅ PASS
**Assessment**: Routes contract specifies DaisyUI components for all UI elements:
- Forms: `form-control`, `label`, `input`, `textarea`, `checkbox`, `radio`
- Buttons: `btn-primary`, `btn-error`, `btn-lg`
- Tables: `table-zebra`, `overflow-x-auto` for employer dashboard
- Alerts: `alert-success`, `alert-error` for validation feedback
- Loading: `loading-spinner` for autosave status

### Principle V: Hotwire-First Interactivity
**Status**: ✅ PASS
**Assessment**: Routes contract specifies Turbo Frames/Streams throughout:
- `#questionnaire_configuration` frame for category/question management
- `#response_form` frame for autosave
- `#responses_table` frame for employer dashboard
- Turbo Streams for append/prepend/replace/remove operations
- Stimulus controllers for autosave debouncing and client-side behavior
- No full page reloads required

### Principle VI: Database Integrity & Performance
**Status**: ✅ PASS
**Assessment**: Data model includes:
- All foreign keys indexed
- Unique constraints on category names per questionnaire, all tokens
- Composite indexes for versioning: `(employee_id, questionnaire_id, submitted_at)`
- GIN index on `selected_option_ids` array for fast queries
- Partial indexes on `status='submitted'` for common queries
- N+1 prevention via eager loading documented in routes contract
- Proper null constraints and defaults specified

### Principle VII: Simplicity & YAGNI
**Status**: ✅ PASS
**Assessment**: Design implements only requested MVP features:
- No authentication/authorization (per spec)
- No PaperTrail (simple timestamp versioning sufficient)
- No caching (premature optimization)
- No background jobs (not needed for MVP scale)
- Service objects only where complexity justified
- Simple PostgreSQL arrays for multiple choice (not junction tables)

**GATE RESULT**: ✅ ALL CHECKS PASS - Design approved, proceed to implementation

## Phase 2 Output

The `/speckit.plan` command completes here. The following artifacts have been generated:

- ✅ `plan.md` - This file (implementation plan)
- ✅ `research.md` - Technical research and decisions
- ✅ `data-model.md` - Complete data model specification
- ✅ `contracts/routes.md` - API/routes contract
- ✅ `quickstart.md` - Development quickstart guide
- ✅ `CLAUDE.md` - Agent context updated

**Next command**: Run `/speckit.tasks` to generate `tasks.md` with dependency-ordered implementation tasks.

**Branch**: `001-an-app-which` (ready for implementation)

**Implementation Ready**: All design artifacts complete. Constitution gates passed. Ready to generate tasks and begin TDD implementation.
