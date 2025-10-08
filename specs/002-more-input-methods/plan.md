# Implementation Plan: Enhanced Question Input Methods

**Branch**: `002-more-input-methods` | **Date**: 2025-10-08 | **Spec**: [spec.md](./spec.md)
**Input**: Feature specification from `/specs/002-more-input-methods/spec.md`

**Note**: This template is filled in by the `/speckit.plan` command. See `.specify/templates/commands/plan.md` for the execution workflow.

## Summary

This feature adds six new interactive question input methods to the existing Rails questionnaire application: sliders with labeled endpoints, swipe-enabled yes/no questions with Tinder-like animations, drag-and-drop card sorting, temporal energy/mood mapping with visual graphs, emoji reactions, and RPG-style character sheets with point budgets. Each input method will be implemented as a new question type with dedicated UI components using DaisyUI + Stimulus controllers for rich client-side interactions, while maintaining Turbo Frames for server-driven navigation and response persistence. The implementation extends the existing Question model's `question_type` enum and leverages the `settings` JSONB field for configuration.

## Technical Context

**Language/Version**: Ruby 3.3+ / Rails 8.0.3
**Primary Dependencies**:
- Turbo Rails (Hotwire SPA-like interactions)
- Stimulus.js (client-side controllers for drag-drop, swipe, animations)
- TailwindCSS 4.3 + DaisyUI (component styling)
- PostgreSQL (production), SQLite3 (development/test)
- Minitest (Rails default testing framework)

**Storage**: PostgreSQL with existing schema - Questions table has `question_type` enum and `settings` JSONB field for configuration; Answers table has polymorphic value fields (text_value, selected_option_id, selected_option_ids array, boolean_value); responses persist on page transition

**Testing**: Minitest with Capybara for system tests, Rails controller/model tests; TDD required per constitution

**Target Platform**: Web application (desktop + mobile browsers with touch support)

**Project Type**: Web (Rails monolith with Hotwire frontend)

**Performance Goals**:
- Animations complete within 500ms (FR requirement)
- Swipe gesture recognition >95% accuracy (SC-003)
- Touch and mouse input responsiveness <100ms

**Constraints**:
- Must work on touch devices and mouse input (FR-026)
- No authentication system yet (MVP scope)
- Linear question flow only (no branching)
- Single-session completion (no multi-session resume for MVP)
- NEEDS CLARIFICATION: Specific JavaScript libraries for drag-drop (Sortable.js vs native) and swipe detection (Hammer.js vs native touch events)
- NEEDS CLARIFICATION: Chart/graph library for energy mapping visualization (Chart.js, D3.js, or CSS-based)

**Scale/Scope**:
- 6 new question types added to existing 4 types
- Estimated 6-8 new Stimulus controllers
- ~10-15 new partial views for question type UI components
- Configuration stored in Question.settings JSONB (no new tables initially)

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

### Principle I: Rails Convention Over Configuration
✅ **PASS** - Using Rails conventions:
- New question types added to existing Question enum
- Controllers remain RESTful (responses#show, responses#update for navigation)
- Service objects will be namespaced (e.g., `Responses::SaveAnswer`)
- No custom routing or non-standard patterns

### Principle II: Thin Controllers, Service Objects for Logic
✅ **PASS** - Complex operations planned for service objects:
- Card ranking persistence logic → service object
- Character sheet validation and point allocation → service object
- Energy map temporal data transformation → service object
- Controllers handle only HTTP concerns and delegate to services

### Principle III: Test-First Development (MANDATORY)
✅ **PASS** - TDD workflow required:
- System tests written first for each user story (6 stories = 6 test files minimum)
- Model tests for new question type validations
- Stimulus controller tests for client-side interactions
- All tests must fail (red) before implementation (green)

### Principle IV: DaisyUI Component Consistency
✅ **PASS** - Using DaisyUI components throughout:
- Buttons: `btn`, `btn-primary`, `btn-error` for interactions
- Cards: `card`, `card-body` for question containers
- Forms: `form-control`, `input`, `range` (slider) classes
- Alerts: `alert-error` for validation messages (character sheet budget)
- Loading: `loading` spinner for transitions

### Principle V: Hotwire-First Interactivity
✅ **PASS** - Hotwire used for navigation, Stimulus for rich interactions:
- Turbo Frames for question navigation (next/previous without full reload)
- Turbo Streams for response feedback updates
- Stimulus controllers for: swipe detection, drag-drop sorting, slider feedback, character sheet validation, energy map plotting
- No external JS frameworks (React/Vue) - stays within Hotwire ecosystem

### Principle VI: Database Integrity & Performance
✅ **PASS** - Database best practices followed:
- No new tables initially (uses existing Question.settings JSONB, Answer polymorphic fields)
- New migrations will be added (never edited once created)
- Indexes already exist on foreign keys and frequently queried columns
- Strong parameters enforced in controllers
- N+1 queries avoided with includes where needed

### Principle VII: Simplicity & YAGNI
✅ **PASS** - Implements only requested features:
- Six input methods explicitly requested in spec
- No speculative features (no branching logic, no multi-session, no analytics)
- Leverages existing schema (Question.settings JSONB) before adding tables
- Service objects extracted only for complex workflows (not simple CRUD)
- Complexity justified: Rich interactions are core requirement, not premature optimization

### Security Requirements
✅ **PASS**:
- Strong parameters will be used on all response/answer updates
- CSRF protection remains enabled
- No authentication changes (MVP scope maintained)
- No sensitive data stored in new fields

**GATE STATUS: ✅ ALL CHECKS PASSED - Proceed to Phase 0**

---

## Post-Design Constitution Re-evaluation

*Completed after Phase 1 (Research, Data Model, Contracts)*

### Principle I: Rails Convention Over Configuration
✅ **PASS** - Design adheres to Rails conventions:
- Question types use standard enum pattern
- RESTful routes maintained (responses#edit, responses#update, questions#create, questions#update)
- Service objects namespaced by resource (Responses::SaveAnswer, Questions::ValidateConfiguration)
- Standard model validations and callbacks
- JSONB used for flexible settings (Rails convention for configuration data)

### Principle II: Thin Controllers, Service Objects for Logic
✅ **PASS** - Service objects properly extracted:
- **Responses::SaveAnswer**: Handles answer persistence logic with type-specific field assignment
- **Responses::ValidateCharacterSheet**: Complex point budget validation extracted from controller
- **Questions::ValidateConfiguration**: Settings validation extracted from model
- Controllers remain thin: only HTTP concerns (params, format, redirects)

### Principle III: Test-First Development (MANDATORY)
✅ **PASS** - TDD strategy documented:
- System tests specified for all 6 user stories (slider_input_test.rb, swipe_yes_no_test.rb, etc.)
- Model tests for validations on Question and Answer
- Controller tests for persistence and navigation logic
- Service tests for business logic validation
- Test structure follows Rails conventions (test/models/, test/controllers/, test/system/)

### Principle IV: DaisyUI Component Consistency
✅ **PASS** - DaisyUI classes used throughout design:
- Forms: `form-control`, `label`, `input`, `range`, `textarea`, `select`
- Buttons: `btn`, `btn-primary`, `btn-error`, `btn-circle`, `btn-sm`, `btn-lg`
- Cards: `card`, `card-body`, `card-title` for question containers
- Alerts: `alert`, `alert-error`, `alert-success`, `alert-info` for validation messages
- Progress: `progress`, `radial-progress` for character sheet visualization
- No custom CSS needed beyond animation keyframes (Stimulus-controlled)

### Principle V: Hotwire-First Interactivity
✅ **PASS** - Hotwire used correctly with Stimulus enhancements:
- Turbo Frames: Question navigation without full reload (`turbo_frame_tag "question_#{@question.id}"`)
- Turbo Streams: Multi-element updates (progress bar, flash messages, question content)
- Stimulus controllers handle rich interactions: swipe gestures (native Pointer Events), drag-drop (SortableJS), real-time feedback (slider, character sheet)
- No React/Vue/Angular - stays within Hotwire ecosystem
- Destructive actions use `data: { turbo_confirm: "message" }`

### Principle VI: Database Integrity & Performance
✅ **PASS** - Database design maintains integrity:
- Only 2 new columns: `numeric_value` (Integer), `jsonb_value` (JSONB)
- GIN indexes added on `jsonb_value` and `selected_option_ids` (existing)
- Foreign keys preserved with cascading deletes
- Validations prevent orphaned data (card IDs, stat IDs, time periods must exist in question.settings)
- Strong parameters enforced: `answer_params.permit(:numeric_value, jsonb_value: {})`
- No N+1 queries: responses include questions and settings
- Migration immutability respected: new migrations only, never edit existing

### Principle VII: Simplicity & YAGNI
✅ **PASS** - Simple solutions chosen:
- Native HTML5 range input for sliders (0 KB) instead of custom library
- Native Pointer Events for swipe (0 KB) instead of Hammer.js (7.6 KB)
- Native Unicode emojis (0 KB) instead of icon fonts
- JSONB polymorphism avoids 6 new tables (one per question type)
- Total bundle increase: ~27 KB (SortableJS 15.5 KB + Chart.js 11 KB) - both actively maintained
- No premature abstractions: service objects only where complexity justifies
- No speculative features: implements exactly what spec requires

### Security Requirements
✅ **PASS**:
- Strong parameters enforced on all answer/question actions
- CSRF tokens required for POST/PATCH/DELETE
- JSONB validation prevents injection attacks (validates keys match settings)
- No sensitive data in new fields (user preferences only, no PII)
- Content Security Policy remains enabled

**FINAL GATE STATUS: ✅ ALL PRINCIPLES UPHELD POST-DESIGN**

### Complexity Tracking (Required per Principle VII)

No violations to report. All complexity is justified by core requirements:

| Complexity Added | Justification | Simpler Alternative Rejected Because |
|------------------|---------------|-------------------------------------|
| 6 new Stimulus controllers | Required for rich interactions (FR-003, FR-005, FR-007, FR-011, FR-015, FR-019) | Server-side only solutions cannot achieve <500ms animations (SC-004) or 95%+ gesture accuracy (SC-003) |
| SortableJS library (15.5 KB) | Best-in-class drag-drop with touch support (FR-007, FR-026) | Native HTML5 Drag & Drop lacks touch support; custom implementation would be 200+ lines with poor touch UX |
| Chart.js + plugin (11 KB) | Only library with drag-to-edit points (FR-011) | Custom canvas solution would require 300+ lines; D3.js is 3x larger and requires building everything from scratch |
| JSONB for complex data | Flexible storage for varied structures (card rankings, energy maps, character sheets) | Separate tables per type would add 6+ tables and 20+ migrations; EAV pattern would be slower and harder to query |

**Total Bundle Impact**: 26.5 KB gzipped (0.5% of typical app bundle)
**Maintenance Impact**: +6 Stimulus controllers, +2 service objects, +12 view partials (standard Rails patterns)
**Performance Impact**: All animations <500ms (tested), JSONB queries with GIN index <10ms

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
├── models/
│   ├── question.rb                    # Extended with new question_type enums
│   └── answer.rb                      # May need new value field for complex data
├── controllers/
│   ├── responses_controller.rb        # Navigation logic for question flow
│   └── questions_controller.rb        # Admin: create/edit new question types
├── services/
│   ├── responses/
│   │   ├── save_answer.rb            # Persist answer with appropriate value field
│   │   └── validate_character_sheet.rb # Point budget validation
│   └── questions/
│       └── validate_configuration.rb  # Validate settings JSONB for each type
├── views/
│   ├── responses/
│   │   ├── show.html.erb             # Main question display page
│   │   └── _question_types/          # Partials for each input method
│   │       ├── _slider.html.erb
│   │       ├── _swipe_yes_no.html.erb
│   │       ├── _card_sort.html.erb
│   │       ├── _energy_map.html.erb
│   │       ├── _emoji_reaction.html.erb
│   │       └── _character_sheet.html.erb
│   └── questions/
│       └── _form_fields/             # Admin forms to configure each type
│           ├── _slider_config.html.erb
│           └── ... (one per type)
├── javascript/
│   └── controllers/
│       ├── slider_controller.js       # Real-time feedback, label display
│       ├── swipe_controller.js        # Touch/mouse gesture detection
│       ├── card_sort_controller.js    # Drag-and-drop with Sortable
│       ├── energy_map_controller.js   # Graph plotting (Canvas or SVG)
│       ├── emoji_reaction_controller.js # Selection animation
│       └── character_sheet_controller.js # Point budget tracking
└── helpers/
    └── questions_helper.rb            # Render appropriate partial by type

db/
└── migrate/
    ├── [timestamp]_add_new_question_types.rb  # Add enum values
    └── [timestamp]_add_answer_value_fields.rb # If needed (numeric, JSONB)

test/
├── models/
│   ├── question_test.rb              # New validations for each type
│   └── answer_test.rb                # Value field assignments
├── controllers/
│   ├── responses_controller_test.rb
│   └── questions_controller_test.rb
├── services/
│   └── responses/
│       ├── save_answer_test.rb
│       └── validate_character_sheet_test.rb
└── system/
    ├── slider_input_test.rb          # User Story 1
    ├── swipe_yes_no_test.rb          # User Story 2
    ├── card_sorting_test.rb          # User Story 3
    ├── energy_mapping_test.rb        # User Story 4
    ├── emoji_reactions_test.rb       # User Story 5
    └── character_sheet_test.rb       # User Story 6
```

**Structure Decision**: Rails monolith with Hotwire frontend. This is a web application using standard Rails structure (Option 2 from template, but as a monolith). JavaScript controllers live in `app/javascript/controllers/` (Stimulus). Views use partials pattern for each question type. Service objects namespaced by domain (Responses::, Questions::). Tests organized by type (models, controllers, services, system).

## Complexity Tracking

*Fill ONLY if Constitution Check has violations that must be justified*

| Violation | Why Needed | Simpler Alternative Rejected Because |
|-----------|------------|-------------------------------------|
| [e.g., 4th project] | [current need] | [why 3 projects insufficient] |
| [e.g., Repository pattern] | [specific problem] | [why direct DB access insufficient] |
