# Research Findings: How to Work With Me App

**Feature**: Employee Questionnaire & Profile Application
**Date**: 2025-10-08
**Branch**: 001-an-app-which

## Research Questions Resolved

### 1. Testing Framework Decision

**Decision**: Keep Minitest (Rails Default) and Update Constitution

**Rationale**:
- Rails 8.0.3 ships with Minitest fully integrated with zero configuration required
- 20-30% faster test suite runtime compared to RSpec for comparable test counts
- Minitest is "just Ruby" - simpler, more straightforward syntax
- All Rails generators, documentation, and guides assume Minitest
- Project is at the beginning stage - starting with framework defaults follows Rails conventions
- Migration to RSpec would require 3+ hours of work with no clear benefit at MVP stage

**Alternatives Considered**:
- **RSpec**: More expressive BDD syntax, extensive matchers ecosystem
  - Rejected: Additional dependencies, configuration overhead, migration time, slower performance
  - No clear benefit for MVP questionnaire application

**Implementation**:
- Update CLAUDE.md to reflect Minitest usage instead of RSpec
- Use standard Minitest assertions and Rails testing conventions
- Leverage parallel test execution (already configured)
- Optional: Add `minitest-reporters` for better output formatting
- Optional: Add `shoulda-matchers` for RSpec-style matchers in Minitest

---

### 2. Draft Autosave Best Practices

**Decision**: Turbo Streams with Database Storage and Stimulus Controller

**Rationale**:
- **Database storage** ensures persistence across browser sessions and devices
- Questionnaire responses can exceed 4KB session/cookie limits
- **Turbo Streams** provide Rails-native way to handle autosave without full page reloads
- **Stimulus controller** manages client-side logic (debouncing, blur events)
- Visual feedback via Turbo Streams for "Saving..." / "Saved" indicators
- Aligns with Rails 8 Hotwire-first approach

**Alternatives Considered**:
- **Session/Cookie Storage**: Too limited (4KB), doesn't persist across devices
- **LocalStorage**: No cross-device sync, lost if browser data cleared
- **AJAX**: Works but doesn't leverage Rails 8 Hotwire capabilities

**Implementation**:
- Store draft responses in `responses` table with `status: 'draft'`
- Debounce autosave to 2-3 seconds after user stops typing
- Immediate save on blur (when user leaves a field)
- Use `previously_changed?` to avoid unnecessary status updates
- Stimulus controller handles timing, Turbo Streams handle server communication

**UX Pattern**:
```
1. User types → Debounced save (2s after stopping)
2. User leaves field → Immediate save on blur
3. Show "Saving..." spinner → "✓ Saved" confirmation
4. Silent failure handling (show error but don't interrupt)
5. Explicit final submit with confirmation dialog
```

---

### 3. Unique Link Generation

**Decision**: Use Rails `has_secure_token` with 36-Character Base58 Tokens

**Rationale**:
- Built into Rails core since 5.0, actively maintained and well-tested
- Automatic lifecycle management with `regenerate_token` method
- Uses `SecureRandom.base58` for cryptographically secure tokens
- Base58 avoids visual confusion (no 0/O, 1/l) and is URL-safe
- 36 characters provides >200 bits of randomness
- Database unique index provides absolute collision protection

**Alternatives Considered**:
- **SecureRandom.urlsafe_base64**: Manual implementation, no automatic regeneration
- **SecureRandom.hex**: Limited character set, less entropy per character
- **UUID**: 36 characters with dashes, less "clean" looking

**Implementation**:
```ruby
# Model
has_secure_token :unique_token, length: 36

# Migration
add_column :questionnaires, :unique_token, :string, null: false
add_index :questionnaires, :unique_token, unique: true

# Routes
resources :questionnaires, param: :unique_token, only: [:show]
resources :responses, param: :unique_token, only: [:show, :edit, :update]

# Example URLs
https://yourapp.com/questionnaires/kXm3nP9qR7sT2vW8yZ4bC5dF6gH1jK0lM
https://yourapp.com/responses/aB2cD3eF4gH5iJ6kL7mN8oP9qR0sT1uV2w
```

**Security Considerations**:
- Always use HTTPS in production to prevent token interception
- Consider rate limiting on token-based endpoints
- Add `expires_at` column for sensitive questionnaires (future enhancement)
- Log token access for security monitoring
- Use `regenerate_token` if a token is compromised

---

### 4. Multiple Choice Question Storage

**Decision**: Separate Tables for Question Options, PostgreSQL Array for User Selections

**Rationale**:
- **Separate `question_options` table** provides referential integrity and queryability
- Foreign key constraints ensure data consistency
- Easy to add/edit/delete options without JSON manipulation
- **PostgreSQL arrays** for user selections are simple and performant
- GIN indexes on arrays provide 20x faster queries
- Rails has excellent native support for PostgreSQL arrays
- Can validate selections against available options

**Alternatives Considered**:
- **Everything in JSON**: No referential integrity, harder to query
- **Junction table for selections**: Overkill, more complex queries
- **JSON for options, Array for selections**: Can't enforce integrity

**Implementation**:

**Schema**:
```ruby
create_table :question_options do |t|
  t.references :question, null: false, foreign_key: true
  t.string :text, null: false
  t.integer :position, null: false
  t.timestamps
end

create_table :answers do |t|
  t.references :response, null: false, foreign_key: true
  t.references :question, null: false, foreign_key: true
  t.text :text_value # For text questions
  t.integer :selected_option_id # For single choice
  t.integer :selected_option_ids, array: true, default: [] # For multiple choice
  t.integer :scale_value # For scale questions
  t.timestamps
end

# GIN index for fast array queries
add_index :answers, :selected_option_ids, using: :gin
```

**Query Patterns**:
```ruby
# Find answers that selected a specific option
Answer.where("? = ANY(selected_option_ids)", option_id)

# Find answers that selected multiple specific options
Answer.where("selected_option_ids @> ARRAY[?]::integer[]", [option_id_1, option_id_2])
```

---

### 5. Response Versioning

**Decision**: Use Timestamps with Composite Index for Simple Versioning (No Gem)

**Rationale**:
- Start simple: Multiple `Response` records with `submitted_at` timestamps
- Composite index on `(employee_id, questionnaire_id, submitted_at)` makes queries fast
- No external dependencies required
- PaperTrail tracks field-level changes (overkill for submission-level versioning)
- Clear data model: each submission is a distinct record
- Easy to query for most recent submission

**Alternatives Considered**:
- **PaperTrail gem**: Overkill for simple submission tracking, adds complexity
- **Soft delete**: Clutters main table, hard to query all versions
- **Custom versioning table**: Reinventing the wheel

**Implementation**:

**Schema**:
```ruby
create_table :responses do |t|
  t.references :questionnaire, null: false, foreign_key: true
  t.references :employee, foreign_key: true
  t.string :unique_token, null: false
  t.string :status, default: 'draft', null: false
  t.datetime :submitted_at
  t.timestamps
end

# Critical indexes for versioning
add_index :responses, [:employee_id, :questionnaire_id, :submitted_at]
add_index :responses, [:questionnaire_id, :submitted_at]
```

**Query Patterns**:
```ruby
# Most recent submission for employee/questionnaire
Response.submitted
        .where(employee: employee, questionnaire: questionnaire)
        .order(submitted_at: :desc)
        .limit(1)
        .take

# All submissions for analytics
Response.submitted
        .where(questionnaire: questionnaire)
        .order(submitted_at: :desc)

# Most recent submission per employee (PostgreSQL DISTINCT ON)
Response.from(
  Response.submitted
          .where(questionnaire: questionnaire)
          .select('DISTINCT ON (employee_id) *')
          .order(:employee_id, submitted_at: :desc)
)
```

**When to Upgrade to PaperTrail**:
- Need field-level auditing (track which specific fields changed)
- Need rollback capability (restore to previous state)
- Regulatory compliance requirements
- Multi-user edit scenarios requiring user attribution

For MVP questionnaire app tracking complete submissions over time, timestamps are sufficient.

---

## Technology Stack Decisions

### Database
- **Development/Test**: SQLite3 (already configured)
- **Production**: PostgreSQL (for array support, GIN indexes, better performance at scale)
- **Migration needed**: Add PostgreSQL to Gemfile for production environment

### Testing
- **Framework**: Minitest (Rails default)
- **System Tests**: Capybara + Selenium WebDriver (already configured)
- **Additional gems** (optional):
  - `minitest-reporters` for better output
  - `shoulda-matchers` for cleaner assertions

### Autosave Implementation
- **Frontend**: Stimulus controller for debouncing and blur events
- **Backend**: Turbo Streams for server communication
- **Storage**: Database (responses table with draft status)
- **Debounce**: 2-3 seconds after typing stops
- **Visual feedback**: "Saving..." spinner → "✓ Saved"

### Security
- **Link generation**: `has_secure_token` with 36-char base58 tokens
- **Transport**: HTTPS required in production
- **Rate limiting**: Consider for token-based endpoints (future enhancement)
- **Token length**: 36 characters provides >200 bits of randomness

---

## Performance Considerations

### Database Indexes
- **Foreign keys**: All relationships indexed
- **Unique constraints**: On category names per organization, token uniqueness
- **Composite indexes**: For versioning queries (employee_id, questionnaire_id, submitted_at)
- **GIN indexes**: On array columns for fast contains/overlap queries
- **Partial indexes**: On status='submitted' for common queries

### Query Optimization
- Use `includes` to prevent N+1 queries on employer dashboard
- Use `limit(1).take` instead of `first` for single-record queries
- Use `previously_changed?` to avoid unnecessary updates
- Use `DISTINCT ON` for "most recent per employee" queries

### Expected Performance
- Profile links: <2s load time (with proper eager loading)
- Employer dashboard: 100 employees without pagination
- Autosave: Debounced to avoid database hammering
- Questionnaire completion: <10 minutes for 20 questions

---

## Action Items from Research

1. **Update Constitution (CLAUDE.md)**:
   - Change RSpec references to Minitest
   - Update test command examples
   - Keep TDD principles intact

2. **Update Technical Context in plan.md**:
   - Resolve "NEEDS CLARIFICATION" on testing framework → Minitest
   - Resolve production database → PostgreSQL with array support
   - Document autosave approach → Turbo Streams + Stimulus

3. **Database Migration Planning**:
   - Design schema with PostgreSQL arrays in mind
   - Plan composite indexes for versioning
   - Add GIN indexes for array queries

4. **Implement Core Patterns**:
   - `has_secure_token` for all linkable resources
   - Turbo Streams for autosave
   - Stimulus controller for debouncing
   - Separate tables for question options

---

## Dependencies to Add

```ruby
# Gemfile additions needed

# PostgreSQL for production
gem 'pg', '~> 1.1', groups: [:production]

# Optional testing enhancements
group :test do
  gem 'minitest-reporters'
  gem 'shoulda-matchers'
end
```

---

## References

- Rails 8.0.3 Guides: https://guides.rubyonrails.org/
- Hotwire Documentation: https://hotwired.dev/
- PostgreSQL Arrays in Rails: https://guides.rubyonrails.org/active_record_postgresql.html
- has_secure_token: https://api.rubyonrails.org/classes/ActiveRecord/SecureToken/ClassMethods.html
- Minitest Documentation: https://github.com/minitest/minitest
