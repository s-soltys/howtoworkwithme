# API Contract: QuestionsController (Admin)

**Feature**: 002-more-input-methods
**Controller**: `app/controllers/questions_controller.rb`
**Purpose**: Create and configure questions with new input types (admin functionality)

---

## Existing Routes (Extended)

```ruby
resources :categories, only: [:update, :destroy] do
  resources :questions, only: [:create]
end

resources :questions, only: [:update, :destroy]
```

**Paths**:
- `category_questions_path(@category)` - POST `/categories/:category_id/questions`
- `question_path(@question)` - PATCH `/questions/:id`
- `question_path(@question)` - DELETE `/questions/:id`

---

## Action: `#create`

**Purpose**: Create new question with configured input method

**Method**: POST
**Path**: `/categories/:category_id/questions`
**Auth**: None (MVP - no auth system yet)

### Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| category_id | Integer | Yes | Parent category ID (in path) |
| question | Hash | Yes | Question attributes |

### Question Parameter Structure

```ruby
params.require(:question).permit(
  :text,
  :question_type,
  :required,
  :position,
  settings: {},
  question_options_attributes: [:id, :text, :position, :_destroy]
)
```

### Settings Schema by Question Type

#### 1. Slider

```ruby
{
  question: {
    text: "How introverted or extroverted are you?",
    question_type: "slider",
    required: true,
    settings: {
      min_value: 1,
      max_value: 10,
      step: 1,
      labels: {
        "1": "Very Introverted",
        "5": "Balanced",
        "10": "Very Extroverted"
      },
      default_value: 5
    }
  }
}
```

#### 2. Swipe Yes/No

```ruby
{
  question: {
    text: "Do you prefer working independently?",
    question_type: "swipe_yes_no",
    required: true,
    settings: {
      swipe_threshold: 0.3,
      positive_label: "Yes, I prefer solo work",
      negative_label: "No, I prefer collaboration",
      animation_duration: 300
    }
  }
}
```

#### 3. Card Sort

```ruby
{
  question: {
    text: "Rank these work values from most to least important to you:",
    question_type: "card_sort",
    required: true,
    settings: {
      cards: [
        { id: "work-life-balance", text: "Work-life balance", description: "Flexible hours and time off" },
        { id: "career-growth", text: "Career growth", description: "Promotion opportunities" },
        { id: "compensation", text: "Competitive compensation" },
        { id: "team-culture", text: "Positive team culture" },
        { id: "challenging-work", text: "Challenging projects" }
      ],
      allow_partial_ranking: true
    }
  }
}
```

#### 4. Energy Map

```ruby
{
  question: {
    text: "Map your typical energy levels throughout a work week:",
    question_type: "energy_map",
    required: true,
    settings: {
      time_periods: [
        "Monday Morning", "Monday Afternoon",
        "Tuesday Morning", "Tuesday Afternoon",
        "Wednesday Morning", "Wednesday Afternoon",
        "Thursday Morning", "Thursday Afternoon",
        "Friday Morning", "Friday Afternoon"
      ],
      scale_min: 0,
      scale_max: 10,
      scale_labels: {
        "0": "Exhausted",
        "5": "Moderate Energy",
        "10": "Highly Energized"
      },
      y_axis_label: "Energy Level",
      allow_partial: true
    }
  }
}
```

#### 5. Emoji Reaction

```ruby
{
  question: {
    text: "How do you feel about frequent meetings?",
    question_type: "emoji_reaction",
    required: true,
    settings: {
      emoji_options: [
        { emoji: "😍", label: "Love them!", value: 5 },
        { emoji: "😊", label: "They're helpful", value: 4 },
        { emoji: "😐", label: "Neutral", value: 3 },
        { emoji: "😕", label: "Not a fan", value: 2 },
        { emoji: "😤", label: "Waste of time", value: 1 }
      ]
    }
  }
}
```

#### 6. Character Sheet

```ruby
{
  question: {
    text: "Allocate 20 points across these work style attributes:",
    question_type: "character_sheet",
    required: true,
    settings: {
      total_points: 20,
      stats: [
        {
          id: "leadership",
          label: "Leadership",
          description: "Guiding teams and making strategic decisions",
          min: 0,
          max: 10
        },
        {
          id: "technical",
          label: "Technical Skills",
          description: "Coding, system design, and technical problem-solving",
          min: 0,
          max: 10
        },
        {
          id: "creative",
          label: "Creativity",
          description: "Innovative thinking and novel solutions",
          min: 0,
          max: 10
        },
        {
          id: "communication",
          label: "Communication",
          description: "Written and verbal communication skills",
          min: 0,
          max: 10
        }
      ],
      require_full_allocation: true
    }
  }
}
```

### Response

**Success (201 Created with Turbo Stream)**:
```ruby
# Format: turbo_stream
turbo_stream.prepend "questions_list", partial: "questions/question", locals: { question: @question }
turbo_stream.update "flash_messages", partial: "shared/flash", locals: { notice: "Question added successfully" }
```

**Success (Redirect - non-Turbo)**:
```ruby
# Status: 302 Found
# Redirect to: edit_questionnaire_path(@questionnaire)
flash[:notice] = "Question added successfully"
```

**Validation Error (422 Unprocessable Entity)**:
```ruby
# Format: turbo_stream or HTML
# Renders form with errors
render :new, status: :unprocessable_entity
```

**Example Validation Errors**:
- "Text can't be blank"
- "Question type can't be blank"
- "Settings must include min_value" (slider)
- "Settings must have between 3 and 15 cards" (card_sort)
- "Settings must have between 3 and 10 emoji options" (emoji_reaction)
- "Settings: total_points must be between 10 and 100" (character_sheet)

---

## Action: `#update`

**Purpose**: Update existing question configuration

**Method**: PATCH
**Path**: `/questions/:id`
**Auth**: None (MVP - no auth system yet)

### Parameters

Same structure as `#create`, but with `id` in path.

### Additional Constraints

1. **Cannot change question_type** if answers exist:
   ```ruby
   if @question.answers.any? && @question.question_type_changed?
     errors.add(:question_type, "cannot be changed after responses have been recorded")
   end
   ```

2. **Cannot modify if questionnaire is locked**:
   ```ruby
   if @question.questionnaire.locked?
     errors.add(:base, "Cannot modify question when questionnaire is locked")
   end
   ```

### Response

**Success (200 OK with Turbo Stream)**:
```ruby
turbo_stream.replace "question_#{@question.id}", partial: "questions/question", locals: { question: @question }
turbo_stream.update "flash_messages", html: "<div class='alert alert-success'>Question updated</div>"
```

**Validation Error (422 Unprocessable Entity)**:
```ruby
render :edit, status: :unprocessable_entity
```

---

## Action: `#destroy`

**Purpose**: Delete question (only if no answers exist)

**Method**: DELETE
**Path**: `/questions/:id`
**Auth**: None (MVP - no auth system yet)

### Response

**Success (200 OK with Turbo Stream)**:
```ruby
turbo_stream.remove "question_#{@question.id}"
turbo_stream.update "flash_messages", html: "<div class='alert alert-success'>Question deleted</div>"
```

**Conflict (422 Unprocessable Entity)**:
```ruby
# If answers exist
flash[:error] = "Cannot delete question with existing responses"
render turbo_stream: turbo_stream.update("flash_messages", html: "<div class='alert alert-error'>#{flash[:error]}</div>")
```

---

## Service Objects

### Questions::ValidateConfiguration

**Purpose**: Validate question.settings JSONB for each question type

**Location**: `app/services/questions/validate_configuration.rb`

**Interface**:
```ruby
result = Questions::ValidateConfiguration.call(
  question_type: params[:question][:question_type],
  settings: params[:question][:settings]
)

if result.valid?
  @question.settings = result.normalized_settings
else
  @errors = result.errors
end
```

**Validation Rules** (see data-model.md for complete list):

**Slider**:
- `min_value` and `max_value` required
- `min_value < max_value`
- `step > 0`
- `labels` is a Hash (optional)

**Swipe Yes/No**:
- `swipe_threshold` between 0.1 and 0.9
- `positive_label` and `negative_label` present (strings)
- `animation_duration` between 100 and 1000ms

**Card Sort**:
- `cards` array with 3-15 elements
- Each card has unique `id` and `text`
- Card IDs are URL-safe strings

**Energy Map**:
- `time_periods` array with 3-24 elements
- `scale_min < scale_max`
- `time_periods` are unique strings

**Emoji Reaction**:
- `emoji_options` array with 3-10 elements
- Each option has `emoji` and `label`
- Emojis are unique
- Optional `value` is integer

**Character Sheet**:
- `total_points` between 10-100
- `stats` array with 3-10 elements
- Each stat has unique `id`, `label`, `description`
- Each stat has `min` and `max` (default 0-10)
- Sum of all stat `max` values >= `total_points`

---

## View Partials for Question Configuration

### Form Partials

**Location**: `app/views/questions/_form_fields/`

Each question type has a dedicated form partial for admin configuration:

1. `_slider_config.html.erb`
   - Min/max value inputs
   - Step size selector
   - Label configuration (key-value pairs)

2. `_swipe_yes_no_config.html.erb`
   - Threshold slider
   - Positive/negative label inputs
   - Animation duration selector

3. `_card_sort_config.html.erb`
   - Dynamic card list with add/remove
   - Card text and description inputs
   - Sortable preview (using SortableJS)
   - Partial ranking toggle

4. `_energy_map_config.html.erb`
   - Time period configuration (add/remove)
   - Scale min/max inputs
   - Scale label configuration
   - Y-axis label input

5. `_emoji_reaction_config.html.erb`
   - Emoji picker for each option
   - Label input
   - Optional numeric value
   - Preview of emoji row

6. `_character_sheet_config.html.erb`
   - Total points input
   - Stat list with add/remove
   - Stat name, description, min/max inputs
   - Validation: sum of max >= total_points

### Dynamic Form Loading

```erb
<!-- app/views/questions/_form.html.erb -->
<%= form_with model: [@category, @question], data: { controller: "question-form" } do |f| %>
  <%= f.text_area :text, class: "textarea textarea-bordered", required: true %>

  <%= f.select :question_type,
               Question.question_types.keys,
               {},
               {
                 class: "select select-bordered",
                 data: { action: "change->question-form#loadConfigFields" }
               } %>

  <div id="question_config_fields" data-question-form-target="configFields">
    <!-- Dynamically loaded based on question_type -->
    <%= render "questions/form_fields/#{@question.question_type}_config", f: f if @question.question_type.present? %>
  </div>

  <%= f.check_box :required, class: "checkbox checkbox-primary" %>
  <%= f.label :required, "Required question", class: "label-text" %>

  <%= f.submit "Save Question", class: "btn btn-primary" %>
<% end %>
```

**Stimulus Controller** (`app/javascript/controllers/question_form_controller.js`):
```javascript
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["configFields"]

  async loadConfigFields(event) {
    const questionType = event.target.value
    if (!questionType) return

    const response = await fetch(`/questions/config_fields?type=${questionType}`, {
      headers: { "Accept": "text/html" }
    })

    if (response.ok) {
      const html = await response.text()
      this.configFieldsTarget.innerHTML = html
    }
  }
}
```

---

## Additional Route (for Dynamic Form Loading)

```ruby
# config/routes.rb
resources :questions, only: [:update, :destroy] do
  collection do
    get :config_fields  # Returns partial HTML for question type config
  end
end
```

**Action**: `QuestionsController#config_fields`

**Purpose**: Return HTML partial for question type configuration form

**Parameters**:
- `type` (String): Question type enum value

**Response**:
```ruby
# GET /questions/config_fields?type=slider
render partial: "questions/form_fields/slider_config", locals: { f: form_builder }
```

---

## Testing Requirements

### Controller Tests

**File**: `test/controllers/questions_controller_test.rb`

**New Tests Required**:
1. `test "should create slider question with valid settings"`
2. `test "should reject slider question with invalid min/max"`
3. `test "should create card sort question with 5 cards"`
4. `test "should reject card sort with only 2 cards"`
5. `test "should create character sheet with valid point budget"`
6. `test "should reject character sheet when max sum < total points"`
7. `test "should update emoji reaction question"`
8. `test "should not allow question_type change with existing answers"`
9. `test "should not allow updates when questionnaire locked"`
10. `test "should delete question without answers"`
11. `test "should not delete question with existing answers"`
12. `test "should return config fields partial for question type"`

### Service Tests

**File**: `test/services/questions/validate_configuration_test.rb`

**Coverage**:
- Valid and invalid settings for each question type
- Edge cases (min/max boundaries, array size limits)
- Normalization of settings (e.g., default values)

---

## Example Requests

### Example 1: Create Slider Question

**Request**:
```http
POST /categories/5/questions
Content-Type: application/json
X-CSRF-Token: [token]

{
  "question": {
    "text": "How comfortable are you with public speaking?",
    "question_type": "slider",
    "required": true,
    "settings": {
      "min_value": 1,
      "max_value": 10,
      "step": 1,
      "labels": {
        "1": "Very Uncomfortable",
        "10": "Very Comfortable"
      },
      "default_value": 5
    }
  }
}
```

**Response**:
```http
HTTP/1.1 201 Created
Content-Type: text/vnd.turbo-stream.html

<turbo-stream action="prepend" target="questions_list">
  <template>
    <!-- Question HTML -->
  </template>
</turbo-stream>
```

### Example 2: Create Character Sheet (Invalid - Max Sum Too Low)

**Request**:
```http
POST /categories/5/questions
Content-Type: application/json

{
  "question": {
    "text": "Allocate your skills",
    "question_type": "character_sheet",
    "settings": {
      "total_points": 30,
      "stats": [
        { "id": "coding", "label": "Coding", "description": "...", "min": 0, "max": 5 },
        { "id": "design", "label": "Design", "description": "...", "min": 0, "max": 5 }
      ]
    }
  }
}
```

**Response**:
```http
HTTP/1.1 422 Unprocessable Entity

{
  "errors": {
    "settings": ["total_points (30) exceeds maximum possible allocation (10)"]
  }
}
```

### Example 3: Update Card Sort Question

**Request**:
```http
PATCH /questions/42
Content-Type: application/json
X-CSRF-Token: [token]

{
  "question": {
    "text": "Rank these team values:",
    "settings": {
      "cards": [
        { "id": "transparency", "text": "Transparency" },
        { "id": "autonomy", "text": "Autonomy" },
        { "id": "collaboration", "text": "Collaboration" },
        { "id": "innovation", "text": "Innovation" }
      ],
      "allow_partial_ranking": false
    }
  }
}
```

**Response**:
```http
HTTP/1.1 200 OK
Content-Type: text/vnd.turbo-stream.html

<turbo-stream action="replace" target="question_42">
  <!-- Updated question HTML -->
</turbo-stream>
```
