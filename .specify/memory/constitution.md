# How to Work With Me Constitution

<!--
Sync Impact Report:
Version: 0.0.0 → 1.0.0 (Initial constitution creation)
Ratification Date: 2025-10-08
Principles Defined:
  - I. Rails Convention Over Configuration
  - II. Thin Controllers, Service Objects for Logic
  - III. Test-First Development (MANDATORY)
  - IV. DaisyUI Component Consistency
  - V. Hotwire-First Interactivity
  - VI. Database Integrity & Performance
  - VII. Simplicity & YAGNI
Templates Requiring Updates:
  ✅ plan-template.md - Constitution Check section aligns with principles
  ✅ spec-template.md - User stories and requirements structure compatible
  ✅ tasks-template.md - Task categorization reflects TDD and Rails structure
Follow-up TODOs: None
-->

## Core Principles

### I. Rails Convention Over Configuration
Follow Rails conventions strictly to maximize framework benefits and team productivity. The framework's opinions are our defaults unless explicitly justified otherwise.

**Rules**:
- Models MUST be singular CamelCase (`Organization`, `Question`, `EmployeeResponse`)
- Controllers MUST be plural CamelCase with "Controller" suffix (`OrganizationsController`)
- Routes MUST use plural snake_case (`organizations_path`, `employee_responses_path`)
- Database tables MUST be plural snake_case (`organizations`, `questions`, `employee_responses`)
- Service objects MUST be namespaced by resource (`Organizations::ConfigureQuestionnaire`)

**Rationale**: Rails conventions eliminate decision fatigue, enable developer familiarity, and ensure tooling compatibility. Deviations create cognitive overhead and maintenance burden.

### II. Thin Controllers, Service Objects for Logic
Controllers MUST delegate business logic to service objects. Controllers are responsible only for HTTP concerns: authentication, authorization, parameter handling, and response formatting.

**Rules**:
- Controllers MUST NOT contain business logic beyond simple CRUD operations
- Complex workflows (multi-step operations, external API calls, coordinated updates) MUST use service objects in `app/services/`
- Service objects MUST implement a `call` method as primary interface
- Service objects MUST return result objects or use Success/Failure patterns
- Each service object MUST focus on a single operation

**Rationale**: Thin controllers improve testability, enable logic reuse, and maintain Single Responsibility Principle. Service objects make business logic portable and independently testable.

### III. Test-First Development (MANDATORY)
All features MUST follow Test-Driven Development (TDD). Tests are written first, confirmed to fail, then implementation proceeds.

**Rules**:
- Tests MUST be written before implementation code
- Tests MUST fail initially (red phase)
- Implementation MUST make tests pass (green phase)
- Code MUST be refactored while maintaining green tests
- Model tests MUST cover validations, associations, scopes, and methods
- System tests MUST cover complete user workflows using Capybara
- Use RSpec with shoulda-matchers for cleaner assertions

**Rationale**: TDD ensures requirements are testable, prevents regression, documents expected behavior, and drives better API design. Non-negotiable for code quality and maintainability.

### IV. DaisyUI Component Consistency
UI MUST use DaisyUI component classes consistently across the application. Custom CSS MUST be avoided unless DaisyUI provides no solution.

**Rules**:
- Buttons MUST use `btn` with modifiers (`btn-primary`, `btn-error`, `btn-sm`, `btn-lg`)
- Forms MUST use `form-control`, `label`, `input`, `textarea` classes
- Cards MUST structure with `card`, `card-body`, `card-title`, `card-actions`
- Tables MUST use `table` with `table-zebra` for striped rows, wrapped in `overflow-x-auto`
- Alerts MUST use `alert` with type modifiers (`alert-success`, `alert-error`, `alert-warning`, `alert-info`)
- Validation errors MUST display with `label-text-alt text-error`

**Rationale**: Consistent component usage ensures visual coherence, reduces CSS bloat, leverages DaisyUI's accessibility features, and accelerates development through reusable patterns.

### V. Hotwire-First Interactivity
Interactivity MUST use Hotwire (Turbo + Stimulus) before reaching for JavaScript frameworks. Full page reloads MUST be avoided.

**Rules**:
- Partial page updates MUST use Turbo Frames with `turbo_frame_tag`
- Multi-element updates MUST use Turbo Streams (`prepend`, `append`, `update`, `replace`, `remove`)
- Client-side behavior (modals, dropdowns, dynamic fields) MUST use Stimulus controllers
- Stimulus controllers MUST be placed in `app/javascript/controllers/`
- Use `dom_id` helper for consistent frame/target naming
- Destructive actions MUST use `data: { turbo_confirm: "message" }`

**Rationale**: Hotwire provides SPA-like UX without JavaScript complexity, maintains server-rendered benefits, and integrates seamlessly with Rails. Reduces frontend dependencies and cognitive load.

### VI. Database Integrity & Performance
Database design MUST prioritize data integrity and query performance. Migrations are immutable once deployed.

**Rules**:
- Existing migrations MUST NEVER be edited; create new migrations for changes
- Foreign keys MUST have database-level indexes
- Frequently queried columns (used in WHERE, ORDER BY, JOIN) MUST have indexes
- Strong parameters MUST be used on all create/update actions
- N+1 queries MUST be eliminated using `includes` or `preload`
- Batch processing of large datasets MUST use `find_each`
- Null constraints and defaults MUST be set appropriately in migrations

**Rationale**: Database integrity prevents data corruption. Proper indexing prevents performance degradation as data grows. Immutable migrations ensure deployment consistency across environments.

### VII. Simplicity & YAGNI
Start with the simplest solution. Additional complexity MUST be justified by concrete requirements, not speculative future needs.

**Rules**:
- Implement only requested features (You Aren't Gonna Need It)
- Prefer Rails conventions over custom abstractions
- Extract service objects only when logic is complex or reused
- Add caching only when performance problems are measured
- Background jobs only for operations that must be asynchronous
- Document justification for any complexity violations in code comments

**Rationale**: Premature abstraction and optimization increase maintenance burden and slow feature delivery. Simple code is easier to understand, test, and modify.

## Security Requirements

### Data Protection
- Strong parameters MUST be used on all create/update controller actions
- CSRF protection MUST remain enabled (Rails default)
- Sensitive data (credentials, API keys) MUST use encrypted credentials, never committed to repository
- Content Security Policy MUST be configured in initializers

### Current Authentication State
- MVP explicitly excludes authentication and authorization
- When authentication is added, it MUST follow principle-based approach (service objects, tested first, simple)

## Development Workflow

### Feature Development Process
1. Create feature branch from main
2. Write failing tests first (TDD - Principle III)
3. Implement minimal code to pass tests
4. Refactor while keeping tests green
5. Run full test suite (`bundle exec rspec`)
6. Check code style with Rubocop (`bundle exec rubocop`)
7. Create pull request with description and testing notes

### Code Quality Gates
- All tests MUST pass before merging
- Rubocop MUST pass with no violations
- N+1 queries MUST be resolved (check with Bullet gem or similar)
- Manual testing of user workflow MUST be performed

## Governance

### Amendment Procedure
1. Proposed amendments MUST be documented with rationale
2. Version number MUST be incremented according to semantic versioning:
   - **MAJOR**: Backward incompatible governance changes (e.g., removing mandatory TDD)
   - **MINOR**: New principles added or existing principles materially expanded
   - **PATCH**: Clarifications, wording improvements, non-semantic refinements
3. All dependent templates (plan, spec, tasks) MUST be updated for consistency
4. Amendment date MUST be recorded in Last Amended field

### Compliance
- All pull requests MUST verify compliance with Core Principles
- Constitution violations MUST be justified in PR description with reference to Complexity Tracking section in plan.md
- Code reviews MUST check for adherence to DaisyUI component patterns (Principle IV) and Hotwire usage (Principle V)
- Runtime development guidance is available in `CLAUDE.md`

### Versioning Policy
- Constitution version follows MAJOR.MINOR.PATCH format
- Breaking changes to principles require MAJOR bump and migration plan
- New guidance or sections require MINOR bump
- Clarifications and fixes require PATCH bump

**Version**: 1.0.0 | **Ratified**: 2025-10-08 | **Last Amended**: 2025-10-08
