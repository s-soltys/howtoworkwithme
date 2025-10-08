# How to Work With Me - Employee Questionnaire & Profile App

An application enabling new employees to complete customizable questionnaires and generate shareable "How to work with me" profiles. Employers can configure organizations with categorized questions (free text, multiple choice, yes/no), employees fill questionnaires via unique links, and results are shareable via profile links plus viewable in an employer dashboard.

## Core User Journeys

### Employer Workflow
1. Create an organization
2. Configure the questionnaire:
   - Create categories (e.g., "Communication Preferences", "Work Style")
   - Create questions with different types (free text, multiple choice, yes/no)
3. Generate a unique link for employees
4. View employee responses in a dashboard table

### Employee Workflow
1. Open the questionnaire link
2. Enter name and answer questions
3. Submit and receive a shareable profile link
4. Share the profile link with colleagues

**Note**: MVP excludes authentication and authorization.

## Prerequisites

- Ruby 3.3+
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
```

### 2. Database Setup

The application uses PostgreSQL. Install it:

```bash
# macOS
brew install postgresql@16
brew services start postgresql@16

# Or use Docker
docker run --name postgres -e POSTGRES_PASSWORD=password -p 5432:5432 -d postgres:16
```

Create and migrate the database:

```bash
# Create databases
rails db:create

# Run migrations
rails db:migrate

# Optional: Load seed data
rails db:seed
```

### 3. Environment Configuration

Create a `.env` file for local development (optional):

```bash
# Database
DATABASE_USERNAME=postgres
DATABASE_PASSWORD=password
DATABASE_HOST=localhost

# Rails
RAILS_ENV=development
RAILS_MAX_THREADS=5
```

Add `.env` to `.gitignore`:

```bash
echo ".env" >> .gitignore
```

### 4. Start Development Server

```bash
# Start Rails server, CSS compilation, and JavaScript build
bin/dev

# Visit http://localhost:3000
```

## Running Tests

```bash
# Run all tests
rails test

# Run specific test file
rails test test/models/organization_test.rb

# Run system tests (Capybara + Selenium)
rails test:system
```

## Code Quality

```bash
# Run Rubocop code style check
bundle exec rubocop

# Auto-fix safe offenses
bundle exec rubocop -a

# Run Brakeman security scan
bundle exec brakeman
```

## Project Structure

```
app/
├── controllers/     # MVC controllers (thin, delegate to services)
├── models/          # ActiveRecord models
├── services/        # Business logic (Questionnaires, Responses, Profiles)
├── views/           # ERB templates with DaisyUI components
├── javascript/      # Stimulus controllers
└── helpers/         # View helpers

test/
├── models/          # Model tests
├── controllers/     # Controller tests
├── services/        # Service tests
└── system/          # End-to-end tests with Capybara
```

## Technology Stack

- **Backend**: Ruby on Rails 8.0.3
- **Database**: PostgreSQL (production), SQLite3 (development/test)
- **Frontend**: Hotwire (Turbo + Stimulus), Tailwind CSS with DaisyUI
- **Testing**: Minitest, Capybara, Selenium WebDriver
- **Asset Pipeline**: Propshaft

## Development Workflow

This project follows Test-Driven Development (TDD):

1. Write failing test first
2. Implement minimal code to pass
3. Refactor while keeping tests green
4. Run full test suite
5. Check code style with Rubocop

## Common Commands

```bash
rails server                  # Start server
rails console                 # Interactive console
rails test                    # Run tests
rails routes                  # Show all routes
rails db:migrate              # Run migrations
rails db:reset                # Drop, create, migrate, seed
```

## Documentation

- Feature Spec: `specs/001-an-app-which/spec.md`
- Data Model: `specs/001-an-app-which/data-model.md`
- Implementation Plan: `specs/001-an-app-which/plan.md`
- Quickstart Guide: `specs/001-an-app-which/quickstart.md`

## License

All rights reserved.
