# API Routes Contract: How to Work With Me App

**Feature**: Employee Questionnaire & Profile Application
**Date**: 2025-10-08
**Branch**: 001-an-app-which
**Architecture**: Server-Rendered Rails Application with Hotwire

## Overview

This application uses traditional Rails routing with server-rendered HTML responses. Turbo Frames and Turbo Streams provide SPA-like interactivity without requiring a JSON API.

## Route Patterns

### Organization Management (Employer)

#### Create Organization
```
POST /organizations
```

**Purpose**: Create a new organization

**Parameters**:
```ruby
{
  organization: {
    name: string (required)
  }
}
```

**Response**: Redirect to organization dashboard
- Success: `302` → `/organizations/:unique_token`
- Validation Error: `422` → Render `new` with errors

---

#### View Organization Dashboard
```
GET /organizations/:unique_token
```

**Purpose**: View organization dashboard with questionnaire configuration and employee responses

**Response**: `200` HTML
- Shows questionnaire configuration UI
- Shows employee responses table (FR-025)
- Links to create/edit categories and questions

---

### Questionnaire Configuration (Employer)

#### Create Questionnaire
```
POST /organizations/:organization_token/questionnaires
```

**Purpose**: Create a questionnaire for the organization

**Parameters**:
```ruby
{
  questionnaire: {
    title: string (required),
    description: text (optional)
  }
}
```

**Response**: Redirect to questionnaire configuration
- Success: `302` → `/questionnaires/:unique_token/edit`
- Validation Error: `422` → Render form with errors

---

#### Edit Questionnaire Configuration
```
GET /questionnaires/:unique_token/edit
```

**Purpose**: Configure questionnaire categories and questions

**Response**: `200` HTML
- Shows all categories and questions
- Forms to add/edit categories and questions
- Generate employee link button
- Locked UI if questionnaire is locked (FR-009)

**Turbo Frame**: `#questionnaire_configuration`

---

#### Generate Employee Link
```
POST /questionnaires/:unique_token/generate_link
```

**Purpose**: Generate unique link for employees to access questionnaire

**Response**:
- Success: `200` Turbo Stream updating link display (FR-010)
- Or: Redirect to questionnaire edit page with link shown

---

### Category Management (Employer)

#### Create Category
```
POST /questionnaires/:questionnaire_token/categories
```

**Purpose**: Add a category to the questionnaire (FR-003)

**Parameters**:
```ruby
{
  category: {
    name: string (required),
    position: integer (optional, auto-calculated if not provided)
  }
}
```

**Response**: Turbo Stream prepending/appending category
- Success: `200` Turbo Stream
- Validation Error: `422` Turbo Stream with error messages
- Locked: `403` Forbidden (if questionnaire locked)

---

#### Update Category
```
PATCH /categories/:id
```

**Purpose**: Update category name or position (FR-008)

**Parameters**:
```ruby
{
  category: {
    name: string (optional),
    position: integer (optional)
  }
}
```

**Response**: Turbo Stream updating category
- Success: `200` Turbo Stream
- Validation Error: `422` Turbo Stream with errors
- Locked: `403` Forbidden (if questionnaire locked)

---

#### Delete Category
```
DELETE /categories/:id
```

**Purpose**: Delete a category and its questions

**Response**: Turbo Stream removing category
- Success: `200` Turbo Stream
- Locked: `403` Forbidden (if questionnaire locked)

---

### Question Management (Employer)

#### Create Question
```
POST /categories/:category_id/questions
```

**Purpose**: Add a question to a category (FR-005)

**Parameters**:
```ruby
{
  question: {
    text: text (required),
    question_type: enum (required), # text, single_choice, multiple_choice, yes_no
    position: integer (optional),
    required: boolean (default: true),
    question_options_attributes: [
      { text: string, position: integer } # For choice types only
    ]
  }
}
```

**Response**: Turbo Stream appending question
- Success: `200` Turbo Stream
- Validation Error: `422` Turbo Stream with errors (e.g., choice questions need 2+ options)
- Locked: `403` Forbidden (if questionnaire locked)

---

#### Update Question
```
PATCH /questions/:id
```

**Purpose**: Update question text, type, or options (FR-008)

**Parameters**:
```ruby
{
  question: {
    text: text (optional),
    position: integer (optional),
    required: boolean (optional),
    question_options_attributes: [
      { id: integer (optional), text: string, position: integer, _destroy: boolean }
    ]
  }
}
```

**Response**: Turbo Stream updating question
- Success: `200` Turbo Stream
- Validation Error: `422` Turbo Stream with errors
- Locked: `403` Forbidden (if questionnaire locked)

---

#### Delete Question
```
DELETE /questions/:id
```

**Purpose**: Delete a question

**Response**: Turbo Stream removing question
- Success: `200` Turbo Stream
- Locked: `403` Forbidden (if questionnaire locked)

---

### Employee Questionnaire Experience

#### View Questionnaire (Employee Entry Point)
```
GET /questionnaires/:unique_token
```

**Purpose**: Display questionnaire landing page for employees (FR-011)

**Response**: `200` HTML
- Shows questionnaire title and description
- "Start Questionnaire" button
- Input for employee name (Assumption 7)

---

#### Start Questionnaire
```
POST /questionnaires/:unique_token/start
```

**Purpose**: Create a draft response and redirect to questionnaire form

**Parameters**:
```ruby
{
  employee_name: string (required)
}
```

**Response**: Redirect to draft response
- Success: `302` → `/responses/:response_token/edit`
- Validation Error: `422` → Render landing page with error

---

#### Fill Questionnaire (Draft)
```
GET /responses/:unique_token/edit
```

**Purpose**: Display questionnaire form for answering questions (FR-011)

**Response**: `200` HTML
- Shows all categories and questions in order
- Form fields based on question types (text, choice, yes/no)
- Autosave enabled via Stimulus controller
- Submit button at bottom

**Turbo Frame**: `#response_form`

---

#### Autosave Draft
```
PATCH /responses/:unique_token
```

**Purpose**: Save draft response (FR-015)

**Parameters**:
```ruby
{
  response: {
    answers_attributes: [
      {
        question_id: integer,
        text_value: text (for text questions),
        selected_option_id: integer (for single_choice),
        selected_option_ids: [integer] (for multiple_choice),
        boolean_value: boolean (for yes_no)
      }
    ]
  }
}
```

**Response**: Turbo Stream updating save status
- Success: `200` Turbo Stream (update "#autosave_status" to "Saved")
- Error: `422` Turbo Stream (update "#autosave_status" to "Error")

**Notes**:
- Debounced on client side (2s after typing stops)
- Immediate save on blur
- Silent partial failures (save what's valid)

---

#### Restore Draft
```
GET /responses/:unique_token/edit
```

**Purpose**: Restore saved draft responses when employee returns (FR-016)

**Response**: `200` HTML
- Pre-fills form with saved draft answers
- Shows "Draft saved on [timestamp]" indicator

---

#### Submit Final Response
```
POST /responses/:unique_token/submit
```

**Purpose**: Submit completed questionnaire and generate profile (FR-017, FR-018)

**Response**: Redirect to profile page
- Success: `302` → `/profiles/:profile_token` with flash message
- Validation Error: `422` → Render edit form with validation errors
- Locks questionnaire if first submission (FR-009)

**Validation**:
- All required questions must be answered (FR-017)
- Answer types must match question types

---

### Profile Sharing

#### View Profile
```
GET /profiles/:unique_token
```

**Purpose**: Display employee's shareable profile (FR-021, FR-022, FR-023)

**Response**: `200` HTML or `404` Not Found
- Shows employee name (FR-022)
- Shows all answers organized by category (FR-023)
- Questions as section headers, answers below
- Returns `404` for invalid/non-existent links (FR-024)

**Format**:
```
[Employee Name]'s Work Profile

Category: Communication Preferences
  Q: How do you prefer to communicate?
  A: Email and Slack

Category: Work Style
  Q: Are you a morning person?
  A: Yes
```

---

### Employer Dashboard

#### View Responses Table
```
GET /questionnaires/:unique_token/responses
```

**Purpose**: Display all employee responses in table format (FR-025, FR-026)

**Response**: `200` HTML
- Table with employees as rows, questions as columns
- Questions grouped/labeled by category (FR-026)
- Shows most recent submission per employee (FR-025)
- Updates in real-time via Turbo Streams (FR-027)

**Turbo Frame**: `#responses_table`

**Table Structure**:
```
| Employee | Category 1: Q1 | Category 1: Q2 | Category 2: Q1 | ... |
|----------|----------------|----------------|----------------|-----|
| Alice    | Answer         | Answer         | Answer         |     |
| Bob      | Answer         | Answer         | Answer         |     |
```

---

## Response Formats

### HTML (Default)
- All routes return server-rendered HTML by default
- Forms use Rails form helpers
- Flash messages for user feedback

### Turbo Stream
- Used for dynamic updates without full page reload
- Enabled via `Accept: text/vnd.turbo-stream.html` header
- Turbo automatically sends this header for form submissions within Turbo Frames

**Turbo Stream Actions**:
- `append` - Add category/question to list
- `prepend` - Add to top of list
- `replace` - Update existing element
- `update` - Update element content
- `remove` - Remove category/question

**Example Turbo Stream Response**:
```erb
<turbo-stream action="append" target="categories">
  <template>
    <%= render partial: "categories/category", locals: { category: @category } %>
  </template>
</turbo-stream>

<turbo-stream action="replace" target="autosave_status">
  <template>
    <span class="text-success">✓ Saved</span>
  </template>
</turbo-stream>
```

---

## HTTP Status Codes

### Success Codes
- `200 OK` - Successful GET, successful Turbo Stream response
- `201 Created` - Resource created (rare, usually redirect instead)
- `302 Found` - Redirect after successful POST/PATCH/DELETE

### Client Error Codes
- `404 Not Found` - Invalid profile link, resource doesn't exist (FR-024)
- `422 Unprocessable Entity` - Validation errors
- `403 Forbidden` - Attempt to edit locked questionnaire (FR-009)

### Server Error Codes
- `500 Internal Server Error` - Unexpected server error

---

## Authentication & Authorization

### MVP (No Authentication)
- All routes publicly accessible via unique tokens
- Security through obscurity (long random tokens)
- No login/logout required

### Token-Based Access Control
- Organizations accessed via `unique_token` in URL
- Questionnaires accessed via `unique_token` in URL
- Responses accessed via `unique_token` in URL
- Profiles accessed via `unique_token` in URL

**Security Notes**:
- Tokens are 36 characters (>200 bits entropy)
- Generated with `SecureRandom.base58`
- HTTPS required in production to prevent token interception
- Consider rate limiting on token-based endpoints

---

## Turbo Frame Targets

### Key Frames
- `#questionnaire_configuration` - Wraps category and question management
- `#response_form` - Wraps questionnaire form for autosave
- `#responses_table` - Wraps employer dashboard table
- `#autosave_status` - Shows "Saving..." / "Saved" indicator

### Dynamic Targets
- `#category_#{category.id}` - Individual category
- `#question_#{question.id}` - Individual question
- `#answer_#{question.id}` - Individual answer field

---

## Error Handling

### Validation Errors (422)
```erb
<turbo-stream action="replace" target="question_form">
  <template>
    <%= form_with model: @question do |f| %>
      <%= render partial: "shared/errors", locals: { object: @question } %>
      <!-- form fields -->
    <% end %>
  </template>
</turbo-stream>
```

### Locked Questionnaire (403)
```ruby
# Controller
if @questionnaire.locked?
  redirect_to questionnaire_path(@questionnaire.unique_token),
              alert: "Cannot edit questionnaire after submissions received"
end
```

### Not Found (404)
```ruby
# Controller
def show
  @profile = Profile.find_by(unique_token: params[:unique_token])

  if @profile.nil?
    render file: "#{Rails.root}/public/404.html", status: :not_found
  end
end
```

---

## Performance Considerations

### Eager Loading
```ruby
# Prevent N+1 queries on dashboard
@responses = @questionnaire.responses
                          .submitted
                          .includes(employee: [], answers: [:question, :selected_option])
```

### Pagination
- Dashboard supports 100 employees without pagination (SC-006)
- Add pagination if exceeding 100 employees in future

### Caching
- Profile pages are good candidates for fragment caching
- Cache key: `profile.cache_key_with_version`

---

## Example Request/Response Flows

### Flow 1: Employee Completes Questionnaire

1. **Access questionnaire**: `GET /questionnaires/kXm3...`
   - Response: 200 HTML (landing page with start button)

2. **Start questionnaire**: `POST /questionnaires/kXm3.../start` with `{ employee_name: "Alice" }`
   - Response: 302 → `/responses/aB2c.../edit`

3. **View form**: `GET /responses/aB2c.../edit`
   - Response: 200 HTML (form with all questions)

4. **Autosave draft** (multiple times): `PATCH /responses/aB2c...` with answers
   - Response: 200 Turbo Stream (update autosave status)

5. **Submit final**: `POST /responses/aB2c.../submit`
   - Response: 302 → `/profiles/xY9z...`

6. **View profile**: `GET /profiles/xY9z...`
   - Response: 200 HTML (shareable profile)

---

### Flow 2: Employer Configures Questionnaire

1. **Create organization**: `POST /organizations` with `{ name: "Acme Corp" }`
   - Response: 302 → `/organizations/oRg1...`

2. **Create questionnaire**: `POST /organizations/oRg1.../questionnaires` with title
   - Response: 302 → `/questionnaires/qSt2.../edit`

3. **Add category**: `POST /questionnaires/qSt2.../categories` with `{ name: "Communication" }`
   - Response: 200 Turbo Stream (append category)

4. **Add question**: `POST /categories/1/questions` with question data
   - Response: 200 Turbo Stream (append question)

5. **Generate link**: `POST /questionnaires/qSt2.../generate_link`
   - Response: 200 Turbo Stream (update link display)

---

### Flow 3: Employer Views Responses

1. **Access dashboard**: `GET /questionnaires/qSt2.../responses`
   - Response: 200 HTML (table with all employee responses)

2. **New submission** (auto-updates via Turbo Streams):
   - After employee submits, Turbo broadcasts update
   - Table row appends/updates automatically (FR-027)

---

## Routes Summary

### Public Routes (Token-Based)
```
GET  /questionnaires/:unique_token           # Landing page
POST /questionnaires/:unique_token/start     # Start questionnaire
GET  /responses/:unique_token/edit           # Edit draft
PATCH/responses/:unique_token                # Autosave draft
POST /responses/:unique_token/submit         # Submit final
GET  /profiles/:unique_token                 # View profile
```

### Organization/Employer Routes (Token-Based)
```
POST   /organizations                                   # Create organization
GET    /organizations/:unique_token                     # Dashboard
POST   /organizations/:org_token/questionnaires         # Create questionnaire
GET    /questionnaires/:unique_token/edit               # Configure
POST   /questionnaires/:unique_token/generate_link      # Generate employee link
GET    /questionnaires/:unique_token/responses          # Responses table
POST   /questionnaires/:quest_token/categories          # Create category
PATCH  /categories/:id                                  # Update category
DELETE /categories/:id                                  # Delete category
POST   /categories/:category_id/questions               # Create question
PATCH  /questions/:id                                   # Update question
DELETE /questions/:id                                   # Delete question
```

---

## Turbo Stream Broadcast Channels

### Real-Time Updates

When an employee submits a response, broadcast update to employer dashboard:

```ruby
# After response submission
Turbo::StreamsChannel.broadcast_append_later_to(
  "questionnaire_#{@questionnaire.id}_responses",
  target: "responses_table_body",
  partial: "responses/response_row",
  locals: { response: @response }
)
```

**Subscription** (in employer dashboard view):
```erb
<%= turbo_stream_from "questionnaire_#{@questionnaire.id}_responses" %>

<div id="responses_table_body">
  <!-- Response rows render here -->
</div>
```

---

## References

- Feature Spec: `/specs/001-an-app-which/spec.md`
- Data Model: `/specs/001-an-app-which/data-model.md`
- Research: `/specs/001-an-app-which/research.md`
- Hotwire Turbo Reference: https://turbo.hotwired.dev/reference/streams
- Rails Routing Guide: https://guides.rubyonrails.org/routing.html
