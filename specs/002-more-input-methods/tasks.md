# Tasks: Enhanced Question Input Methods

**Feature Branch**: `002-more-input-methods`
**Input**: Design documents from `/specs/002-more-input-methods/`
**Prerequisites**: plan.md, spec.md, research.md, data-model.md, contracts/, quickstart.md

**Testing Framework**: Minitest (Rails default) with Capybara for system tests
**TDD Required**: Per project constitution, tests must be written FIRST and FAIL before implementation

**Organization**: Tasks are grouped by user story to enable independent implementation and testing of each story.

## Format: `[ID] [P?] [Story] Description`
- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (e.g., US1, US2, US3)
- Include exact file paths in descriptions

---

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Project initialization and dependency installation

- [X] T001 [P] Pin SortableJS via importmap: `bin/importmap pin sortablejs`
- [X] T002 [P] Pin Chart.js via importmap: `bin/importmap pin chart.js`
- [X] T003 [P] Pin chartjs-plugin-dragdata: `bin/importmap pin chartjs-plugin-dragdata`
- [X] T004 Run bundle install to ensure all gems are current

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Core infrastructure that MUST be complete before ANY user story can be implemented

**⚠️ CRITICAL**: No user story work can begin until this phase is complete

### Database Migrations

- [ ] T005 Create migration to add new question types: `rails g migration AddNewQuestionInputTypes` in `db/migrate/`
- [ ] T006 Create migration to add value fields to answers: `rails g migration AddValueFieldsToAnswers numeric_value:integer jsonb_value:jsonb` in `db/migrate/`
- [ ] T007 Run migrations: `rails db:migrate`

### Model Extensions

- [ ] T008 Extend Question model enum with 6 new question types in `app/models/question.rb`
- [ ] T009 Add settings validation methods for all 6 question types in `app/models/question.rb`
- [ ] T010 Extend Answer model with validation methods for all 6 question types in `app/models/answer.rb`
- [ ] T011 Update strong parameters in `app/controllers/responses_controller.rb` to permit `numeric_value` and `jsonb_value` fields

### Service Objects

- [ ] T012 [P] Create Questions::ValidateConfiguration service in `app/services/questions/validate_configuration.rb`
- [ ] T013 [P] Create Responses::SaveAnswer service in `app/services/responses/save_answer.rb`
- [ ] T014 [P] Create Responses::ValidateCharacterSheet service in `app/services/responses/validate_character_sheet.rb`

**Checkpoint**: Foundation ready - user story implementation can now begin in parallel

---

## Phase 3: User Story 1 - Scale-based Preference Collection (Priority: P1) 🎯 MVP

**Goal**: Users can express nuanced opinions on a spectrum using sliders with labeled endpoints

**Independent Test**: Create a question with a labeled scale (e.g., "1=Introvert, 10=Extrovert"), allow user to select a value, verify response is saved with proper labeling

### Tests for User Story 1 (TDD - Write FIRST, ensure they FAIL)

- [ ] T015 [P] [US1] Create model test for slider question settings validation in `test/models/question_test.rb`
- [ ] T016 [P] [US1] Create model test for slider answer value validation in `test/models/answer_test.rb`
- [ ] T017 [P] [US1] Create controller test for creating slider question in `test/controllers/questions_controller_test.rb`
- [ ] T018 [P] [US1] Create controller test for saving slider answer in `test/controllers/responses_controller_test.rb`
- [ ] T019 [US1] Create system test for complete slider input workflow in `test/system/slider_input_test.rb`

### Implementation for User Story 1

- [ ] T020 [P] [US1] Create Stimulus slider controller in `app/javascript/controllers/slider_controller.js`
- [ ] T021 [P] [US1] Create slider question view partial in `app/views/responses/_question_types/_slider.html.erb`
- [ ] T022 [P] [US1] Create slider config form partial for admin in `app/views/questions/_form_fields/_slider_config.html.erb`
- [ ] T023 [US1] Update QuestionsController#create to handle slider question creation in `app/controllers/questions_controller.rb`
- [ ] T024 [US1] Update ResponsesController#update to handle slider answer persistence in `app/controllers/responses_controller.rb`

**Checkpoint**: User Story 1 should be fully functional - test slider input independently

---

## Phase 4: User Story 2 - Engaging Binary Decision Making (Priority: P2)

**Goal**: Users experience fun and intuitive yes/no decisions through swipe gestures and visual feedback

**Independent Test**: Present a yes/no question, enable swipe left/right gestures, show visual feedback (animations, button highlights), verify choice is recorded

### Tests for User Story 2 (TDD - Write FIRST, ensure they FAIL)

- [ ] T025 [P] [US2] Create model test for swipe_yes_no question settings validation in `test/models/question_test.rb`
- [ ] T026 [P] [US2] Create model test for swipe_yes_no answer validation in `test/models/answer_test.rb`
- [ ] T027 [P] [US2] Create controller test for creating swipe_yes_no question in `test/controllers/questions_controller_test.rb`
- [ ] T028 [P] [US2] Create controller test for saving swipe answer in `test/controllers/responses_controller_test.rb`
- [ ] T029 [US2] Create system test for swipe gesture workflow in `test/system/swipe_yes_no_test.rb`

### Implementation for User Story 2

- [ ] T030 [P] [US2] Create Stimulus swipe controller with Pointer Events in `app/javascript/controllers/swipe_controller.js`
- [ ] T031 [P] [US2] Create swipe yes/no view partial in `app/views/responses/_question_types/_swipe_yes_no.html.erb`
- [ ] T032 [P] [US2] Create swipe config form partial for admin in `app/views/questions/_form_fields/_swipe_yes_no_config.html.erb`
- [ ] T033 [P] [US2] Add swipe animation CSS styles in `app/assets/stylesheets/application.tailwind.css`
- [ ] T034 [US2] Update QuestionsController#create to handle swipe_yes_no question creation in `app/controllers/questions_controller.rb`
- [ ] T035 [US2] Update ResponsesController#update to handle swipe answer persistence in `app/controllers/responses_controller.rb`

**Checkpoint**: User Stories 1 AND 2 should both work independently

---

## Phase 5: User Story 3 - Priority-based Card Sorting (Priority: P2)

**Goal**: Users can rank multiple options by importance through drag-and-drop to reveal true priorities

**Independent Test**: Present multiple cards (e.g., 5 work values), allow drag-and-drop reordering from most to least important, verify final ranked order is saved

### Tests for User Story 3 (TDD - Write FIRST, ensure they FAIL)

- [ ] T036 [P] [US3] Create model test for card_sort question settings validation in `test/models/question_test.rb`
- [ ] T037 [P] [US3] Create model test for card_sort answer validation in `test/models/answer_test.rb`
- [ ] T038 [P] [US3] Create controller test for creating card_sort question in `test/controllers/questions_controller_test.rb`
- [ ] T039 [P] [US3] Create controller test for saving card ranking in `test/controllers/responses_controller_test.rb`
- [ ] T040 [US3] Create system test for card sorting workflow in `test/system/card_sorting_test.rb`

### Implementation for User Story 3

- [ ] T041 [P] [US3] Create Stimulus card sort controller with SortableJS in `app/javascript/controllers/card_sort_controller.js`
- [ ] T042 [P] [US3] Create card sort view partial in `app/views/responses/_question_types/_card_sort.html.erb`
- [ ] T043 [P] [US3] Create card sort config form partial for admin in `app/views/questions/_form_fields/_card_sort_config.html.erb`
- [ ] T044 [P] [US3] Add card sorting CSS styles in `app/assets/stylesheets/application.tailwind.css`
- [ ] T045 [US3] Update QuestionsController#create to handle card_sort question creation in `app/controllers/questions_controller.rb`
- [ ] T046 [US3] Update ResponsesController#update to handle card ranking persistence in `app/controllers/responses_controller.rb`

**Checkpoint**: User Stories 1, 2, AND 3 should all work independently

---

## Phase 6: User Story 4 - Temporal Energy/Mood Visualization (Priority: P3)

**Goal**: Users map energy, mood, or engagement levels across different phases or times with visual pattern representation

**Independent Test**: Display a timeline/graph interface (e.g., "your typical work week"), allow users to plot energy levels at different points, save the complete temporal pattern

### Tests for User Story 4 (TDD - Write FIRST, ensure they FAIL)

- [ ] T047 [P] [US4] Create model test for energy_map question settings validation in `test/models/question_test.rb`
- [ ] T048 [P] [US4] Create model test for energy_map answer validation in `test/models/answer_test.rb`
- [ ] T049 [P] [US4] Create controller test for creating energy_map question in `test/controllers/questions_controller_test.rb`
- [ ] T050 [P] [US4] Create controller test for saving energy map data in `test/controllers/responses_controller_test.rb`
- [ ] T051 [US4] Create system test for energy mapping workflow in `test/system/energy_mapping_test.rb`

### Implementation for User Story 4

- [ ] T052 [P] [US4] Create Stimulus energy map controller with Chart.js + dragdata plugin in `app/javascript/controllers/energy_map_controller.js`
- [ ] T053 [P] [US4] Create energy map view partial in `app/views/responses/_question_types/_energy_map.html.erb`
- [ ] T054 [P] [US4] Create energy map config form partial for admin in `app/views/questions/_form_fields/_energy_map_config.html.erb`
- [ ] T055 [US4] Update QuestionsController#create to handle energy_map question creation in `app/controllers/questions_controller.rb`
- [ ] T056 [US4] Update ResponsesController#update to handle energy map persistence in `app/controllers/responses_controller.rb`

**Checkpoint**: User Stories 1-4 should all work independently

---

## Phase 7: User Story 5 - Emoji-based Quick Reactions (Priority: P3)

**Goal**: Users express immediate emotional or intuitive responses to statements through emoji selection

**Independent Test**: Show a statement with emoji options (e.g., "How do you feel about meetings?" with 😍😊😐😕😤), capture selected emoji, save response

### Tests for User Story 5 (TDD - Write FIRST, ensure they FAIL)

- [ ] T057 [P] [US5] Create model test for emoji_reaction question settings validation in `test/models/question_test.rb`
- [ ] T058 [P] [US5] Create model test for emoji_reaction answer validation in `test/models/answer_test.rb`
- [ ] T059 [P] [US5] Create controller test for creating emoji_reaction question in `test/controllers/questions_controller_test.rb`
- [ ] T060 [P] [US5] Create controller test for saving emoji selection in `test/controllers/responses_controller_test.rb`
- [ ] T061 [US5] Create system test for emoji reaction workflow in `test/system/emoji_reactions_test.rb`

### Implementation for User Story 5

- [ ] T062 [P] [US5] Create Stimulus emoji reaction controller in `app/javascript/controllers/emoji_reaction_controller.js`
- [ ] T063 [P] [US5] Create emoji reaction view partial in `app/views/responses/_question_types/_emoji_reaction.html.erb`
- [ ] T064 [P] [US5] Create emoji reaction config form partial for admin in `app/views/questions/_form_fields/_emoji_reaction_config.html.erb`
- [ ] T065 [P] [US5] Add emoji animation CSS styles in `app/assets/stylesheets/application.tailwind.css`
- [ ] T066 [US5] Update QuestionsController#create to handle emoji_reaction question creation in `app/controllers/questions_controller.rb`
- [ ] T067 [US5] Update ResponsesController#update to handle emoji selection persistence in `app/controllers/responses_controller.rb`

**Checkpoint**: User Stories 1-5 should all work independently

---

## Phase 8: User Story 6 - RPG Character Sheet Stats (Priority: P3)

**Goal**: Users distribute points across multiple attributes to build a "character sheet" representing their work style, skills, or preferences

**Independent Test**: Present a character sheet with multiple stats (e.g., "Leadership", "Technical", "Creative"), allow point allocation with constraints (e.g., 20 total points), save complete stat distribution

### Tests for User Story 6 (TDD - Write FIRST, ensure they FAIL)

- [ ] T068 [P] [US6] Create model test for character_sheet question settings validation in `test/models/question_test.rb`
- [ ] T069 [P] [US6] Create model test for character_sheet answer validation in `test/models/answer_test.rb`
- [ ] T070 [P] [US6] Create service test for ValidateCharacterSheet in `test/services/responses/validate_character_sheet_test.rb`
- [ ] T071 [P] [US6] Create controller test for creating character_sheet question in `test/controllers/questions_controller_test.rb`
- [ ] T072 [P] [US6] Create controller test for saving character sheet allocation in `test/controllers/responses_controller_test.rb`
- [ ] T073 [US6] Create system test for character sheet workflow in `test/system/character_sheet_test.rb`

### Implementation for User Story 6

- [ ] T074 [P] [US6] Create Stimulus character sheet controller with point budget tracking in `app/javascript/controllers/character_sheet_controller.js`
- [ ] T075 [P] [US6] Create character sheet view partial in `app/views/responses/_question_types/_character_sheet.html.erb`
- [ ] T076 [P] [US6] Create character sheet config form partial for admin in `app/views/questions/_form_fields/_character_sheet_config.html.erb`
- [ ] T077 [US6] Update QuestionsController#create to handle character_sheet question creation in `app/controllers/questions_controller.rb`
- [ ] T078 [US6] Update ResponsesController#update to handle character sheet persistence with ValidateCharacterSheet service in `app/controllers/responses_controller.rb`

**Checkpoint**: All 6 user stories should now be independently functional

---

## Phase 9: Polish & Cross-Cutting Concerns

**Purpose**: Improvements that affect multiple user stories

- [ ] T079 [P] Add dynamic question type form loading with Stimulus controller in `app/javascript/controllers/question_form_controller.js`
- [ ] T080 [P] Create QuestionsController#config_fields action for dynamic form partial loading in `app/controllers/questions_controller.rb`
- [ ] T081 [P] Add route for config_fields in `config/routes.rb`
- [ ] T082 [P] Update main question form to dynamically load config partials in `app/views/questions/_form.html.erb`
- [ ] T083 [P] Add service tests for Questions::ValidateConfiguration in `test/services/questions/validate_configuration_test.rb`
- [ ] T084 [P] Add service tests for Responses::SaveAnswer in `test/services/responses/save_answer_test.rb`
- [ ] T085 [P] Create seed data examples for all 6 question types in `db/seeds.rb`
- [ ] T086 [P] Add GIN index optimization for jsonb_value and selected_option_ids (verify migration includes this from Phase 2)
- [ ] T087 Run full test suite: `rails test`
- [ ] T088 Run RuboCop for code style: `bundle exec rubocop`
- [ ] T089 Validate quickstart.md instructions by following the guide

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: No dependencies - can start immediately
- **Foundational (Phase 2)**: Depends on Setup completion - BLOCKS all user stories
- **User Stories (Phase 3-8)**: All depend on Foundational phase completion
  - User stories can proceed in parallel (if staffed)
  - Or sequentially in priority order (P1 → P2 → P3)
- **Polish (Phase 9)**: Depends on all desired user stories being complete

### User Story Dependencies

- **User Story 1 (P1)**: Can start after Foundational (Phase 2) - No dependencies on other stories
- **User Story 2 (P2)**: Can start after Foundational (Phase 2) - Independent of US1
- **User Story 3 (P2)**: Can start after Foundational (Phase 2) - Independent of US1, US2
- **User Story 4 (P3)**: Can start after Foundational (Phase 2) - Independent of US1-3
- **User Story 5 (P3)**: Can start after Foundational (Phase 2) - Independent of US1-4
- **User Story 6 (P3)**: Can start after Foundational (Phase 2) - Independent of US1-5

### Within Each User Story

- Tests MUST be written and FAIL before implementation (TDD)
- Tests marked [P] can run in parallel (different test files)
- View partials and Stimulus controllers can be developed in parallel [P]
- Controller updates depend on view/stimulus implementation completing
- Story complete before moving to next priority

### Parallel Opportunities

- **Setup (Phase 1)**: All 4 tasks can run in parallel
- **Foundational (Phase 2)**:
  - T005-T007 (migrations) must be sequential
  - T008-T011 (models) can run in parallel after migrations
  - T012-T014 (services) can run in parallel
- **Within Each User Story**:
  - All tests can run in parallel
  - View partials, Stimulus controllers, config forms can run in parallel
  - Controller updates must come after view/stimulus work
- **Across User Stories**: Once Foundational is complete, ALL 6 user stories can be developed in parallel

---

## Parallel Examples

### Phase 1: Setup (All in parallel)
```bash
Task: "Pin SortableJS via importmap"
Task: "Pin Chart.js via importmap"
Task: "Pin chartjs-plugin-dragdata"
Task: "Run bundle install"
```

### User Story 1: Tests (All in parallel after Foundational)
```bash
Task: "Create model test for slider question settings validation"
Task: "Create model test for slider answer value validation"
Task: "Create controller test for creating slider question"
Task: "Create controller test for saving slider answer"
# Note: System test (T019) runs sequentially after unit tests
```

### User Story 1: Implementation (Partials and controllers in parallel)
```bash
Task: "Create Stimulus slider controller"
Task: "Create slider question view partial"
Task: "Create slider config form partial for admin"
# Note: Controller updates (T023, T024) depend on these completing
```

### Across All Stories (After Foundational complete)
```bash
# Multiple developers can work on different stories simultaneously:
Developer A: User Story 1 (Slider)
Developer B: User Story 2 (Swipe Yes/No)
Developer C: User Story 3 (Card Sorting)
```

---

## Implementation Strategy

### MVP First (User Story 1 Only)

1. Complete Phase 1: Setup
2. Complete Phase 2: Foundational (CRITICAL - blocks all stories)
3. Complete Phase 3: User Story 1 (Slider)
4. **STOP and VALIDATE**: Test User Story 1 independently
5. Deploy/demo if ready

### Incremental Delivery

1. Complete Setup + Foundational → Foundation ready
2. Add User Story 1 (Slider) → Test independently → Deploy/Demo (MVP!)
3. Add User Story 2 (Swipe) → Test independently → Deploy/Demo
4. Add User Story 3 (Card Sort) → Test independently → Deploy/Demo
5. Add User Story 4 (Energy Map) → Test independently → Deploy/Demo
6. Add User Story 5 (Emoji Reaction) → Test independently → Deploy/Demo
7. Add User Story 6 (Character Sheet) → Test independently → Deploy/Demo
8. Each story adds value without breaking previous stories

### Parallel Team Strategy

With multiple developers:

1. Team completes Setup + Foundational together
2. Once Foundational is done:
   - Developer A: User Story 1 (Slider) - P1
   - Developer B: User Story 2 (Swipe) - P2
   - Developer C: User Story 3 (Card Sort) - P2
   - Developer D: User Story 4 (Energy Map) - P3
   - Developer E: User Story 5 (Emoji Reaction) - P3
   - Developer F: User Story 6 (Character Sheet) - P3
3. Stories complete and integrate independently

---

## Testing Strategy

### TDD Workflow (MANDATORY per Constitution)

For each user story:

1. **RED**: Write tests first, ensure they FAIL
   - Model tests: Question settings validation
   - Model tests: Answer value validation
   - Controller tests: Question creation
   - Controller tests: Answer persistence
   - System tests: Full user workflow

2. **GREEN**: Implement minimal code to pass tests
   - Stimulus controllers
   - View partials
   - Controller actions

3. **REFACTOR**: Improve code while maintaining green tests
   - Extract service objects
   - DRY up view partials
   - Optimize validations

### Test Coverage by Story

Each user story has:
- 2 model tests (question settings, answer validation)
- 2 controller tests (question creation, answer save)
- 1 system test (end-to-end workflow)

Total: 30 tests (5 tests × 6 stories)

### Running Tests

```bash
# Run all tests
rails test

# Run tests for specific story
rails test test/system/slider_input_test.rb

# Run all system tests
rails test:system

# Run all model tests
rails test:models
```

---

## Task Count Summary

- **Phase 1 (Setup)**: 4 tasks
- **Phase 2 (Foundational)**: 10 tasks (CRITICAL - blocks all stories)
- **Phase 3 (US1 - Slider)**: 10 tasks (5 tests + 5 implementation)
- **Phase 4 (US2 - Swipe)**: 11 tasks (5 tests + 6 implementation)
- **Phase 5 (US3 - Card Sort)**: 11 tasks (5 tests + 6 implementation)
- **Phase 6 (US4 - Energy Map)**: 10 tasks (5 tests + 5 implementation)
- **Phase 7 (US5 - Emoji)**: 11 tasks (5 tests + 6 implementation)
- **Phase 8 (US6 - Character Sheet)**: 11 tasks (6 tests + 5 implementation)
- **Phase 9 (Polish)**: 11 tasks

**Total**: 89 tasks

### Tasks by User Story
- User Story 1: 10 tasks
- User Story 2: 11 tasks
- User Story 3: 11 tasks
- User Story 4: 10 tasks
- User Story 5: 11 tasks
- User Story 6: 11 tasks

### Parallel Opportunities Identified
- Phase 1: 4 parallel tasks
- Phase 2: 7 parallel tasks (within constraints)
- Per User Story: 5-6 parallel tasks (tests, then implementation)
- Across Stories: 6 stories can proceed in parallel after Foundational

### Independent Test Criteria
Each user story can be tested independently by:
- US1: Create slider question, set value, verify save
- US2: Present swipe question, swipe left/right, verify choice
- US3: Display cards, drag to reorder, verify ranking
- US4: Show timeline, plot energy points, verify pattern
- US5: Show statement, tap emoji, verify selection
- US6: Display stats, allocate points, verify distribution

---

## Notes

- [P] tasks = different files, no dependencies - can run in parallel
- [Story] label (US1-US6) maps task to specific user story for traceability
- Each user story is independently completable and testable
- TDD MANDATORY: Verify tests fail (RED) before implementing (GREEN)
- Commit after each task or logical group
- Stop at any checkpoint to validate story independently
- Constitution principles upheld: Rails conventions, thin controllers, service objects, DaisyUI components, Hotwire-first, database integrity
- Bundle size impact: 27 KB total (SortableJS 15.5 KB + Chart.js + plugin 11 KB)
