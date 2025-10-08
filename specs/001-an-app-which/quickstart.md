# Quickstart Guide: How to Work With Me App

**Feature**: Employee Questionnaire & Profile Application
**Date**: 2025-10-08
**Branch**: 001-an-app-which

## Prerequisites

- Ruby 3.3+ installed
- Rails 8.0.3
- PostgreSQL installed (for production-like development)
- Node.js and Yarn/npm (for JavaScript dependencies)
- Git

## Initial Setup

### 1. Install Dependencies

```bash
# Install Ruby gems
bundle install

# Install JavaScript dependencies
yarn install
# or
npm install

# Install PostgreSQL (macOS)
brew install postgresql@16
brew services start postgresql@16

# Or use Docker
docker run --name postgres -e POSTGRES_PASSWORD=password -p 5432:5432 -d postgres:16
```

### 2. Database Setup

Update `config/database.yml` for PostgreSQL (currently using SQLite):

```yaml
development:
  adapter: postgresql
  encoding: unicode
  database: howtoworkwithme_development
  pool: 5
  username: <%= ENV.fetch("DATABASE_USERNAME", "postgres") %>
  password: <%= ENV.fetch("DATABASE_PASSWORD", "password") %>
  host: <%= ENV.fetch("DATABASE_HOST", "localhost") %>

test:
  adapter: postgresql
  encoding: unicode
  database: howtoworkwithme_test
  pool: 5
  username: <%= ENV.fetch("DATABASE_USERNAME", "postgres") %>
  password: <%= ENV.fetch("DATABASE_PASSWORD", "password") %>
  host: <%= ENV.fetch("DATABASE_HOST", "localhost") %>
```

Add PostgreSQL gem to Gemfile:

```ruby
# Gemfile
gem 'pg', '~> 1.1'
```

Run database setup:

```bash
# Create databases
rails db:create

# Run migrations (to be created)
rails db:migrate

# Seed sample data (optional)
rails db:seed
```

### 3. Start Development Server

```bash
# Start Rails server, CSS compilation, and JavaScript build
bin/dev

# Or individually:
rails server      # http://localhost:3000
bin/rails tailwindcss:watch  # CSS compilation
```

### 4. Verify Setup

Visit http://localhost:3000 and verify the application loads.

---

## Development Workflow

### Test-Driven Development (TDD)

Per Constitution Principle III, all features MUST follow TDD:

```bash
# 1. Write failing test first
rails test test/models/questionnaire_test.rb

# 2. Implement minimal code to pass
# Edit app/models/questionnaire.rb

# 3. Verify test passes
rails test test/models/questionnaire_test.rb

# 4. Refactor while keeping tests green
# Edit code

# 5. Run full test suite
rails test

# 6. Check code style
bundle exec rubocop
```

### Running Tests

```bash
# Run all tests
rails test

# Run specific test file
rails test test/models/organization_test.rb

# Run specific test by line number
rails test test/models/organization_test.rb:15

# Run system tests (Capybara + Selenium)
rails test:system

# Run with coverage (if simplecov configured)
COVERAGE=true rails test
```

### Database Migrations

```bash
# Generate model with migration
rails g model Questionnaire organization:references title:string unique_token:string:uniq

# Generate standalone migration
rails g migration AddLockedAtToQuestionnaires locked_at:datetime

# Run migrations
rails db:migrate

# Rollback last migration
rails db:rollback

# Check migration status
rails db:migrate:status

# Reset database (drop, create, migrate, seed)
rails db:reset
```

### Code Quality

```bash
# Run Rubocop
bundle exec rubocop

# Auto-fix safe offenses
bundle exec rubocop -a

# Auto-fix all offenses (use with caution)
bundle exec rubocop -A

# Run Brakeman security scan
bundle exec brakeman
```

---

## Key File Locations

### Models
- `app/models/organization.rb`
- `app/models/questionnaire.rb`
- `app/models/category.rb`
- `app/models/question.rb`
- `app/models/question_option.rb`
- `app/models/employee.rb`
- `app/models/response.rb`
- `app/models/answer.rb`
- `app/models/profile.rb`

### Controllers
- `app/controllers/organizations_controller.rb`
- `app/controllers/questionnaires_controller.rb`
- `app/controllers/categories_controller.rb`
- `app/controllers/questions_controller.rb`
- `app/controllers/responses_controller.rb`
- `app/controllers/profiles_controller.rb`

### Service Objects
- `app/services/questionnaires/generate_employee_link.rb`
- `app/services/questionnaires/lock_configuration.rb`
- `app/services/responses/save_draft.rb`
- `app/services/responses/submit_final.rb`
- `app/services/profiles/generate_shareable_link.rb`

### Views
- `app/views/organizations/`
- `app/views/questionnaires/`
- `app/views/categories/`
- `app/views/questions/`
- `app/views/responses/`
- `app/views/profiles/`

### JavaScript (Stimulus Controllers)
- `app/javascript/controllers/questionnaire_controller.js`
- `app/javascript/controllers/draft_autosave_controller.js`
- `app/javascript/controllers/question_type_controller.js`

### Tests
- `test/models/`
- `test/controllers/`
- `test/services/`
- `test/system/`
- `test/fixtures/`

### Migrations
- `db/migrate/`

---

## Implementation Order

Based on the planning workflow, implement in this order:

### Phase 1: Core Models & Migrations
1. Create Organization model with `has_secure_token`
2. Create Questionnaire model with associations
3. Create Category model with validations
4. Create Question model with question_type enum
5. Create QuestionOption model
6. Create Employee model
7. Create Response model with status enum
8. Create Answer model with polymorphic fields
9. Create Profile model

**Commands**:
```bash
rails g model Organization name:string unique_token:string:uniq
rails g model Questionnaire organization:references title:string description:text unique_token:string:uniq locked_at:datetime active:boolean
rails g model Category questionnaire:references name:string position:integer
rails g model Question category:references question_type:string text:text position:integer required:boolean settings:jsonb
rails g model QuestionOption question:references text:string position:integer
rails g model Employee organization:references name:string email:string
rails g model Response questionnaire:references employee:references unique_token:string:uniq status:string submitted_at:datetime
rails g model Answer response:references question:references text_value:text selected_option_id:integer selected_option_ids:integer[] boolean_value:boolean
rails g model Profile response:references unique_token:string:uniq viewed_count:integer

# After generating, edit migrations to add:
# - NOT NULL constraints
# - Foreign key indexes
# - Composite indexes
# - Unique constraints
# - Default values
```

### Phase 2: Controllers & Routes
1. Organizations controller (create, show)
2. Questionnaires controller (create, edit, show)
3. Categories controller (create, update, delete)
4. Questions controller (create, update, delete)
5. Responses controller (start, edit, update, submit)
6. Profiles controller (show)

**Commands**:
```bash
rails g controller Organizations create show
rails g controller Questionnaires create edit show generate_link responses
rails g controller Categories create update destroy
rails g controller Questions create update destroy
rails g controller Responses start edit update submit
rails g controller Profiles show
```

### Phase 3: Service Objects
1. `Questionnaires::GenerateEmployeeLink`
2. `Questionnaires::LockConfiguration`
3. `Responses::SaveDraft`
4. `Responses::SubmitFinal`
5. `Profiles::GenerateShareableLink`

**Commands**:
```bash
mkdir -p app/services/questionnaires
mkdir -p app/services/responses
mkdir -p app/services/profiles
touch app/services/questionnaires/generate_employee_link.rb
touch app/services/questionnaires/lock_configuration.rb
touch app/services/responses/save_draft.rb
touch app/services/responses/submit_final.rb
touch app/services/profiles/generate_shareable_link.rb
```

### Phase 4: Views & UI (DaisyUI Components)
1. Organization dashboard view
2. Questionnaire configuration views
3. Category and question forms (Turbo Frames)
4. Employee questionnaire form
5. Profile display view
6. Employer responses table

### Phase 5: JavaScript (Stimulus Controllers)
1. Draft autosave controller
2. Question type dynamic rendering controller
3. Form validation controller

### Phase 6: System Tests
1. Employer questionnaire configuration test
2. Employee questionnaire completion test
3. Profile sharing test
4. Employer dashboard test

---

## Common Development Tasks

### Add a New Model

```bash
# Generate model with migration
rails g model ModelName field:type ...

# Edit migration to add constraints
code db/migrate/[timestamp]_create_model_names.rb

# Run migration
rails db:migrate

# Write model tests
code test/models/model_name_test.rb

# Run tests
rails test test/models/model_name_test.rb
```

### Add a New Controller Action

```bash
# Add route to config/routes.rb
# Add action to controller
# Add view template
# Write system test

# Example:
# 1. Edit config/routes.rb
# 2. Edit app/controllers/questionnaires_controller.rb
# 3. Create app/views/questionnaires/action_name.html.erb
# 4. Write test/system/questionnaire_action_test.rb
```

### Add a Service Object

```bash
# Create service file
mkdir -p app/services/namespace
touch app/services/namespace/service_name.rb

# Write service test
mkdir -p test/services/namespace
touch test/services/namespace/service_name_test.rb

# Template:
# class Namespace::ServiceName
#   def initialize(params)
#     @params = params
#   end
#
#   def call
#     # Service logic
#     { success: true, data: result }
#   rescue => e
#     { success: false, error: e.message }
#   end
# end
```

### Add a Stimulus Controller

```bash
# Generate Stimulus controller
rails g stimulus ControllerName

# Or manually:
touch app/javascript/controllers/controller_name_controller.js

# Template:
# import { Controller } from "@hotwired/stimulus"
#
# export default class extends Controller {
#   static targets = [ "element" ]
#   static values = { param: String }
#
#   connect() {
#     console.log("Connected")
#   }
#
#   action() {
#     // Action logic
#   }
# }
```

### Debug in Development

```bash
# Rails console
rails console

# Test specific query
rails console
> Questionnaire.includes(:categories).first

# Check routes
rails routes | grep questionnaire

# Check logs
tail -f log/development.log
```

---

## Environment Variables

Create `.env` file for local development:

```bash
# Database
DATABASE_USERNAME=postgres
DATABASE_PASSWORD=password
DATABASE_HOST=localhost

# Rails
RAILS_ENV=development
RAILS_MAX_THREADS=5

# Optional: Rate limiting
RATE_LIMIT_REQUESTS=100
RATE_LIMIT_PERIOD=60
```

Add `.env` to `.gitignore`:

```bash
echo ".env" >> .gitignore
```

---

## Troubleshooting

### Database Issues

```bash
# Reset database
rails db:reset

# Drop and recreate
rails db:drop db:create db:migrate db:seed

# Check PostgreSQL connection
psql -U postgres -h localhost
```

### Asset Issues

```bash
# Recompile assets
bin/rails assets:precompile

# Clear cache
bin/rails tmp:clear
bin/rails assets:clobber

# Restart server
# Ctrl+C, then bin/dev
```

### Test Issues

```bash
# Reset test database
RAILS_ENV=test rails db:reset

# Run specific test with backtrace
rails test test/models/questionnaire_test.rb --backtrace

# Run with verbose output
rails test test/models/questionnaire_test.rb --verbose
```

### Rubocop Issues

```bash
# Generate TODO list for existing offenses
bundle exec rubocop --auto-gen-config

# This creates .rubocop_todo.yml which ignores existing issues
```

---

## Deployment Checklist

Before deploying to production:

- [ ] All tests passing (`rails test`)
- [ ] Rubocop passing (`bundle exec rubocop`)
- [ ] Brakeman security scan passing (`bundle exec brakeman`)
- [ ] Database migrations tested on production-like data
- [ ] Environment variables configured
- [ ] HTTPS enabled
- [ ] Rate limiting configured
- [ ] Error monitoring configured (e.g., Sentry, Rollbar)
- [ ] Logging configured
- [ ] Backups configured
- [ ] Performance tested with 100 employees (SC-006)

---

## Production Setup (Brief)

### Database Migration

```bash
# Run migrations
RAILS_ENV=production rails db:migrate

# Check status
RAILS_ENV=production rails db:migrate:status
```

### Asset Compilation

```bash
# Precompile assets
RAILS_ENV=production rails assets:precompile
```

### Server Start

```bash
# With Puma (recommended)
RAILS_ENV=production bundle exec puma -C config/puma.rb

# Or with Rails server
RAILS_ENV=production rails server -p 3000
```

---

## Useful Commands Reference

### Rails Commands
```bash
rails server                  # Start server
rails console                 # Interactive console
rails test                    # Run tests
rails routes                  # Show all routes
rails db:migrate              # Run migrations
rails db:seed                 # Seed database
rails db:reset                # Drop, create, migrate, seed
rails generate model [Name]   # Generate model
rails generate controller [Name] # Generate controller
rails generate migration [Name] # Generate migration
```

### Gem Commands
```bash
bundle install                # Install gems
bundle update                 # Update gems
bundle exec [command]         # Run command with bundler
```

### Database Commands
```bash
rails db:create               # Create database
rails db:drop                 # Drop database
rails db:migrate              # Run pending migrations
rails db:rollback             # Rollback last migration
rails db:version              # Show current schema version
rails db:seed                 # Load seed data
```

---

## Resources

### Documentation
- Rails Guides: https://guides.rubyonrails.org/
- DaisyUI Components: https://daisyui.com/components/
- Hotwire Turbo: https://turbo.hotwired.dev/
- Stimulus: https://stimulus.hotwired.dev/
- PostgreSQL Arrays: https://guides.rubyonrails.org/active_record_postgresql.html

### Project Documentation
- Feature Spec: `specs/001-an-app-which/spec.md`
- Data Model: `specs/001-an-app-which/data-model.md`
- API Contracts: `specs/001-an-app-which/contracts/routes.md`
- Research: `specs/001-an-app-which/research.md`
- Implementation Plan: `specs/001-an-app-which/plan.md`
- Constitution: `.specify/memory/constitution.md`
- Runtime Guidance: `CLAUDE.md`

---

## Getting Help

1. Check Rails logs: `tail -f log/development.log`
2. Check test output: `rails test --verbose`
3. Use Rails console: `rails console`
4. Check routes: `rails routes | grep [resource]`
5. Review project documentation (above)
6. Consult Rails Guides: https://guides.rubyonrails.org/

---

## Next Steps

1. Run `/speckit.tasks` to generate implementation tasks
2. Follow TDD workflow for each task
3. Commit frequently with descriptive messages
4. Run full test suite before each commit
5. Deploy to staging environment for manual testing
6. Deploy to production after validation
