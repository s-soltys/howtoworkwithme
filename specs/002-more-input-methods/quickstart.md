# Developer Quickstart: Enhanced Question Input Methods

**Feature**: 002-more-input-methods
**Branch**: `002-more-input-methods`
**Last Updated**: 2025-10-08

## Overview

This guide helps developers implement the six new interactive question input methods: sliders, swipe yes/no, card sorting, energy mapping, emoji reactions, and character sheets.

---

## Prerequisites

- Rails 8.0.3 installed and running
- Database setup completed (`rails db:migrate`)
- Basic familiarity with:
  - Rails models, controllers, views
  - Stimulus.js
  - Turbo Frames & Streams
  - DaisyUI component classes

---

## Quick Start (5 minutes)

### 1. Checkout Feature Branch

```bash
git checkout 002-more-input-methods
```

### 2. Install Dependencies

```bash
# Pin JavaScript libraries via importmap
bin/importmap pin sortablejs                    # Card sorting
bin/importmap pin chart.js                      # Energy mapping
bin/importmap pin chartjs-plugin-dragdata       # Energy mapping

# Install gems (if any new)
bundle install

# Run pending migrations
rails db:migrate
```

### 3. Verify Setup

```bash
# Start development server
bin/dev

# Run tests
rails test

# Check routes
rails routes | grep questions
rails routes | grep responses
```

### 4. Explore Sample Questions

```bash
# Seed database with example questions (optional)
rails db:seed

# Access admin interface
open http://localhost:3000/questionnaires/[token]/edit

# Access employee questionnaire
open http://localhost:3000/responses/[token]/edit
```

---

## Architecture Overview

```
User Answers Question
         ↓
    Turbo Frame (client-side interaction)
         ↓
    Stimulus Controller (validation, animation)
         ↓
    Form Submit (POST/PATCH to ResponsesController)
         ↓
    Service Object (Responses::SaveAnswer)
         ↓
    Answer Model (validation, persistence)
         ↓
    Database (answers table: numeric_value or jsonb_value)
```

---

## Adding a New Question Type (Step-by-Step)

### Example: Adding a "Slider" Question

#### Step 1: Database Migration (if needed)

```bash
# Already done for this feature - numeric_value and jsonb_value fields added
# If adding future types, check if existing fields support your data structure
```

#### Step 2: Update Question Model Enum

**File**: `app/models/question.rb`

```ruby
enum :question_type, {
  text: "text",
  single_choice: "single_choice",
  multiple_choice: "multiple_choice",
  yes_no: "yes_no",
  slider: "slider",  # ← NEW
  # ... other types
}
```

#### Step 3: Add Settings Validation

**File**: `app/models/question.rb`

```ruby
validate :slider_settings_valid, if: :slider?

private

def slider_settings_valid
  return unless settings.present?

  min = settings["min_value"]
  max = settings["max_value"]

  errors.add(:settings, "must include min_value") if min.blank?
  errors.add(:settings, "must include max_value") if max.blank?
  errors.add(:settings, "min_value must be less than max_value") if min && max && min >= max
end
```

#### Step 4: Add Answer Validation

**File**: `app/models/answer.rb`

```ruby
validate :slider_value_valid

private

def slider_value_valid
  return unless question&.slider? && numeric_value.present?

  min = question.settings["min_value"]
  max = question.settings["max_value"]

  if min && numeric_value < min
    errors.add(:numeric_value, "must be at least #{min}")
  end

  if max && numeric_value > max
    errors.add(:numeric_value, "must be at most #{max}")
  end
end
```

#### Step 5: Create Stimulus Controller

**File**: `app/javascript/controllers/slider_controller.js`

```javascript
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["input", "valueDisplay", "label"]
  static values = {
    min: { type: Number, default: 1 },
    max: { type: Number, default: 10 },
    labels: Object
  }

  connect() {
    this.updateDisplay()
  }

  updateDisplay() {
    const value = parseInt(this.inputTarget.value)
    this.valueDisplayTarget.textContent = value

    if (this.labelsValue[value]) {
      this.labelTarget.textContent = this.labelsValue[value]
    }
  }

  save() {
    const value = parseInt(this.inputTarget.value)
    this.dispatch('changed', { detail: { value } })
  }
}
```

#### Step 6: Create View Partial

**File**: `app/views/responses/_question_types/_slider.html.erb`

```erb
<div data-controller="slider"
     data-slider-min-value="<%= question.settings['min_value'] %>"
     data-slider-max-value="<%= question.settings['max_value'] %>"
     data-slider-labels-value='<%= question.settings["labels"].to_json %>'
     data-action="slider:changed->responses#saveAnswer">

  <label class="form-control">
    <div class="label">
      <span class="label-text"><%= question.text %></span>
      <% if question.required? %>
        <span class="label-text-alt text-error">*Required</span>
      <% end %>
    </div>

    <input type="range"
           name="answer[numeric_value]"
           min="<%= question.settings['min_value'] %>"
           max="<%= question.settings['max_value'] %>"
           value="<%= answer.numeric_value || question.settings['default_value'] || 5 %>"
           class="range range-primary"
           data-slider-target="input"
           data-action="input->slider#updateDisplay change->slider#save">

    <div class="flex justify-between text-xs px-2 mt-2">
      <span><%= question.settings.dig('labels', '1') || question.settings['min_value'] %></span>
      <span data-slider-target="valueDisplay" class="font-bold text-primary">5</span>
      <span><%= question.settings.dig('labels', question.settings['max_value'].to_s) || question.settings['max_value'] %></span>
    </div>

    <div class="text-center mt-2">
      <span data-slider-target="label" class="badge badge-lg"></span>
    </div>
  </label>
</div>
```

#### Step 7: Create Admin Config Form Partial

**File**: `app/views/questions/_form_fields/_slider_config.html.erb`

```erb
<div class="form-control">
  <%= f.label :settings_min_value, "Minimum Value", class: "label" %>
  <%= f.number_field :settings_min_value,
                     value: @question.settings["min_value"] || 1,
                     class: "input input-bordered" %>
</div>

<div class="form-control">
  <%= f.label :settings_max_value, "Maximum Value", class: "label" %>
  <%= f.number_field :settings_max_value,
                     value: @question.settings["max_value"] || 10,
                     class: "input input-bordered" %>
</div>

<div class="form-control">
  <%= f.label :settings_labels, "Labels (JSON)", class: "label" %>
  <%= f.text_area :settings_labels,
                  value: @question.settings["labels"]&.to_json || '{"1": "Low", "10": "High"}',
                  class: "textarea textarea-bordered",
                  placeholder: '{"1": "Very Low", "5": "Neutral", "10": "Very High"}' %>
  <div class="label">
    <span class="label-text-alt">Format: {"value": "label"}</span>
  </div>
</div>
```

#### Step 8: Update Strong Parameters

**File**: `app/controllers/responses_controller.rb`

```ruby
def answer_params
  params.require(:answer).permit(
    :question_id,
    :text_value,
    :selected_option_id,
    :boolean_value,
    :numeric_value,  # ← For slider (and character sheet stats)
    selected_option_ids: [],
    jsonb_value: {}
  )
end
```

#### Step 9: Write Tests

**File**: `test/system/slider_input_test.rb`

```ruby
require "application_system_test_case"

class SliderInputTest < ApplicationSystemTestCase
  test "user can answer slider question" do
    # Arrange
    @questionnaire = questionnaires(:default)
    @category = @questionnaire.categories.first
    @question = @category.questions.create!(
      text: "How introverted/extroverted are you?",
      question_type: "slider",
      required: true,
      settings: {
        min_value: 1,
        max_value: 10,
        labels: { "1" => "Introvert", "10" => "Extrovert" }
      }
    )
    @response = @questionnaire.responses.create!(unique_token: "test123")

    # Act
    visit edit_response_path(@response.unique_token)

    # Find and interact with slider
    slider = find('input[type="range"]')
    slider.set(7)

    # Assert real-time feedback
    assert_selector '[data-slider-target="valueDisplay"]', text: "7"

    # Submit answer
    click_button "Next"

    # Assert answer saved
    assert_equal 7, @response.answers.find_by(question: @question).numeric_value
  end
end
```

**File**: `test/models/answer_test.rb`

```ruby
test "slider answer validates numeric_value within range" do
  question = questions(:slider_question)
  question.update(settings: { min_value: 1, max_value: 10 })

  answer = Answer.new(
    response: responses(:one),
    question: question,
    numeric_value: 15  # Invalid: exceeds max
  )

  assert_not answer.valid?
  assert_includes answer.errors[:numeric_value], "must be at most 10"
end
```

---

## File Structure Cheatsheet

```
app/
├── models/
│   ├── question.rb                    # Enum + settings validations
│   └── answer.rb                      # Answer value validations
├── controllers/
│   ├── responses_controller.rb        # Save answers, navigation
│   └── questions_controller.rb        # Admin: create/edit questions
├── services/
│   ├── responses/
│   │   ├── save_answer.rb            # Persist answer logic
│   │   └── validate_character_sheet.rb
│   └── questions/
│       └── validate_configuration.rb  # Validate question.settings
├── views/
│   ├── responses/
│   │   ├── edit.html.erb             # Main question page
│   │   └── _question_types/
│   │       ├── _slider.html.erb
│   │       ├── _swipe_yes_no.html.erb
│   │       ├── _card_sort.html.erb
│   │       ├── _energy_map.html.erb
│   │       ├── _emoji_reaction.html.erb
│   │       └── _character_sheet.html.erb
│   └── questions/
│       └── _form_fields/
│           ├── _slider_config.html.erb
│           └── ... (admin config forms)
├── javascript/
│   └── controllers/
│       ├── slider_controller.js
│       ├── swipe_controller.js
│       ├── card_sort_controller.js
│       ├── energy_map_controller.js
│       ├── emoji_reaction_controller.js
│       └── character_sheet_controller.js
└── helpers/
    └── questions_helper.rb

test/
├── models/
│   ├── question_test.rb
│   └── answer_test.rb
├── controllers/
│   ├── responses_controller_test.rb
│   └── questions_controller_test.rb
├── services/
│   ├── responses/
│   │   └── save_answer_test.rb
│   └── questions/
│       └── validate_configuration_test.rb
└── system/
    ├── slider_input_test.rb
    ├── swipe_yes_no_test.rb
    ├── card_sorting_test.rb
    ├── energy_mapping_test.rb
    ├── emoji_reactions_test.rb
    └── character_sheet_test.rb
```

---

## Common Development Tasks

### Task 1: Add a New Stat to Character Sheet Question

**File**: Admin UI (QuestionnairesController#edit)

1. Navigate to questionnaire edit page
2. Find character sheet question
3. Click "Edit Question"
4. Add new stat in settings:
   ```json
   {
     "id": "empathy",
     "label": "Empathy",
     "description": "Understanding and relating to others",
     "min": 0,
     "max": 10
   }
   ```
5. Save question

### Task 2: Debug Answer Validation Failure

**Steps**:
1. Check `rails server` logs for validation errors
2. Open Rails console: `rails console`
3. Inspect answer:
   ```ruby
   answer = Answer.find(123)
   answer.valid?  # => false
   answer.errors.full_messages
   ```
4. Check question settings:
   ```ruby
   answer.question.settings
   ```
5. Verify answer data matches expected structure (see `data-model.md`)

### Task 3: Test Stimulus Controller in Isolation

**File**: Browser DevTools Console

1. Open questionnaire page with target question
2. Open DevTools Console
3. Get controller instance:
   ```javascript
   const element = document.querySelector('[data-controller="slider"]')
   const controller = application.getControllerForElementAndIdentifier(element, 'slider')
   ```
4. Inspect values:
   ```javascript
   controller.minValue  // 1
   controller.maxValue  // 10
   controller.labelsValue  // {1: "Low", 10: "High"}
   ```
5. Trigger actions manually:
   ```javascript
   controller.updateDisplay()
   ```

### Task 4: Add Custom Validation to Question Settings

**Example**: Require at least 5 cards for card_sort questions

**File**: `app/models/question.rb`

```ruby
validate :card_sort_settings_valid, if: :card_sort?

private

def card_sort_settings_valid
  return unless settings.present?

  cards = settings["cards"]
  errors.add(:settings, "must include cards array") if cards.blank?

  # Custom requirement: minimum 5 cards
  if cards && cards.size < 5
    errors.add(:settings, "must have at least 5 cards")
  end

  # Existing validations
  # ...
end
```

### Task 5: Customize DaisyUI Theme for Question Types

**File**: `app/assets/stylesheets/application.tailwind.css`

```css
/* Custom styles for swipe indicators */
.swipe-indicator--yes {
  color: oklch(var(--su));  /* DaisyUI success color */
  font-size: 3rem;
  font-weight: bold;
}

.swipe-indicator--no {
  color: oklch(var(--er));  /* DaisyUI error color */
  font-size: 3rem;
  font-weight: bold;
}

/* Card sort drag preview */
.sortable-ghost {
  opacity: 0.4;
}

.sortable-drag {
  transform: rotate(5deg);
}
```

---

## Testing Strategy

### Unit Tests (Models)

**What to test**:
- Question settings validation for each type
- Answer value validation for each type
- Enum behavior
- Edge cases (min/max boundaries, null values)

**Example**:
```ruby
test "energy map allows null values for periods" do
  answer = answers(:energy_map)
  answer.jsonb_value = {
    data_points: [
      { period: "Monday", value: 7 },
      { period: "Tuesday", value: null }  # Per FR-013
    ]
  }

  assert answer.valid?
end
```

### Integration Tests (Controllers)

**What to test**:
- Answer persistence via POST/PATCH
- Strong parameters filtering
- Turbo Stream responses
- Navigation flow (next/previous)
- Validation error handling

**Example**:
```ruby
test "should save character sheet answer with full allocation" do
  patch response_path(@response.unique_token), params: {
    answer: {
      question_id: @character_sheet_question.id,
      jsonb_value: {
        allocations: { leadership: 5, technical: 10, creative: 5 },
        total_allocated: 20
      }
    }
  }

  assert_response :success
  assert_equal 20, @response.answers.last.jsonb_value["total_allocated"]
end
```

### System Tests (End-to-End)

**What to test**:
- Complete user workflows (User Stories 1-6)
- Touch/mouse interactions (where applicable)
- Visual feedback (animations, real-time updates)
- Error recovery
- Navigation and answer persistence

**Example**:
```ruby
test "user completes card sorting question" do
  visit edit_response_path(@response.unique_token)

  # Drag cards to reorder
  card1 = find('.card', text: 'Work-life balance')
  card2 = find('.card', text: 'Career growth')

  # Simulate drag-and-drop (using Capybara DSL or custom driver)
  card1.drag_to(card2)

  # Click next
  click_button "Next"

  # Assert ranking saved
  answer = @response.answers.find_by(question: @card_sort_question)
  ranked = answer.jsonb_value["ranked"]

  assert_equal "Career growth", ranked[0]["text"]
  assert_equal "Work-life balance", ranked[1]["text"]
end
```

---

## Debugging Tips

### Issue: Stimulus Controller Not Connecting

**Symptoms**: No console logs, actions not firing

**Solutions**:
1. Check controller is registered:
   ```javascript
   // app/javascript/controllers/index.js
   import SliderController from "./slider_controller"
   application.register("slider", SliderController)
   ```

2. Verify `data-controller` attribute:
   ```erb
   <div data-controller="slider">  <!-- Correct -->
   <div data-controller="sliderController">  <!-- Wrong -->
   ```

3. Check browser console for errors:
   - Open DevTools → Console
   - Look for "Error loading controller" messages

### Issue: Answer Validation Failing

**Symptoms**: 422 errors, "Answer is invalid"

**Solutions**:
1. Check `rails server` logs for specific validation errors
2. Use Rails console to debug:
   ```ruby
   answer = Answer.last
   answer.errors.full_messages
   answer.question.settings
   ```
3. Verify answer data structure matches `data-model.md`
4. Check question settings are valid (run validations on question)

### Issue: Turbo Frame Not Updating

**Symptoms**: Form submits but page doesn't change

**Solutions**:
1. Check `data-turbo-frame` attribute matches target frame ID
2. Verify controller responds with `format.turbo_stream`
3. Check browser DevTools → Network tab:
   - Response Content-Type should be `text/vnd.turbo-stream.html`
4. Inspect Turbo Stream response in Network tab

### Issue: JSONB Value Not Saving

**Symptoms**: `jsonb_value` is nil or empty

**Solutions**:
1. Check strong parameters permit `jsonb_value: {}`
2. Ensure nested hash structure is correct:
   ```ruby
   params.require(:answer).permit(jsonb_value: {})  # Permits any hash
   ```
3. Verify JSON is valid (use JSON validator)
4. Check PostgreSQL logs for type errors

---

## Performance Considerations

### Optimize JSONB Queries

**Add GIN Index** (already done in migration):
```ruby
add_index :answers, :jsonb_value, using: :gin
```

**Query Efficiently**:
```ruby
# Find all answers with specific emoji
Answer.where("jsonb_value->>'emoji' = ?", "😍")

# Find character sheets with high leadership
Answer.where("(jsonb_value->'allocations'->>'leadership')::int > 7")
```

### Lazy Load Stimulus Controllers

**File**: `app/javascript/controllers/index.js`

```javascript
// Eager load common controllers
import SliderController from "./slider_controller"
application.register("slider", SliderController)

// Lazy load heavy controllers
application.load("energy-map", () => import("./energy_map_controller"))
application.load("card-sort", () => import("./card_sort_controller"))
```

### Minimize Animation Repaints

**Use CSS Transforms** (GPU-accelerated):
```css
/* Good */
.swipe-card {
  transform: translateX(100px) rotate(10deg);
  transition: transform 0.3s ease-out;
}

/* Bad (triggers layout recalculation) */
.swipe-card {
  left: 100px;
  transition: left 0.3s ease-out;
}
```

---

## Resources

### Documentation

- [Rails Guides](https://guides.rubyonrails.org/)
- [Stimulus Handbook](https://stimulus.hotwired.dev/handbook/introduction)
- [Turbo Handbook](https://turbo.hotwired.dev/handbook/introduction)
- [DaisyUI Components](https://daisyui.com/components/)
- [SortableJS Docs](https://github.com/SortableJS/Sortable)
- [Chart.js Docs](https://www.chartjs.org/docs/latest/)

### Project Files

- [Feature Spec](./spec.md) - Full requirements and user stories
- [Data Model](./data-model.md) - Database schema and validations
- [API Contracts](./contracts/) - Controller actions and parameters
- [Research](./research.md) - Technology decisions and rationale

### Getting Help

1. Check this quickstart guide
2. Review feature spec for requirements
3. Check data-model.md for validation rules
4. Search test files for examples
5. Ask in team chat/stand-up

---

## Next Steps

After completing Phase 1 (Design), proceed to:

1. **Phase 2**: Run `/speckit.tasks` to generate `tasks.md` with implementation checklist
2. **Implementation**: Follow TDD workflow:
   - Write failing test (red)
   - Implement feature (green)
   - Refactor (maintain green tests)
3. **Review**: Check Constitution compliance before PR
4. **Deploy**: Merge to main after all tests pass

---

**Questions?** Refer to the [Feature Spec](./spec.md) or contact the team.
