# Tasks: How to Work With Me - Employee Questionnaire & Profile App

**Feature Branch**: `001-an-app-which`
**Input**: Design documents from `/specs/001-an-app-which/`
**Prerequisites**: plan.md, spec.md, research.md, data-model.md, contracts/routes.md

**Tests**: Following Constitution Principle III (Test-First Development MANDATORY), all tasks include TDD workflow with tests written FIRST.

**Organization**: Tasks are grouped by user story to enable independent implementation and testing.

## Format: `[ID] [P?] [Story] Description`
- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: User story this task belongs to (Setup, Foundation, US1, US2, US3, Polish)
- **File paths**: Rails conventions - `app/`, `test/`, `db/migrate/`

---

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Project initialization and PostgreSQL configuration

- [X] T001 [Setup] Add PostgreSQL gem to Gemfile: `gem 'pg', '~> 1.1'` for production
- [X] T002 [Setup] Update `config/database.yml` to use PostgreSQL for development and test per research.md
- [X] T003 [Setup] Run `bundle install` to install PostgreSQL adapter
- [X] T004 [Setup] Create databases with `rails db:create`
- [X] T005 [P] [Setup] Create `.env` file with DATABASE_USERNAME, DATABASE_PASSWORD, DATABASE_HOST per quickstart.md

**Checkpoint**: Database configured and ready for migrations

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Core data models and migrations that ALL user stories depend on

**⚠️ CRITICAL**: No user story work can begin until this phase is complete

### Database Schema Setup

- [X] T006 [Foundation] Generate Organization model: `rails g model Organization name:string unique_token:string:uniq`
- [X] T007 [Foundation] Edit organization migration to add NOT NULL constraints, `has_secure_token` setup
- [X] T008 [Foundation] Generate Questionnaire model: `rails g model Questionnaire organization:references title:string description:text unique_token:string:uniq locked_at:datetime active:boolean`
- [X] T009 [Foundation] Edit questionnaire migration to add NOT NULL constraints, defaults, indexes
- [X] T010 [Foundation] Generate Category model: `rails g model Category questionnaire:references name:string position:integer`
- [X] T011 [Foundation] Edit category migration to add NOT NULL constraints, composite unique index on (questionnaire_id, name)
- [X] T012 [Foundation] Generate Question model: `rails g model Question category:references question_type:string text:text position:integer required:boolean settings:jsonb`
- [X] T013 [Foundation] Edit question migration to add NOT NULL constraints, defaults, composite index on (category_id, position)
- [X] T014 [Foundation] Generate QuestionOption model: `rails g model QuestionOption question:references text:string position:integer`
- [X] T015 [Foundation] Edit question_option migration to add NOT NULL constraints, composite index on (question_id, position)
- [X] T016 [Foundation] Generate Employee model: `rails g model Employee organization:references name:string email:string`
- [X] T017 [Foundation] Edit employee migration to add NOT NULL constraint on name
- [X] T018 [Foundation] Generate Response model: `rails g model Response questionnaire:references employee:references unique_token:string:uniq status:string submitted_at:datetime`
- [X] T019 [Foundation] Edit response migration to add composite indexes: (employee_id, questionnaire_id, submitted_at), (questionnaire_id, submitted_at), (questionnaire_id, status)
- [X] T020 [Foundation] Generate Answer model: `rails g model Answer response:references question:references text_value:text selected_option_id:integer boolean_value:boolean`
- [X] T021 [Foundation] Add `selected_option_ids` integer array column to answers table in new migration with GIN index
- [X] T022 [Foundation] Edit answer migration to add composite unique index on (response_id, question_id)
- [X] T023 [Foundation] Generate Profile model: `rails g model Profile response:references unique_token:string:uniq viewed_count:integer`
- [X] T024 [Foundation] Edit profile migration to add default value for viewed_count, unique constraint on response_id
- [X] T025 [Foundation] Run `rails db:migrate` to execute all migrations
- [X] T026 [Foundation] Verify schema with `rails db:migrate:status`

### Core Model Implementations

- [X] T027 [P] [Foundation] Write failing test for Organization model in `test/models/organization_test.rb` (validations, has_secure_token)
- [X] T028 [Foundation] Implement Organization model in `app/models/organization.rb`: validations, has_secure_token, associations
- [X] T029 [Foundation] Run test, verify it passes: `rails test test/models/organization_test.rb`
- [X] T030 [P] [Foundation] Write failing test for Questionnaire model in `test/models/questionnaire_test.rb` (validations, has_secure_token, scopes)
- [X] T031 [Foundation] Implement Questionnaire model in `app/models/questionnaire.rb`: validations, has_secure_token, associations, scopes (active, locked, unlocked)
- [X] T032 [Foundation] Run test, verify it passes: `rails test test/models/questionnaire_test.rb`
- [X] T033 [P] [Foundation] Write failing test for Category model in `test/models/category_test.rb` (validations, unique name per questionnaire)
- [X] T034 [Foundation] Implement Category model in `app/models/category.rb`: validations, associations, uniqueness validation
- [X] T035 [Foundation] Run test, verify it passes: `rails test test/models/category_test.rb`
- [X] T036 [P] [Foundation] Write failing test for Question model in `test/models/question_test.rb` (validations, question_type enum, choice questions need options)
- [X] T037 [Foundation] Implement Question model in `app/models/question.rb`: validations, associations, enum for question_type, custom validation for options
- [X] T038 [Foundation] Run test, verify it passes: `rails test test/models/question_test.rb`
- [X] T039 [P] [Foundation] Write failing test for QuestionOption model in `test/models/question_option_test.rb`
- [X] T040 [Foundation] Implement QuestionOption model in `app/models/question_option.rb`: validations, associations
- [X] T041 [Foundation] Run test, verify it passes: `rails test test/models/question_option_test.rb`
- [X] T042 [P] [Foundation] Write failing test for Employee model in `test/models/employee_test.rb`
- [X] T043 [Foundation] Implement Employee model in `app/models/employee.rb`: validations, associations
- [X] T044 [Foundation] Run test, verify it passes: `rails test test/models/employee_test.rb`
- [X] T045 [P] [Foundation] Write failing test for Response model in `test/models/response_test.rb` (status enum, scopes, versioning queries)
- [X] T046 [Foundation] Implement Response model in `app/models/response.rb`: validations, has_secure_token, enum for status, scopes (draft, submitted, most_recent_first), submit! method
- [X] T047 [Foundation] Run test, verify it passes: `rails test test/models/response_test.rb`
- [X] T048 [P] [Foundation] Write failing test for Answer model in `test/models/answer_test.rb` (polymorphic storage, validations per question type)
- [X] T049 [Foundation] Implement Answer model in `app/models/answer.rb`: validations, associations, custom validation for answer_matches_question_type, selected_options_exist
- [X] T050 [Foundation] Run test, verify it passes: `rails test test/models/answer_test.rb`
- [X] T051 [P] [Foundation] Write failing test for Profile model in `test/models/profile_test.rb`
- [X] T052 [Foundation] Implement Profile model in `app/models/profile.rb`: validations, has_secure_token, associations, scopes
- [X] T053 [Foundation] Run test, verify it passes: `rails test test/models/profile_test.rb`

**Checkpoint**: Foundation ready - all core models tested and working. User story implementation can now begin.

---

## Phase 3: User Story 1 - Employee Creates and Shares Profile (Priority: P1) 🎯 MVP

**Goal**: Enable employees to fill out a questionnaire and generate a shareable profile link

**Independent Test**: Provide a pre-configured questionnaire link → employee answers all questions → receives shareable profile link → profile displays correctly

### System Tests for User Story 1

**NOTE: Write these tests FIRST, ensure they FAIL before implementation**

- [ ] T054 [US1] Write failing system test for employee questionnaire flow in `test/system/employee_completes_questionnaire_test.rb`:
  - Employee opens questionnaire link
  - Sees all categories and questions
  - Answers text, multiple choice, and yes/no questions
  - Submits questionnaire
  - Receives shareable profile link
- [ ] T055 [US1] Write failing system test for profile viewing in `test/system/profile_viewing_test.rb`:
  - Colleague opens profile link
  - Sees employee name
  - Sees all answers organized by category
  - Sees 404 for invalid profile link

### Routes and Controllers for User Story 1

- [X] T056 [US1] Add routes to `config/routes.rb`:
  - `GET /questionnaires/:unique_token` (landing page)
  - `POST /questionnaires/:unique_token/start` (create draft response)
  - `GET /responses/:unique_token/edit` (questionnaire form)
  - `PATCH /responses/:unique_token` (autosave draft)
  - `POST /responses/:unique_token/submit` (final submission)
  - `GET /profiles/:unique_token` (view profile)
- [X] T057 [P] [US1] Generate Questionnaires controller: `rails g controller Questionnaires show start`
- [X] T058 [US1] Write failing controller test for `QuestionnairesController#show` in `test/controllers/questionnaires_controller_test.rb`
- [X] T059 [US1] Implement `QuestionnairesController#show` in `app/controllers/questionnaires_controller.rb`: find questionnaire by token, render landing page
- [X] T060 [US1] Run controller test, verify it passes: `rails test test/controllers/questionnaires_controller_test.rb`
- [X] T061 [US1] Write failing controller test for `QuestionnairesController#start`
- [X] T062 [US1] Implement `QuestionnairesController#start`: create employee, create draft response, redirect to response edit
- [X] T063 [US1] Run controller test, verify it passes
- [X] T064 [P] [US1] Generate Responses controller: `rails g controller Responses edit update submit`
- [X] T065 [US1] Write failing controller test for `ResponsesController#edit` in `test/controllers/responses_controller_test.rb`
- [X] T066 [US1] Implement `ResponsesController#edit`: find response by token, eager load questionnaire/categories/questions/options, render form
- [X] T067 [US1] Run controller test, verify it passes
- [X] T068 [US1] Write failing controller test for `ResponsesController#update` (autosave)
- [X] T069 [US1] Implement `ResponsesController#update`: accept nested answers_attributes, update response, return Turbo Stream with save status
- [X] T070 [US1] Run controller test, verify it passes

### Service Objects for User Story 1

- [X] T071 [US1] Create service directory: `mkdir -p app/services/responses`
- [X] T072 [US1] Write failing test for `Responses::SubmitFinal` service in `test/services/responses/submit_final_test.rb`
- [X] T073 [US1] Implement `Responses::SubmitFinal` service in `app/services/responses/submit_final.rb`:
  - Validate all required questions answered
  - Update response status to submitted
  - Set submitted_at timestamp
  - Lock questionnaire if first submission
  - Generate profile with unique token
  - Return success/failure result
- [X] T074 [US1] Run service test, verify it passes: `rails test test/services/responses/submit_final_test.rb`
- [X] T075 [US1] Write failing controller test for `ResponsesController#submit` using SubmitFinal service
- [X] T076 [US1] Implement `ResponsesController#submit`: call Responses::SubmitFinal, redirect to profile on success
- [X] T077 [US1] Run controller test, verify it passes
- [X] T078 [P] [US1] Create service directory: `mkdir -p app/services/profiles`
- [ ] T079 [US1] Write failing test for Profile generation in `test/services/profiles/generate_shareable_link_test.rb`
- [ ] T080 [US1] Implement `Profiles::GenerateShareableLink` service in `app/services/profiles/generate_shareable_link.rb` (if needed separately from SubmitFinal)
- [ ] T081 [US1] Run service test, verify it passes
- [X] T082 [P] [US1] Generate Profiles controller: `rails g controller Profiles show`
- [X] T083 [US1] Write failing controller test for `ProfilesController#show` in `test/controllers/profiles_controller_test.rb`
- [X] T084 [US1] Implement `ProfilesController#show`: find profile by token, eager load response/answers/questions/categories, render 404 if not found
- [X] T085 [US1] Run controller test, verify it passes

### Views for User Story 1

- [X] T086 [P] [US1] Create questionnaire landing page view in `app/views/questionnaires/show.html.erb`:
  - Questionnaire title and description
  - Form to enter employee name
  - "Start Questionnaire" button
  - DaisyUI components: card, form-control, btn-primary
- [X] T087 [P] [US1] Create questionnaire form view in `app/views/responses/edit.html.erb`:
  - Form with all categories and questions
  - Dynamic question rendering based on type (text, single_choice, multiple_choice, yes_no)
  - Autosave status indicator
  - Submit button with Turbo confirm
  - Turbo Frame wrapping form
  - DaisyUI components: form-control, textarea, radio, checkbox, btn-primary
- [X] T088 [P] [US1] Create autosave status partial in `app/views/responses/_autosave_status.html.erb`:
  - "Saving..." with loading spinner
  - "✓ Saved" with success styling
  - "Error saving" with error styling
  - DaisyUI components: loading-spinner, text-success, text-error
- [X] T089 [P] [US1] Create profile view in `app/views/profiles/show.html.erb`:
  - Employee name as header
  - Categories as section headers
  - Questions and answers organized by category
  - DaisyUI components: card, card-title, card-body

### JavaScript (Stimulus Controllers) for User Story 1

- [X] T090 [US1] Generate Stimulus autosave controller: `rails g stimulus autosave`
- [X] T091 [US1] Implement autosave controller in `app/javascript/controllers/autosave_controller.js`:
  - Debounce save to 2 seconds after typing stops
  - Immediate save on blur
  - Show "Saving..." status
  - Submit form via Turbo
  - Handle response and update status
- [ ] T092 [US1] Test autosave controller manually: type in field, verify "Saving..." → "Saved" after 2s

### Integration for User Story 1

- [X] T093 [US1] Add nested attributes support to Response model for answers: `accepts_nested_attributes_for :answers`
- [X] T094 [US1] Add strong parameters for nested answers in ResponsesController
- [ ] T095 [US1] Test draft save/restore: start questionnaire, answer questions, leave, return to same link, verify answers restored
- [ ] T096 [US1] Run full system test: `rails test:system test/system/employee_completes_questionnaire_test.rb`
- [ ] T097 [US1] Run full system test: `rails test:system test/system/profile_viewing_test.rb`
- [ ] T098 [US1] Fix any failing tests
- [ ] T099 [US1] Run all tests for User Story 1: `rails test`

**Checkpoint**: User Story 1 (MVP) is complete and independently testable. Employee can fill questionnaire and generate shareable profile.

---

## Phase 4: User Story 2 - Employer Configures Organization Questionnaire (Priority: P2)

**Goal**: Enable employers to create organizations and configure questionnaires with categories and questions

**Independent Test**: Create organization → add categories → add questions of each type → generate employee link → verify configuration persists

### System Tests for User Story 2

**NOTE: Write these tests FIRST, ensure they FAIL before implementation**

- [ ] T100 [US2] Write failing system test for organization creation in `test/system/employer_creates_organization_test.rb`:
  - Employer creates organization
  - Organization dashboard loads
  - Employer creates questionnaire
- [ ] T101 [US2] Write failing system test for questionnaire configuration in `test/system/employer_configures_questionnaire_test.rb`:
  - Employer creates categories
  - Employer adds text, single_choice, multiple_choice, yes_no questions
  - Employer reorders categories and questions
  - Configuration persists
  - Employee link is generated

### Routes and Controllers for User Story 2

- [ ] T102 [US2] Add routes to `config/routes.rb`:
  - `POST /organizations` (create organization)
  - `GET /organizations/:unique_token` (dashboard)
  - `POST /organizations/:org_token/questionnaires` (create questionnaire)
  - `GET /questionnaires/:unique_token/edit` (configure)
  - `POST /questionnaires/:unique_token/generate_link` (generate employee link)
  - `POST /questionnaires/:quest_token/categories` (create category)
  - `PATCH /categories/:id` (update category)
  - `DELETE /categories/:id` (delete category)
  - `POST /categories/:category_id/questions` (create question)
  - `PATCH /questions/:id` (update question)
  - `DELETE /questions/:id` (delete question)
- [ ] T103 [P] [US2] Generate Organizations controller: `rails g controller Organizations create show`
- [ ] T104 [US2] Write failing controller test for `OrganizationsController#create` in `test/controllers/organizations_controller_test.rb`
- [ ] T105 [US2] Implement `OrganizationsController#create`: create organization, redirect to dashboard
- [ ] T106 [US2] Run controller test, verify it passes
- [ ] T107 [US2] Write failing controller test for `OrganizationsController#show` (dashboard)
- [ ] T108 [US2] Implement `OrganizationsController#show`: find organization by token, load questionnaires, render dashboard
- [ ] T109 [US2] Run controller test, verify it passes
- [ ] T110 [US2] Write failing controller test for `QuestionnairesController#create` in `test/controllers/questionnaires_controller_test.rb`
- [ ] T111 [US2] Implement `QuestionnairesController#create`: create questionnaire for organization, redirect to edit
- [ ] T112 [US2] Run controller test, verify it passes
- [ ] T113 [US2] Write failing controller test for `QuestionnairesController#edit`
- [ ] T114 [US2] Implement `QuestionnairesController#edit`: find questionnaire, eager load categories/questions/options, check if locked, render configuration UI
- [ ] T115 [US2] Run controller test, verify it passes
- [ ] T116 [US2] Write failing controller test for `QuestionnairesController#generate_link`
- [ ] T117 [US2] Implement `QuestionnairesController#generate_link`: return Turbo Stream with questionnaire link display
- [ ] T118 [US2] Run controller test, verify it passes
- [ ] T119 [P] [US2] Generate Categories controller: `rails g controller Categories create update destroy`
- [ ] T120 [US2] Write failing controller test for `CategoriesController#create` in `test/controllers/categories_controller_test.rb`
- [ ] T121 [US2] Implement `CategoriesController#create`: check questionnaire not locked, create category, return Turbo Stream append
- [ ] T122 [US2] Run controller test, verify it passes
- [ ] T123 [US2] Write failing controller test for `CategoriesController#update`
- [ ] T124 [US2] Implement `CategoriesController#update`: check questionnaire not locked, update category, return Turbo Stream replace
- [ ] T125 [US2] Run controller test, verify it passes
- [ ] T126 [US2] Write failing controller test for `CategoriesController#destroy`
- [ ] T127 [US2] Implement `CategoriesController#destroy`: check questionnaire not locked, destroy category, return Turbo Stream remove
- [ ] T128 [US2] Run controller test, verify it passes
- [ ] T129 [P] [US2] Generate Questions controller: `rails g controller Questions create update destroy`
- [ ] T130 [US2] Write failing controller test for `QuestionsController#create` in `test/controllers/questions_controller_test.rb`
- [ ] T131 [US2] Implement `QuestionsController#create`: check questionnaire not locked, create question with nested options, return Turbo Stream append
- [ ] T132 [US2] Run controller test, verify it passes
- [ ] T133 [US2] Write failing controller test for `QuestionsController#update`
- [ ] T134 [US2] Implement `QuestionsController#update`: check questionnaire not locked, update question and options, return Turbo Stream replace
- [ ] T135 [US2] Run controller test, verify it passes
- [ ] T136 [US2] Write failing controller test for `QuestionsController#destroy`
- [ ] T137 [US2] Implement `QuestionsController#destroy`: check questionnaire not locked, destroy question, return Turbo Stream remove
- [ ] T138 [US2] Run controller test, verify it passes

### Service Objects for User Story 2

- [ ] T139 [US2] Create service directory: `mkdir -p app/services/questionnaires`
- [ ] T140 [US2] Write failing test for `Questionnaires::LockConfiguration` service in `test/services/questionnaires/lock_configuration_test.rb`
- [ ] T141 [US2] Implement `Questionnaires::LockConfiguration` service in `app/services/questionnaires/lock_configuration.rb`:
  - Check if questionnaire has any submitted responses
  - If yes, set locked_at timestamp
  - Called automatically during Responses::SubmitFinal
  - Return success/failure result
- [ ] T142 [US2] Run service test, verify it passes
- [ ] T143 [US2] Integrate LockConfiguration service into Responses::SubmitFinal (update T073)
- [ ] T144 [US2] Test questionnaire locking: submit first response, verify questionnaire locked, attempt to edit category, verify 403 error

### Views for User Story 2

- [ ] T145 [P] [US2] Create organization creation form view in `app/views/organizations/new.html.erb`:
  - Form to enter organization name
  - "Create Organization" button
  - DaisyUI components: form-control, input, btn-primary
- [ ] T146 [P] [US2] Create organization dashboard view in `app/views/organizations/show.html.erb`:
  - Organization name
  - List of questionnaires
  - "Create Questionnaire" button
  - DaisyUI components: card, btn-primary
- [ ] T147 [P] [US2] Create questionnaire configuration view in `app/views/questionnaires/edit.html.erb`:
  - Questionnaire title and description
  - List of categories (with add/edit/delete buttons)
  - List of questions per category (with add/edit/delete buttons)
  - "Generate Employee Link" button
  - Employee link display
  - Locked UI indicator if questionnaire is locked
  - Turbo Frame: #questionnaire_configuration
  - DaisyUI components: card, btn-primary, btn-error, alert
- [ ] T148 [P] [US2] Create category form partial in `app/views/categories/_form.html.erb`:
  - Name input
  - Position input (optional)
  - DaisyUI components: form-control, input
- [ ] T149 [P] [US2] Create category card partial in `app/views/categories/_category.html.erb`:
  - Category name
  - Edit/Delete buttons (disabled if locked)
  - List of questions
  - DaisyUI components: card, btn-sm, btn-ghost
- [ ] T150 [P] [US2] Create question form partial in `app/views/questions/_form.html.erb`:
  - Question text input
  - Question type select (text, single_choice, multiple_choice, yes_no)
  - Dynamic options fields for choice types (Stimulus controller)
  - Required checkbox
  - DaisyUI components: form-control, textarea, select, checkbox
- [ ] T151 [P] [US2] Create question card partial in `app/views/questions/_question.html.erb`:
  - Question text
  - Question type badge
  - Options display (for choice types)
  - Edit/Delete buttons (disabled if locked)
  - DaisyUI components: card, badge, btn-sm

### JavaScript (Stimulus Controllers) for User Story 2

- [ ] T152 [US2] Generate Stimulus question_type controller: `rails g stimulus question_type`
- [ ] T153 [US2] Implement question_type controller in `app/javascript/controllers/question_type_controller.js`:
  - Show/hide options fields based on question type selection
  - Add/remove option fields dynamically
  - Validate minimum 2 options for choice types
- [ ] T154 [US2] Test question_type controller manually: select multiple_choice, verify options fields appear

### Integration for User Story 2

- [ ] T155 [US2] Add nested attributes support to Question model for question_options: `accepts_nested_attributes_for :question_options, allow_destroy: true`
- [ ] T156 [US2] Add strong parameters for nested question_options in QuestionsController
- [ ] T157 [US2] Add before_action to check questionnaire locked status in Categories and Questions controllers
- [ ] T158 [US2] Implement questionnaire locking logic: add `locked?` method to Questionnaire model, check in controllers
- [ ] T159 [US2] Run full system test: `rails test:system test/system/employer_creates_organization_test.rb`
- [ ] T160 [US2] Run full system test: `rails test:system test/system/employer_configures_questionnaire_test.rb`
- [ ] T161 [US2] Fix any failing tests
- [ ] T162 [US2] Run all tests for User Story 2: `rails test`
- [ ] T163 [US2] Integration test: Create organization → configure questionnaire → generate employee link → employee fills questionnaire (US1) → verify questionnaire locked → attempt to edit category → verify 403

**Checkpoint**: User Story 2 is complete. Employers can configure questionnaires. US1 and US2 work together (employer configures, employee fills).

---

## Phase 5: User Story 3 - Employer Views Employee Responses (Priority: P3)

**Goal**: Enable employers to view all employee responses in a table format on their dashboard

**Independent Test**: Multiple employees complete questionnaire → employer views dashboard → sees table with employees as rows, questions as columns, grouped by category

### System Tests for User Story 3

**NOTE: Write these tests FIRST, ensure they FAIL before implementation**

- [ ] T164 [US3] Write failing system test for employer dashboard in `test/system/employer_views_responses_test.rb`:
  - Create questionnaire with 3 categories, 5 questions
  - 3 employees fill out questionnaire (via US1 flow)
  - Employer views responses table
  - Verifies table has 3 rows (employees) and 5 columns (questions)
  - Verifies questions are grouped/labeled by category
  - Verifies correct answers displayed in cells
  - Verifies most recent submission shown when employee submits multiple times

### Routes and Controllers for User Story 3

- [ ] T165 [US3] Add route to `config/routes.rb`:
  - `GET /questionnaires/:unique_token/responses` (responses table)
- [ ] T166 [US3] Write failing controller test for `QuestionnairesController#responses` in `test/controllers/questionnaires_controller_test.rb`
- [ ] T167 [US3] Implement `QuestionnairesController#responses`:
  - Find questionnaire by token
  - Eager load categories → questions → responses → answers → employees (prevent N+1)
  - Get most recent response per employee using DISTINCT ON or group_by
  - Render responses table view
- [ ] T168 [US3] Run controller test, verify it passes
- [ ] T169 [US3] Test N+1 prevention: Use Bullet gem or manual query counting to verify no N+1 queries

### Views for User Story 3

- [ ] T170 [P] [US3] Create responses table view in `app/views/questionnaires/responses.html.erb`:
  - Table with employees as rows, questions as columns
  - Table header: Category name | Question text
  - Table body: Employee name | Answers
  - Turbo Frame: #responses_table
  - DaisyUI components: table, table-zebra, overflow-x-auto
- [ ] T171 [P] [US3] Create response row partial in `app/views/responses/_response_row.html.erb`:
  - Employee name in first column
  - Answer cells for each question
  - Handle different answer types (text, selected option(s), boolean)
  - DaisyUI components: table row, table cell

### Helpers for User Story 3

- [ ] T172 [US3] Create QuestionnairesHelper in `app/helpers/questionnaires_helper.rb`:
  - Method to format answer display based on question type
  - Method to group questions by category for table header
- [ ] T173 [US3] Write failing test for helpers in `test/helpers/questionnaires_helper_test.rb`
- [ ] T174 [US3] Implement helper methods
- [ ] T175 [US3] Run helper test, verify it passes

### Real-Time Updates (Turbo Streams) for User Story 3

- [ ] T176 [US3] Add Turbo Stream broadcast to Responses::SubmitFinal service:
  - After successful submission, broadcast to "questionnaire_#{questionnaire.id}_responses" channel
  - Append or update response row in employer dashboard table
  - Use `Turbo::StreamsChannel.broadcast_append_later_to` or similar
- [ ] T177 [US3] Add Turbo Stream subscription to responses table view:
  - `<%= turbo_stream_from "questionnaire_#{@questionnaire.id}_responses" %>`
  - Test: open employer dashboard, have employee submit (in different browser/tab), verify table updates automatically

### Integration for User Story 3

- [ ] T178 [US3] Add link to responses table from questionnaire edit page (US2)
- [ ] T179 [US3] Add link to responses table from organization dashboard (US2)
- [ ] T180 [US3] Test response versioning: employee submits multiple times, verify dashboard shows most recent submission only
- [ ] T181 [US3] Run full system test: `rails test:system test/system/employer_views_responses_test.rb`
- [ ] T182 [US3] Fix any failing tests
- [ ] T183 [US3] Run all tests for User Story 3: `rails test`
- [ ] T184 [US3] Integration test across all stories:
  - Employer creates organization (US2)
  - Employer configures questionnaire (US2)
  - Generate employee link (US2)
  - Employee 1 fills questionnaire (US1)
  - Employee 2 fills questionnaire (US1)
  - Employer views responses table (US3)
  - Verify complete end-to-end flow

**Checkpoint**: All 3 user stories are complete and working together. Full application functionality delivered.

---

## Phase 6: Polish & Cross-Cutting Concerns

**Purpose**: Refinements that affect multiple user stories

### Edge Cases and Error Handling

- [ ] T185 [P] [Polish] Implement 404 error page for invalid tokens in `app/views/errors/404.html.erb`
- [ ] T186 [Polish] Add custom error handling in ApplicationController for ActiveRecord::RecordNotFound
- [ ] T187 [Polish] Test 404 behavior: access invalid profile link, verify 404 page displayed
- [ ] T188 [Polish] Add validation error display across all forms using DaisyUI alert components
- [ ] T189 [Polish] Test validation errors: submit form with missing required field, verify error displayed

### Performance Optimization

- [ ] T190 [Polish] Review all controller actions for N+1 queries, add `includes` where needed
- [ ] T191 [Polish] Add database indexes review: verify all foreign keys indexed, composite indexes in place
- [ ] T192 [Polish] Test performance: create questionnaire with 20 questions, have 50 employees respond, verify dashboard loads in <3s
- [ ] T193 [Polish] Add pagination to responses table if exceeds 100 employees (optional future enhancement)

### User Experience Improvements

- [ ] T194 [P] [Polish] Add flash messages for user actions (organization created, questionnaire saved, response submitted)
- [ ] T195 [Polish] Add loading indicators for form submissions using DaisyUI loading spinners
- [ ] T196 [Polish] Add Turbo confirm dialogs for destructive actions (delete category, delete question, submit questionnaire)
- [ ] T197 [Polish] Test UX flows: verify smooth transitions, appropriate feedback messages

### Documentation and Deployment Preparation

- [ ] T198 [P] [Polish] Verify all routes are RESTful and follow Rails conventions
- [ ] T199 [P] [Polish] Run Rubocop code style check: `bundle exec rubocop`
- [ ] T200 [Polish] Fix Rubocop offenses or generate .rubocop_todo.yml
- [ ] T201 [P] [Polish] Run Brakeman security scan: `bundle exec brakeman`
- [ ] T202 [Polish] Address any Brakeman security warnings
- [ ] T203 [P] [Polish] Update README with setup instructions from quickstart.md
- [ ] T204 [Polish] Run quickstart.md validation: follow setup instructions from scratch, verify app works
- [ ] T205 [Polish] Run full test suite: `rails test` and `rails test:system`
- [ ] T206 [Polish] Verify all tests pass with no warnings

### Optional Enhancements (Future)

- [ ] T207 [Polish] Add question reordering UI with drag-and-drop (Stimulus controller)
- [ ] T208 [Polish] Add category reordering UI with drag-and-drop (Stimulus controller)
- [ ] T209 [Polish] Add response export to CSV feature for employer dashboard
- [ ] T210 [Polish] Add profile link expiration dates (add expires_at column to profiles)
- [ ] T211 [Polish] Add email notifications when employee completes questionnaire

**Checkpoint**: Application is production-ready with all edge cases handled, performance optimized, and code quality validated.

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: No dependencies - can start immediately
- **Foundational (Phase 2)**: Depends on Setup completion - **BLOCKS all user stories**
- **User Stories (Phase 3-5)**: All depend on Foundational phase completion
  - User Story 1 (Phase 3) can proceed independently
  - User Story 2 (Phase 4) can proceed independently (provides configuration for US1)
  - User Story 3 (Phase 5) depends on US1 completing (needs responses to display)
- **Polish (Phase 6)**: Depends on desired user stories being complete

### User Story Dependencies

- **User Story 1 (P1)**: Can start after Foundational phase - No dependencies on other stories (can use fixtures for testing)
- **User Story 2 (P2)**: Can start after Foundational phase - Provides configuration that US1 uses, but US1 can be tested with fixtures
- **User Story 3 (P3)**: Depends on US1 completing (needs responses to display) - Integrates with US2 for dashboard access

### Within Each User Story

- System tests MUST be written and FAIL before implementation
- Model tests before model implementation
- Controller tests before controller implementation
- Service tests before service implementation
- Views can be developed in parallel with controllers
- JavaScript controllers can be developed in parallel with views
- Integration tests run after all components complete

### Parallel Opportunities

- **Setup (Phase 1)**: T001-T005 can all run in parallel (different files)
- **Foundational (Phase 2)**:
  - All model tests (T027, T030, T033, T036, T039, T042, T045, T048, T051) can run in parallel
  - Migrations must run sequentially (T006-T026)
  - Model implementations run after their tests pass
- **User Story 1 (Phase 3)**:
  - Controller generation (T057, T064, T082) can run in parallel
  - View creation (T086-T089) can run in parallel
  - Service directories (T071, T078) can run in parallel
- **User Story 2 (Phase 4)**:
  - Controller generation (T103, T119, T129) can run in parallel
  - View creation (T145-T151) can run in parallel
- **User Story 3 (Phase 5)**:
  - Views (T170, T171) can run in parallel with helpers development
- **Polish (Phase 6)**:
  - Error pages (T185), documentation (T198, T199, T201, T203) can run in parallel

---

## Parallel Example: User Story 1

```bash
# After Foundational phase completes, launch User Story 1 tasks in parallel:

# Generate all controllers at once (different files):
rails g controller Questionnaires show start
rails g controller Responses edit update submit
rails g controller Profiles show

# Create all views in parallel (different files):
# Create app/views/questionnaires/show.html.erb
# Create app/views/responses/edit.html.erb
# Create app/views/responses/_autosave_status.html.erb
# Create app/views/profiles/show.html.erb

# Create service directories in parallel:
mkdir -p app/services/responses
mkdir -p app/services/profiles
```

---

## Parallel Example: Across User Stories (If Team Has Capacity)

```bash
# After Foundational phase completes:

# Developer A: Work on User Story 1 (T054-T099)
# Developer B: Work on User Story 2 (T100-T163) in parallel
# Developer C: Can work on shared views/components

# All three can proceed independently after Foundation is complete
```

---

## Implementation Strategy

### MVP First (User Story 1 Only)

1. **Phase 1**: Setup (T001-T005) - ~1 hour
2. **Phase 2**: Foundational (T006-T053) - ~8-12 hours (TDD with all model tests)
3. **Phase 3**: User Story 1 (T054-T099) - ~8-12 hours (TDD with system and controller tests)
4. **STOP and VALIDATE**: Test User Story 1 end-to-end independently using fixtures
5. Deploy/demo MVP if ready

**MVP Deliverable**: Employees can fill out a pre-configured questionnaire and generate shareable profiles (US1 with fixture data for testing).

### Incremental Delivery

1. **Phase 1 + 2**: Setup + Foundation → ~12 hours → Foundation ready
2. **Phase 3**: User Story 1 → ~12 hours → Test independently → **Deploy MVP!**
3. **Phase 4**: User Story 2 → ~16 hours → Test independently → Deploy with configuration UI
4. **Phase 5**: User Story 3 → ~8 hours → Test independently → Deploy complete solution
5. **Phase 6**: Polish → ~8 hours → Production-ready

**Total Estimated Time**: ~56 hours for complete 3-story implementation with TDD

### Parallel Team Strategy

With 2-3 developers after Foundational phase:

1. **Team**: Complete Setup + Foundational together (~12 hours)
2. **Split work**:
   - Developer A: User Story 1 (T054-T099) - ~12 hours
   - Developer B: User Story 2 (T100-T163) - ~16 hours
   - Developer C: User Story 3 preparation, shared components
3. **Integrate**: Developer A finishes US1, helps with US2/US3 integration
4. **Polish**: Team does final polish together

**Total Team Time**: ~28-32 hours with 2 developers, ~20-24 hours with 3 developers

---

## Notes

- **[P] = Parallelizable**: Different files, no dependencies, can run simultaneously
- **[Story] = User Story mapping**: US1 (Employee), US2 (Employer Config), US3 (Employer Dashboard)
- **TDD Required**: Per Constitution Principle III, ALL tests written FIRST, must FAIL before implementation
- **Each user story independently completable**: Can stop after any phase and have working functionality
- **Verify tests fail**: Before implementing, always confirm test fails (red → green → refactor)
- **Commit frequently**: After each task or logical group passes tests
- **Stop at checkpoints**: Validate story independently before proceeding
- **Constitution compliance**: All tasks follow Rails conventions, Hotwire-first, DaisyUI components, thin controllers with service objects

---

## Task Count Summary

- **Phase 1 (Setup)**: 5 tasks
- **Phase 2 (Foundational)**: 48 tasks (26 migrations/models + 22 tests)
- **Phase 3 (User Story 1 - MVP)**: 46 tasks
- **Phase 4 (User Story 2)**: 64 tasks
- **Phase 5 (User Story 3)**: 21 tasks
- **Phase 6 (Polish)**: 27 tasks

**Total Tasks**: 211 tasks

**Tasks per User Story**:
- US1: 46 tasks (22% of total)
- US2: 64 tasks (30% of total)
- US3: 21 tasks (10% of total)
- Foundation + Setup: 53 tasks (25% of total)
- Polish: 27 tasks (13% of total)

**Parallel Opportunities Identified**: ~60 tasks marked [P] for parallel execution

**Independent Test Criteria**:
- **US1**: Pre-configured questionnaire → employee fills → profile generated → profile viewable
- **US2**: Create org → add categories/questions → generate link → configuration persists
- **US3**: Multiple responses exist → employer views table → correct data displayed

**Suggested MVP Scope**: Phase 1 + Phase 2 + Phase 3 (User Story 1 only) = 99 tasks for fully tested MVP
