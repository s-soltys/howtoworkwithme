# Data Model: How to Work With Me App

**Feature**: Employee Questionnaire & Profile Application
**Date**: 2025-10-08
**Branch**: 001-an-app-which

## Overview

The data model centers around a **Questionnaire** structure with hierarchical relationships:

```
Organization → Questionnaire → Category → Question → QuestionOption
                                            ↓
                                Employee → Response → Answer
                                            ↓
                                         Profile
```

## Entity Definitions

### Organization

Represents a company or team using the application.

**Attributes**:
- `id` (integer, primary key)
- `name` (string, not null) - Organization name
- `unique_token` (string, not null, unique, indexed) - For accessing organization dashboard
- `created_at` (datetime)
- `updated_at` (datetime)

**Relationships**:
- Has many `questionnaires`
- Has many `employees`

**Validations**:
- `name` must be present
- `unique_token` must be unique

**Notes**:
- Organization names can be duplicate across the system
- Uses `has_secure_token :unique_token, length: 36` for secure access

---

### Questionnaire

Represents a complete questionnaire configuration for an organization. Contains categories and questions. **Key model per user requirement**.

**Attributes**:
- `id` (integer, primary key)
- `organization_id` (integer, foreign key, not null, indexed)
- `title` (string, not null) - Questionnaire title
- `description` (text, nullable) - Optional description
- `unique_token` (string, not null, unique, indexed) - For employee access link
- `locked_at` (datetime, nullable) - When questionnaire was locked (after first submission)
- `active` (boolean, default: true) - Whether questionnaire is active
- `created_at` (datetime)
- `updated_at` (datetime)

**Relationships**:
- Belongs to `organization`
- Has many `categories` (dependent: destroy, ordered by position)
- Has many `questions` (through categories)
- Has many `responses` (dependent: destroy)

**Validations**:
- `title` must be present
- `unique_token` must be unique
- `organization_id` must be present

**Business Logic**:
- Cannot be edited (categories/questions) once `locked_at` is set (FR-009)
- Locked automatically when first employee submits a completed response
- Generates employee questionnaire link via `unique_token`

**Scopes**:
- `active` - Where active = true
- `locked` - Where locked_at is not null
- `unlocked` - Where locked_at is null

---

### Category

Represents a grouping of related questions (e.g., "Communication Preferences", "Work Style").

**Attributes**:
- `id` (integer, primary key)
- `questionnaire_id` (integer, foreign key, not null, indexed)
- `name` (string, not null) - Category name
- `position` (integer, not null) - Display order
- `created_at` (datetime)
- `updated_at` (datetime)

**Relationships**:
- Belongs to `questionnaire`
- Has many `questions` (dependent: destroy, ordered by position)

**Validations**:
- `name` must be present
- `name` must be unique within the same questionnaire (FR-004)
- `position` must be present and positive integer
- Cannot be modified if questionnaire is locked

**Business Logic**:
- Categories display in order specified by `position`
- Category names must be unique per organization (not globally)

**Indexes**:
- `(questionnaire_id, position)` - For ordered retrieval
- `(questionnaire_id, name)` - For uniqueness validation

---

### Question

Represents a single question in the questionnaire.

**Attributes**:
- `id` (integer, primary key)
- `category_id` (integer, foreign key, not null, indexed)
- `question_type` (string/enum, not null) - Values: `text`, `single_choice`, `multiple_choice`, `yes_no`
- `text` (text, not null) - Question text
- `position` (integer, not null) - Display order within category
- `required` (boolean, default: true) - Whether question must be answered
- `settings` (jsonb, default: {}) - Additional settings (e.g., char limits, scale ranges)
- `created_at` (datetime)
- `updated_at` (datetime)

**Relationships**:
- Belongs to `category`
- Has many `question_options` (dependent: destroy, ordered by position) - Only for choice types
- Has many `answers` (dependent: destroy)

**Validations**:
- `text` must be present
- `question_type` must be one of: `text`, `single_choice`, `multiple_choice`, `yes_no`
- `position` must be present and positive integer
- Choice questions (`single_choice`, `multiple_choice`) must have at least 2 options (FR-006)
- Cannot be modified if questionnaire is locked

**Question Types**:

1. **text**: Free-form text response
   - Max character limit: 1000 characters (FR-012)
   - Stored in `answers.text_value`

2. **single_choice**: Select one option from predefined choices
   - Requires 2+ `question_options`
   - Stored in `answers.selected_option_id`

3. **multiple_choice**: Select multiple options from predefined choices
   - Requires 2+ `question_options`
   - Stored in `answers.selected_option_ids` (PostgreSQL array)

4. **yes_no**: Boolean question
   - No options needed
   - Stored in `answers.boolean_value`

**Indexes**:
- `(category_id, position)` - For ordered retrieval

---

### QuestionOption

Represents a predefined option for multiple choice or single choice questions.

**Attributes**:
- `id` (integer, primary key)
- `question_id` (integer, foreign key, not null, indexed)
- `text` (string, not null) - Option text
- `position` (integer, not null) - Display order
- `created_at` (datetime)
- `updated_at` (datetime)

**Relationships**:
- Belongs to `question`
- Has many `answers` (where selected)

**Validations**:
- `text` must be present
- `position` must be present and positive integer
- Cannot be modified if questionnaire is locked

**Business Logic**:
- Only exists for `single_choice` and `multiple_choice` question types
- Minimum 2 options required per choice question (FR-006)

**Indexes**:
- `(question_id, position)` - For ordered retrieval

---

### Employee

Represents someone filling out the questionnaire. Created when starting a questionnaire.

**Attributes**:
- `id` (integer, primary key)
- `organization_id` (integer, foreign key, not null, indexed)
- `name` (string, not null) - Employee name
- `email` (string, nullable) - Optional email for notifications
- `created_at` (datetime)
- `updated_at` (datetime)

**Relationships**:
- Belongs to `organization`
- Has many `responses` (dependent: destroy)
- Has many `profiles` (through responses)

**Validations**:
- `name` must be present
- `organization_id` must be present

**Business Logic**:
- Name collected via text input during questionnaire start (Assumption 7)
- No authentication in MVP - identified by name only
- Can submit questionnaire multiple times (creates multiple responses)

---

### Response

Represents an employee's submission of a questionnaire. Stores all answers and supports versioning (multiple submissions).

**Attributes**:
- `id` (integer, primary key)
- `questionnaire_id` (integer, foreign key, not null, indexed)
- `employee_id` (integer, foreign key, nullable, indexed)
- `unique_token` (string, not null, unique, indexed) - For accessing/editing draft
- `status` (string/enum, not null, default: 'draft') - Values: `draft`, `submitted`
- `submitted_at` (datetime, nullable) - When response was submitted
- `created_at` (datetime)
- `updated_at` (datetime)

**Relationships**:
- Belongs to `questionnaire`
- Belongs to `employee` (optional: true for anonymous)
- Has many `answers` (dependent: destroy)
- Has one `profile` (dependent: destroy)

**Validations**:
- `unique_token` must be unique
- `status` must be one of: `draft`, `submitted`
- `submitted_at` must be present when status is `submitted`

**Business Logic**:
- Supports draft saving (FR-015, FR-016)
- `unique_token` used for accessing draft and final profile
- Multiple responses per employee/questionnaire allowed (FR-020)
- Most recent submission shown in profile and dashboard (FR-021, FR-025)
- All submissions stored permanently with timestamps (FR-019, FR-020)

**Scopes**:
- `draft` - Where status = 'draft'
- `submitted` - Where status = 'submitted'
- `most_recent_first` - Order by submitted_at DESC
- `for_employee(employee)` - Where employee_id matches
- `for_questionnaire(questionnaire)` - Where questionnaire_id matches

**Indexes**:
- `unique_token` - Unique index for access
- `(questionnaire_id, status)` - For filtering by status
- `(employee_id, questionnaire_id, submitted_at)` - Composite for versioning queries
- `(questionnaire_id, submitted_at)` - For dashboard queries

---

### Answer

Represents an employee's answer to a specific question. Polymorphic storage for different question types.

**Attributes**:
- `id` (integer, primary key)
- `response_id` (integer, foreign key, not null, indexed)
- `question_id` (integer, foreign key, not null, indexed)
- `text_value` (text, nullable) - For `text` question type
- `selected_option_id` (integer, foreign key, nullable) - For `single_choice` type
- `selected_option_ids` (integer array, default: [], nullable) - For `multiple_choice` type (PostgreSQL array)
- `boolean_value` (boolean, nullable) - For `yes_no` type
- `created_at` (datetime)
- `updated_at` (datetime)

**Relationships**:
- Belongs to `response`
- Belongs to `question`
- Belongs to `selected_option` (class_name: 'QuestionOption', optional: true)

**Validations**:
- `question_id` must be unique per `response_id` (one answer per question per response)
- Answer value must match question type:
  - `text` → `text_value` present, max 1000 chars
  - `single_choice` → `selected_option_id` present, must exist in question's options
  - `multiple_choice` → `selected_option_ids` present and not empty, all IDs must exist in question's options
  - `yes_no` → `boolean_value` present

**Business Logic**:
- Polymorphic storage based on question type
- Validation ensures only appropriate field is populated
- For multiple choice, PostgreSQL array with GIN index for fast queries

**Indexes**:
- `(response_id, question_id)` - Unique index, one answer per question
- `selected_option_ids` - GIN index for array queries (PostgreSQL)

---

### Profile

Represents a generated "How to work with me" profile. Links to a specific response submission.

**Attributes**:
- `id` (integer, primary key)
- `response_id` (integer, foreign key, not null, indexed, unique)
- `unique_token` (string, not null, unique, indexed) - Shareable profile link
- `viewed_count` (integer, default: 0) - Analytics: how many times viewed
- `created_at` (datetime)
- `updated_at` (datetime)

**Relationships**:
- Belongs to `response`
- Has one `employee` (through response)
- Has one `questionnaire` (through response)

**Validations**:
- `unique_token` must be unique
- `response_id` must be unique (one profile per response)
- Associated response must have status = 'submitted'

**Business Logic**:
- Generated automatically when response is submitted (FR-018)
- `unique_token` is the shareable link sent to colleagues (FR-021)
- Displays employee's name and all answers organized by category (FR-022, FR-023)
- Publicly accessible to anyone with the link (Assumption 4)
- Returns 404 for invalid/non-existent links (FR-024)

**Scopes**:
- `most_viewed` - Order by viewed_count DESC
- `recent` - Order by created_at DESC

**Indexes**:
- `unique_token` - Unique index for access
- `response_id` - Unique index, one profile per response

---

## Database Schema Summary

### Tables

1. **organizations**
   - Primary entity for companies
   - Has secure unique_token for dashboard access

2. **questionnaires** (KEY MODEL PER REQUIREMENT)
   - Belongs to organization
   - Contains categories and questions
   - Has secure unique_token for employee access
   - Locks when first submission received

3. **categories**
   - Belongs to questionnaire
   - Groups related questions
   - Ordered by position

4. **questions**
   - Belongs to category
   - Four types: text, single_choice, multiple_choice, yes_no
   - Ordered by position within category

5. **question_options**
   - Belongs to question
   - Defines available choices for choice-type questions
   - Ordered by position

6. **employees**
   - Belongs to organization
   - Simple name-based identification (MVP, no auth)

7. **responses**
   - Belongs to questionnaire and employee
   - Status: draft or submitted
   - Supports versioning via submitted_at
   - Has secure unique_token for access

8. **answers**
   - Belongs to response and question
   - Polymorphic storage: text_value, selected_option_id, selected_option_ids (array), boolean_value
   - One answer per question per response

9. **profiles**
   - Belongs to response (one-to-one)
   - Has secure unique_token for sharing
   - Generated on response submission

### Key Indexes

**Performance Indexes**:
- All foreign keys indexed
- `(employee_id, questionnaire_id, submitted_at)` on responses - For versioning
- `(questionnaire_id, submitted_at)` on responses - For dashboard
- `selected_option_ids` GIN index on answers - For array queries
- `(questionnaire_id, name)` on categories - For uniqueness

**Unique Constraints**:
- `unique_token` on organizations, questionnaires, responses, profiles
- `(questionnaire_id, name)` on categories
- `(response_id, question_id)` on answers
- `response_id` on profiles

---

## State Transitions

### Questionnaire States

```
[unlocked] --first_submission--> [locked]
```

- **unlocked**: `locked_at` is null, can edit categories/questions
- **locked**: `locked_at` is set, cannot edit categories/questions (FR-009)

### Response States

```
[draft] --submit--> [submitted]
```

- **draft**: Can be edited, `submitted_at` is null
- **submitted**: Read-only, `submitted_at` is set, profile generated

---

## Data Integrity Rules

### Foreign Key Constraints

All relationships enforced with database foreign keys:
- `questionnaires.organization_id` → `organizations.id`
- `categories.questionnaire_id` → `questionnaires.id`
- `questions.category_id` → `categories.id`
- `question_options.question_id` → `questions.id`
- `employees.organization_id` → `organizations.id`
- `responses.questionnaire_id` → `questionnaires.id`
- `responses.employee_id` → `employees.id` (nullable)
- `answers.response_id` → `responses.id`
- `answers.question_id` → `questions.id`
- `answers.selected_option_id` → `question_options.id` (nullable)
- `profiles.response_id` → `responses.id`

### Cascade Rules

- Delete organization → cascade to questionnaires, employees
- Delete questionnaire → cascade to categories, questions, responses
- Delete category → cascade to questions
- Delete question → cascade to question_options, answers
- Delete response → cascade to answers, profile
- Delete employee → cascade to responses

### Unique Constraints

- Category names unique per questionnaire (not globally)
- One answer per question per response
- One profile per response
- All `unique_token` fields globally unique

---

## Query Patterns

### Most Recent Response per Employee

```ruby
# PostgreSQL DISTINCT ON
Response.from(
  Response.submitted
          .where(questionnaire: questionnaire)
          .select('DISTINCT ON (employee_id) *')
          .order(:employee_id, submitted_at: :desc)
)
```

### Employer Dashboard Data

```ruby
# Eager load to prevent N+1
responses = questionnaire.responses
                         .submitted
                         .includes(employee: [], answers: [:question, :selected_option])
                         .group_by(&:employee_id)
                         .transform_values { |rs| rs.max_by(&:submitted_at) }
```

### Profile Display

```ruby
# Load response with all related data
response = Response.includes(
  questionnaire: { categories: { questions: :question_options } },
  answers: [:question, :selected_option],
  employee: []
).find_by!(unique_token: token)
```

### Draft Restoration

```ruby
# Find most recent draft for employee
Response.draft
        .where(questionnaire: questionnaire, employee: employee)
        .order(updated_at: :desc)
        .first
```

---

## Capacity Planning

### Expected Data Volumes (MVP)

- **Organizations**: Unlimited
- **Questionnaires per org**: 1-5
- **Categories per questionnaire**: 5-10
- **Questions per questionnaire**: 20-30
- **Options per multiple choice question**: 2-10
- **Employees per org**: Up to 100 (SC-005, SC-006)
- **Responses per employee**: 1-3 (versioning)

### Storage Estimates

**Per questionnaire configuration**:
- 1 questionnaire + 5 categories + 25 questions + 100 options ≈ 50KB

**Per response**:
- 1 response + 25 answers + 1 profile ≈ 10KB

**Per organization (100 employees)**:
- Configuration: 50KB
- Responses: 100 × 10KB = 1MB
- **Total per org**: ~1MB

**System capacity** (1000 orgs):
- ~1GB for MVP scale
- Well within SQLite/PostgreSQL capabilities

---

## Performance Requirements

### Query Performance Targets

- Profile link access: <2s (SC-002)
- Employer dashboard load (100 employees): <3s (SC-006)
- Draft save: <500ms
- Questionnaire start: <1s

### Optimization Strategies

1. **Eager Loading**: Prevent N+1 queries with `includes`
2. **Composite Indexes**: Fast versioning queries
3. **GIN Indexes**: Fast array queries for multiple choice
4. **Partial Indexes**: On `status='submitted'` for common queries
5. **Database Connection Pooling**: Handle concurrent users

---

## Security Considerations

### Token-Based Access

- All resources use `has_secure_token` with 36-char tokens
- Tokens are cryptographically secure (SecureRandom.base58)
- Database unique constraints prevent collisions
- HTTPS required in production

### Data Protection

- Strong parameters on all create/update actions
- CSRF protection enabled (Rails default)
- No sensitive data stored (MVP has no auth)
- SQL injection prevented via ActiveRecord

### Privacy

- Profile links are public (anyone with link can view)
- No PII stored beyond name and optional email
- Data retention is indefinite (Assumption 5)

---

## Future Enhancements

### Authentication & Authorization

- Add user authentication (Devise, Doorkeeper, etc.)
- Restrict organization access to authorized users
- Expire or password-protect profile links

### Advanced Features

- Question conditional logic (show Q2 if Q1 = "yes")
- File upload question type
- Rich text formatting for text answers
- Profile link expiration dates
- Analytics dashboard (response rates, completion times)
- Export responses to CSV/Excel
- Team comparison views

### Performance Optimizations

- Cache frequently accessed profiles
- Background job for dashboard data aggregation
- Database read replicas for reporting
- CDN for static assets

---

## Migration Strategy

### Initial Setup

1. Create all tables in single migration (atomic)
2. Add indexes in same migration (fast for empty tables)
3. Seed with sample data for testing

### Future Migrations

- Never edit existing migrations (Constitution Principle VI)
- Add new migrations for schema changes
- Use `change` method for automatic reversibility
- Test migrations on production-like data volumes

---

## References

- Feature Spec: `/specs/001-an-app-which/spec.md`
- Research: `/specs/001-an-app-which/research.md`
- Constitution: `/.specify/memory/constitution.md`
- Rails Associations Guide: https://guides.rubyonrails.org/association_basics.html
- PostgreSQL Arrays: https://guides.rubyonrails.org/active_record_postgresql.html
