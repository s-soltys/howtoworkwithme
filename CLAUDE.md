# Ruby on Rails + DaisyUI Project Guidelines

## Architecture Principles

### Controllers
- Keep controllers thin - delegate business logic to service objects
- Use `before_action` for authentication, authorization, and setup
- Return appropriate HTTP status codes (`:ok`, `:created`, `:unprocessable_entity`)
- Always use strong parameters for mass assignment protection
- One action should have one responsibility

### Models
- Follow Single Responsibility Principle
- Use validations for data integrity
- Complex queries belong in scopes or class methods
- Use concerns for shared behavior across models
- Minimize callbacks - prefer service objects for complex workflows
- Use enums for status/state fields

### Service Objects
- Extract complex business logic into service objects in `app/services/`
- Use a `call` method as the primary interface
- Return result objects or use Success/Failure patterns
- Keep services focused on a single operation

### Views & Partials
- Use partials to DRY up repeated view code
- Keep logic out of views - use helpers or decorators
- Always pass locals explicitly when rendering partials
- Use view components for complex, reusable UI elements

## DaisyUI Component Standards

### Component Library Setup
- DaisyUI configured in `tailwind.config.js` with theme settings
- Use semantic component classes consistently across the app

### Component Usage Patterns
- **Buttons**: Use `btn` + modifier classes (`btn-primary`, `btn-error`, `btn-sm`, `btn-lg`)
- **Cards**: Structure with `card`, `card-body`, `card-title`, `card-actions`
- **Forms**: Use `form-control`, `label`, `input`, `textarea`, `checkbox` classes
- **Form Errors**: Display validation errors with `label-text-alt text-error`
- **Alerts**: Use `alert` with type modifiers (`alert-success`, `alert-error`, `alert-warning`, `alert-info`)
- **Tables**: Use `table` with `table-zebra` for striped rows, wrap in `overflow-x-auto` for responsiveness
- **Modals**: Implement with modal-toggle checkbox pattern or dialog element with Stimulus
- **Navigation**: Use `navbar` with `navbar-start`, `navbar-center`, `navbar-end` sections
- **Dropdowns**: Use `dropdown` with `dropdown-end` or `dropdown-start` positioning
- **Loading States**: Use `loading` spinner classes and `skeleton` loaders for content placeholders
- **Menus**: Use `menu` class with `menu-horizontal` or `menu-vertical`

### Flash Message Helper
- Create `alert_class` helper to map Rails flash types to DaisyUI alert classes
- Display in toast notifications using `toast` positioning classes

## Hotwire & Turbo Integration

### Turbo Frames
- Isolate page sections with `turbo_frame_tag` for partial updates
- Use `dom_id` helper for consistent frame naming
- Frames automatically scope navigation and form submissions

### Turbo Streams
- Use for updating multiple page elements simultaneously
- Common actions: `prepend`, `append`, `update`, `replace`, `remove`
- Respond with `format.turbo_stream` in controller actions
- Can render multiple stream actions in array format

### Stimulus Controllers
- Add interactive behavior without full page reloads
- Place in `app/javascript/controllers/`
- Use data attributes: `data-controller`, `data-action`, `data-{controller}-target`
- Common use cases: modals, dropdowns, form validation, dynamic fields

## Testing Requirements

### Model Tests
- Test validations, associations, scopes, and methods
- Use RSpec with shoulda-matchers for cleaner assertions
- Test both positive and negative cases

### System Tests
- Test full user workflows with Capybara
- Use data-testid selectors to find elements
- Test Turbo Frame/Stream behavior
- Run with headless Chrome for CI/CD compatibility

## Security Standards

### Authentication & Authorization
- No authentication or authorization yet

### Data Protection
- Strong parameters required on all create/update actions
- CSRF protection enabled by default - keep it
- Configure Content Security Policy in initializers
- Never commit sensitive data (use encrypted credentials)

### Turbo Confirm
- Use `data: { turbo_confirm: "message" }` for destructive actions

## Database Best Practices

### Migrations
- Never edit existing migrations - create new ones
- Add indexes for foreign keys and frequently queried columns
- Use `change` method for automatic reversibility
- Set appropriate null constraints and defaults

### Query Optimization
- Always use `includes` or `preload` to avoid N+1 queries
- Use `select` to limit columns when appropriate
- Add database indexes for columns used in WHERE, ORDER BY, JOIN
- Use `find_each` for batch processing large datasets

## Performance Guidelines

### Caching Strategy
- Fragment caching for expensive view rendering
- Russian Doll caching for nested resources
- Low-level caching for expensive computations
- Set appropriate cache expiration

### Background Jobs
- Use ActiveJob for long-running tasks
- Common cases: email sending, external API calls, report generation
- Choose appropriate queue adapter (Sidekiq for production)

## Code Style Standards

### Ruby Conventions
- Follow Ruby Style Guide
- Use Rubocop for consistent formatting
- Prefer double quotes for strings
- Use trailing commas in multi-line collections

### Naming Conventions
- Models: singular CamelCase (`Article`, `UserProfile`)
- Controllers: plural CamelCase with "Controller" (`ArticlesController`)
- Routes: plural snake_case (`articles_path`)
- Tables: plural snake_case (`articles`, `user_profiles`)
- Service objects: namespace with resource (`Articles::PublishService`)

### Documentation
- Write self-documenting code when possible
- Comment complex business logic
- Use YARD format for public API documentation

## Project Structure

```
app/
├── controllers/
├── models/
├── views/
│   └── layouts/
├── services/
├── javascript/controllers/
└── helpers/
```

## Development Workflow

1. Create feature branch from main
2. Write failing tests first (TDD)
3. Implement minimal code to pass tests
4. Refactor while keeping tests green
5. Run full test suite
6. Check code style with Rubocop
7. Create PR with description and testing notes

## Common Rails Commands

- Start server: `bin/dev`
- Run tests: `bundle exec rspec`
- Run Rubocop: `bundle exec rubocop`
- Database: `rails db:migrate`, `rails db:seed`, `rails db:reset`
- Console: `rails console`
- Routes: `rails routes | grep [resource]`
- Generators: `rails g model/controller/migration`

## Key Resources

- Rails Guides: https://guides.rubyonrails.org/
- DaisyUI Docs: https://daisyui.com/components/
- Hotwire Docs: https://hotwired.dev/
- RSpec Rails: https://github.com/rspec/rspec-rails
