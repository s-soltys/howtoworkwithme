# API Contract: ResponsesController

**Feature**: 002-more-input-methods
**Controller**: `app/controllers/responses_controller.rb`
**Purpose**: Handle question navigation and answer persistence for all question types

---

## Existing Routes (Unchanged)

```ruby
resources :responses, param: :unique_token, only: [:edit, :update] do
  member do
    post :submit
  end
end
```

**Paths**:
- `edit_response_path(@response.unique_token)` - GET `/responses/:unique_token/edit`
- `response_path(@response.unique_token)` - PATCH `/responses/:unique_token`
- `submit_response_path(@response.unique_token)` - POST `/responses/:unique_token/submit`

---

## Action: `#edit`

**Purpose**: Display current question in questionnaire flow

**Method**: GET
**Path**: `/responses/:unique_token/edit`
**Auth**: None (token-based access)

### Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| unique_token | String | Yes | Response unique token (in path) |
| question_id | Integer | No | Specific question ID to display (default: first unanswered) |

### Response

**Success (200 OK)**:
```erb
<!-- Renders: app/views/responses/edit.html.erb -->
<!-- Contains Turbo Frame with current question -->

<turbo-frame id="question_<%= @question.id %>">
  <!-- Question content rendered via partial based on type -->
  <%= render partial: "responses/question_types/#{@question.question_type}",
             locals: { question: @question, answer: @answer, response: @response } %>
</turbo-frame>
```

**Not Found (404)**:
- Response with unique_token not found
- Question not found in questionnaire

**Redirect (302)**:
- If response already submitted → redirect to `profile_path(@response.profile.unique_token)`

### Instance Variables

```ruby
@response # Response record
@questionnaire # Parent questionnaire
@question # Current question to display
@answer # Answer record (may be new or existing)
@progress # { current: 5, total: 20, percentage: 25 }
@navigation # { prev_question_id: 4, next_question_id: 6 }
```

---

## Action: `#update`

**Purpose**: Save answer and navigate to next/previous question

**Method**: PATCH
**Path**: `/responses/:unique_token`
**Auth**: None (token-based access)

### Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| unique_token | String | Yes | Response unique token (in path) |
| question_id | Integer | Yes | Question being answered |
| direction | String | No | Navigation: "next" or "previous" (default: "next") |
| answer | Hash | Yes (if answering) | Answer data (structure varies by question type) |

### Answer Parameter Structures by Question Type

#### 1. Slider
```ruby
{
  answer: {
    question_id: 123,
    numeric_value: 7
  }
}
```

#### 2. Swipe Yes/No
```ruby
{
  answer: {
    question_id: 123,
    boolean_value: true  # true = yes (right swipe), false = no (left swipe)
  }
}
```

#### 3. Card Sort
```ruby
{
  answer: {
    question_id: 123,
    jsonb_value: {
      ranked: [
        { id: "card-2", rank: 1 },
        { id: "card-1", rank: 2 },
        { id: "card-5", rank: 3 }
      ],
      unranked: ["card-3", "card-4"]
    }
  }
}
```

#### 4. Energy Map
```ruby
{
  answer: {
    question_id: 123,
    jsonb_value: {
      data_points: [
        { period: "Monday Morning", value: 7 },
        { period: "Monday Afternoon", value: 5 },
        { period: "Tuesday Morning", value: null },  # Empty allowed per FR-013
        { period: "Tuesday Afternoon", value: 8 }
      ]
    }
  }
}
```

#### 5. Emoji Reaction
```ruby
{
  answer: {
    question_id: 123,
    jsonb_value: {
      emoji: "😍",
      label: "Love it",
      value: 5
    }
  }
}
```

#### 6. Character Sheet
```ruby
{
  answer: {
    question_id: 123,
    jsonb_value: {
      allocations: {
        "leadership": 5,
        "technical": 8,
        "creative": 3,
        "communication": 4
      },
      total_allocated: 20
    }
  }
}
```

### Strong Parameters

```ruby
def answer_params
  params.require(:answer).permit(
    :question_id,
    :text_value,
    :selected_option_id,
    :boolean_value,
    :numeric_value,
    selected_option_ids: [],
    jsonb_value: {}
  )
end
```

### Response

**Success - Next Question (200 OK with Turbo Stream)**:
```ruby
# Format: turbo_stream
# Replaces question frame with next question
turbo_stream.replace "question_#{@next_question.id}", partial: "..."
turbo_stream.update "progress_bar", partial: "..."
```

**Success - Last Question (302 Redirect)**:
```ruby
# Redirect to: edit_response_path(direction: 'submit_prompt')
# Shows "Review & Submit" page
```

**Success - Previous Question (200 OK with Turbo Stream)**:
```ruby
# Similar to next, but loads previous question
turbo_stream.replace "question_#{@prev_question.id}", partial: "..."
```

**Validation Error (422 Unprocessable Entity)**:
```ruby
# Format: turbo_stream
# Returns error alert + current question form with errors
turbo_stream.update "flash_messages", html: "<div class='alert alert-error'>...</div>"
turbo_stream.replace "question_form", partial: "..."
```

**Example Validation Errors**:
- Slider: "Numeric value must be between 1 and 10"
- Card Sort: "Contains invalid card IDs: card-99"
- Character Sheet: "Must allocate all 20 points (currently allocated: 18)"
- Energy Map: "Energy value 15 for Monday Morning must be between 0 and 10"

---

## Action: `#submit`

**Purpose**: Finalize response and generate profile

**Method**: POST
**Path**: `/responses/:unique_token/submit`
**Auth**: None (token-based access)

### Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| unique_token | String | Yes | Response unique token (in path) |

### Response

**Success (302 Redirect)**:
```ruby
# Redirect to: profile_path(@response.profile.unique_token)
flash[:success] = "Your profile has been generated!"
```

**Validation Error (422 Unprocessable Entity)**:
- Missing required answers
- Invalid answer data (failed model validations)

**Not Found (404)**:
- Response not found or already submitted

---

## Service Objects

### Responses::SaveAnswer

**Purpose**: Persist answer with appropriate validations

**Location**: `app/services/responses/save_answer.rb`

**Interface**:
```ruby
result = Responses::SaveAnswer.call(
  response: @response,
  question: @question,
  answer_params: answer_params
)

if result.success?
  @answer = result.answer
else
  @errors = result.errors
end
```

**Logic**:
1. Find or initialize Answer record for (response_id, question_id)
2. Clear unused value fields based on question type
3. Assign value to appropriate field (numeric_value, boolean_value, jsonb_value, etc.)
4. Validate answer matches question type and settings
5. Save and return result

### Responses::ValidateCharacterSheet

**Purpose**: Client-side and server-side validation for character sheet point allocation

**Location**: `app/services/responses/validate_character_sheet.rb`

**Interface**:
```ruby
result = Responses::ValidateCharacterSheet.call(
  question: @question,
  allocations: params[:answer][:jsonb_value][:allocations]
)

if result.valid?
  # Proceed with save
else
  render json: { errors: result.errors }, status: :unprocessable_entity
end
```

**Validation Rules** (per FR-018, FR-020):
1. All points must be allocated (total_allocated == total_points)
2. Each stat allocation within min/max bounds
3. No negative allocations
4. All stat IDs exist in question.settings.stats
5. No missing stat allocations

---

## Turbo Frame Naming Conventions

| Frame ID | Purpose |
|----------|---------|
| `question_#{@question.id}` | Individual question content |
| `progress_bar` | Progress indicator (X of Y questions) |
| `navigation_buttons` | Next/Previous/Submit buttons |
| `flash_messages` | Success/error notifications |

---

## Error Handling

### Common Error Scenarios

1. **Invalid Answer Data**
   - Status: 422 Unprocessable Entity
   - Response: Turbo Stream with error alert + form

2. **Question Not Found**
   - Status: 404 Not Found
   - Response: Redirect to first question in questionnaire

3. **Response Already Submitted**
   - Status: 302 Redirect
   - Redirect to: profile_path

4. **Missing Required Answer**
   - Status: 422 Unprocessable Entity
   - Message: "This question is required"

5. **Validation Failures** (see data-model.md for full list)
   - Status: 422 Unprocessable Entity
   - Messages: Specific to question type and validation rule

---

## Examples

### Example 1: Save Slider Answer and Navigate Next

**Request**:
```http
PATCH /responses/abc123xyz/edit
Content-Type: application/x-www-form-urlencoded
X-CSRF-Token: [token]

answer[question_id]=45&
answer[numeric_value]=7&
direction=next
```

**Response**:
```http
HTTP/1.1 200 OK
Content-Type: text/vnd.turbo-stream.html

<turbo-stream action="replace" target="question_46">
  <template>
    <!-- Next question HTML -->
  </template>
</turbo-stream>
<turbo-stream action="update" target="progress_bar">
  <template>
    <span>Question 5 of 20</span>
  </template>
</turbo-stream>
```

### Example 2: Save Character Sheet with Validation Error

**Request**:
```http
PATCH /responses/abc123xyz/edit
Content-Type: application/json
X-CSRF-Token: [token]

{
  "answer": {
    "question_id": 47,
    "jsonb_value": {
      "allocations": {
        "leadership": 5,
        "technical": 8,
        "creative": 3
      },
      "total_allocated": 16
    }
  }
}
```

**Response**:
```http
HTTP/1.1 422 Unprocessable Entity
Content-Type: text/vnd.turbo-stream.html

<turbo-stream action="update" target="flash_messages">
  <template>
    <div class="alert alert-error">
      <span>Must allocate all 20 points (currently allocated: 16)</span>
    </div>
  </template>
</turbo-stream>
```

### Example 3: Save Energy Map with Partial Data (Valid per FR-013)

**Request**:
```http
PATCH /responses/abc123xyz/edit
Content-Type: application/json
X-CSRF-Token: [token]

{
  "answer": {
    "question_id": 48,
    "jsonb_value": {
      "data_points": [
        { "period": "Monday Morning", "value": 7 },
        { "period": "Monday Afternoon", "value": null },
        { "period": "Tuesday Morning", "value": 5 }
      ]
    }
  },
  "direction": "next"
}
```

**Response**:
```http
HTTP/1.1 200 OK
Content-Type: text/vnd.turbo-stream.html

<!-- Successfully saved with null values, navigates to next question -->
```

---

## Testing Requirements

### Controller Tests

**File**: `test/controllers/responses_controller_test.rb`

**New Tests Required**:
1. `test "should save slider answer and navigate to next question"`
2. `test "should save swipe yes/no answer"`
3. `test "should save card sort with partial ranking"`
4. `test "should save energy map with null periods"`
5. `test "should save emoji reaction"`
6. `test "should reject character sheet with incomplete allocation"`
7. `test "should accept character sheet with full allocation"`
8. `test "should validate slider value within range"`
9. `test "should validate card sort with invalid card IDs"`
10. `test "should navigate to previous question and load saved answer"`

### System Tests

**Files**: `test/system/*_test.rb` (one per user story)

**Coverage**:
- Full user workflows for each question type (6 user stories)
- Navigation between questions with answer persistence
- Validation error display and recovery
- Touch and mouse interaction simulation (where applicable)
