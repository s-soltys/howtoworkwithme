# Implementation Tasks: Enhanced Question Input Methods

**Feature**: 002-more-input-methods
**Branch**: `002-more-input-methods`
**Generated**: 2025-10-08
**TDD Required**: Yes (per Constitution Principle III)

## Summary

This document outlines implementation tasks for six new interactive question input methods. Tasks are organized by user story priority (P1 → P2 → P3) to enable independent, incremental delivery.

**Total Tasks**: 82
**Parallelizable**: 45 tasks marked [P]
**MVP Scope**: Phase 3 (User Story 1 - Slider) = 13 tasks
**Full Feature**: All 6 user stories

---

## Implementation Strategy

### Delivery Approach
- **MVP**: User Story 1 (Slider - P1) provides immediate value with simplest implementation
- **Increment 1**: Add User Stories 2-3 (Swipe Yes/No, Card Sort - P2)
- **Increment 2**: Add User Stories 4-6 (Energy Map, Emoji, Character Sheet - P3)

### Story Independence
Each user story (Phase 3-8) is independently testable and deployable. Stories share foundational infrastructure (Phase 1-2) but have no inter-story dependencies.

### Parallel Execution
Tasks marked [P] can be executed simultaneously when working in teams or with multiple AI agents.

---

## Phase 1: Setup & Dependencies

**Goal**: Install JavaScript libraries and configure importmap

**Checkpoint**: ✓ JavaScript libraries available in browser console

### T001 [P] - Pin SortableJS for card sorting
**File**: `config/importmap.rb`
```bash
bin/importmap pin sortablejs
```
**Verify**: Check importmap.rb contains sortablejs entry

### T002 [P] - Pin Chart.js for energy mapping
**File**: `config/importmap.rb`
```bash
bin/importmap pin chart.js
```
**Verify**: Check importmap.rb contains chart.js entry

### T003 [P] - Pin chartjs-plugin-dragdata for interactive energy graphs
**File**: `config/importmap.rb`
```bash
bin/importmap pin chartjs-plugin-dragdata
```
**Verify**: Check importmap.rb contains chartjs-plugin-dragdata entry

### T004 - Verify JavaScript imports work
**File**: Browser DevTools Console
```javascript
// Open any page and check console - no import errors
// Sortable, Chart should be available
```
**Verify**: No console errors, libraries load successfully

---

## Phase 2: Foundational Infrastructure

**Goal**: Database schema and base model extensions that ALL user stories depend on

**Checkpoint**: ✓ Migrations run successfully, Question and Answer models support new types

### T005 - Create migration to add new question type enum values
**File**: `db/migrate/YYYYMMDDHHMMSS_add_new_question_input_types.rb`
```ruby
class AddNewQuestionInputTypes < ActiveRecord::Migration[8.0]
  def up
    # Validate existing data
    Question.where.not(question_type: ['text', 'single_choice', 'multiple_choice', 'yes_no']).each do |q|
      raise "Invalid question_type: #{q.question_type} for Question ID #{q.id}"
    end
    # Enum managed in model - this migration is a checkpoint
  end

  def down
    # Remove new question types before rollback
    Question.where(question_type: ['slider', 'swipe_yes_no', 'card_sort', 'energy_map', 'emoji_reaction', 'character_sheet']).destroy_all
  end
end
```
**Verify**: Migration runs without errors

### T006 - Create migration to add numeric_value and jsonb_value fields to answers
**File**: `db/migrate/YYYYMMDDHHMMSS_add_value_fields_to_answers.rb`
```ruby
class AddValueFieldsToAnswers < ActiveRecord::Migration[8.0]
  def change
    add_column :answers, :numeric_value, :integer
    add_column :answers, :jsonb_value, :jsonb, default: {}
    add_index :answers, :jsonb_value, using: :gin
  end
end
```
**Verify**: Migration adds columns and GIN index

### T007 - Run migrations
**Command**: `rails db:migrate`
**Verify**: Schema updated, no errors

### T008 - Update Question model with new enum values
**File**: `app/models/question.rb`
```ruby
enum :question_type, {
  text: "text",
  single_choice: "single_choice",
  multiple_choice: "multiple_choice",
  yes_no: "yes_no",
  slider: "slider",
  swipe_yes_no: "swipe_yes_no",
  card_sort: "card_sort",
  energy_map: "energy_map",
  emoji_reaction: "emoji_reaction",
  character_sheet: "character_sheet"
}
```
**Verify**: Rails console: `Question.question_types.keys` includes all new types

### T009 - Update ResponsesController strong parameters
**File**: `app/controllers/responses_controller.rb`
```ruby
def answer_params
  params.require(:answer).permit(
    :question_id,
    :text_value,
    :selected_option_id,
    :boolean_value,
    :numeric_value,        # NEW for slider
    selected_option_ids: [],
    jsonb_value: {}         # NEW for complex types
  )
end
```
**Verify**: Controller permits new parameters

---

## Phase 3: User Story 1 - Slider (P1)

**Story Goal**: Users can express nuanced opinions on a spectrum using slider inputs with labeled endpoints

**Independent Test**: Create slider question "Introvert (1) to Extrovert (10)", move slider to 7, save answer, verify numeric_value=7 persisted

**Why MVP**: Simplest implementation, provides immediate value for dimensional feedback, uses native HTML5 (0 KB)

### T010 - Write system test for User Story 1
**File**: `test/system/slider_input_test.rb`
```ruby
require "application_system_test_case"

class SliderInputTest < ApplicationSystemTestCase
  test "user can answer slider question with real-time feedback" do
    # Arrange: Create questionnaire with slider question
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
    @response = @questionnaire.responses.create!(unique_token: "test_slider")

    # Act: Visit questionnaire and interact with slider
    visit edit_response_path(@response.unique_token)
    slider = find('input[type="range"]')
    slider.set(7)

    # Assert: Real-time feedback displays
    assert_selector '[data-slider-target="valueDisplay"]', text: "7"

    # Act: Submit answer
    click_button "Next"

    # Assert: Answer saved correctly
    @response.reload
    answer = @response.answers.find_by(question: @question)
    assert_equal 7, answer.numeric_value
  end

  test "user sees semantic labels at slider endpoints" do
    # Test AS-2: Labels displayed during slider interaction
    # ... implementation
  end

  test "slider value persists when navigating back" do
    # Test AS-3: Saved response pre-filled on return
    # ... implementation
  end
end
```
**Verify**: Test fails (red) - no slider implementation yet

### T011 [P] - Add slider settings validation to Question model
**File**: `app/models/question.rb`
```ruby
validate :slider_settings_valid, if: :slider?

private

def slider_settings_valid
  return unless settings.present?

  min = settings["min_value"]
  max = settings["max_value"]
  step = settings["step"] || 1

  errors.add(:settings, "must include min_value") if min.blank?
  errors.add(:settings, "must include max_value") if max.blank?
  errors.add(:settings, "min_value must be less than max_value") if min && max && min >= max
  errors.add(:settings, "step must be positive") if step && step <= 0
end
```
**Test**: `test/models/question_test.rb` - add tests for slider validation
**Verify**: Validation tests pass

### T012 [P] - Add slider answer validation to Answer model
**File**: `app/models/answer.rb`
```ruby
validate :slider_value_valid

# Update answer_matches_question_type to include slider
def answer_matches_question_type
  # ... existing code ...
  when "slider"
    if question.required? && numeric_value.blank?
      errors.add(:numeric_value, "must be present for required slider questions")
    end
end

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
**Test**: `test/models/answer_test.rb` - add slider validation tests
**Verify**: Answer validation tests pass

### T013 - Create Stimulus controller for slider
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

    // Show semantic label if defined
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
**Verify**: Controller connects (check browser console)

### T014 - Create view partial for slider question type
**File**: `app/views/responses/_question_types/_slider.html.erb`
```erb
<div data-controller="slider"
     data-slider-min-value="<%= question.settings['min_value'] %>"
     data-slider-max-value="<%= question.settings['max_value'] %>"
     data-slider-labels-value='<%= question.settings["labels"].to_json %>'
     data-action="slider:changed->responses#saveAnswer">

  <%= form_with model: [@response, @answer], url: response_path(@response.unique_token), method: :patch, data: { turbo_frame: "question_#{question.id}" } do |f| %>
    <%= f.hidden_field :question_id, value: question.id %>

    <label class="form-control">
      <div class="label">
        <span class="label-text"><%= question.text %></span>
        <% if question.required? %>
          <span class="label-text-alt text-error">*Required</span>
        <% end %>
      </div>

      <%= f.range_field :numeric_value,
                        min: question.settings['min_value'],
                        max: question.settings['max_value'],
                        value: @answer.numeric_value || question.settings['default_value'] || 5,
                        class: "range range-primary",
                        data: {
                          slider_target: "input",
                          action: "input->slider#updateDisplay change->slider#save"
                        } %>

      <div class="flex justify-between text-xs px-2 mt-2">
        <span><%= question.settings.dig('labels', question.settings['min_value'].to_s) || question.settings['min_value'] %></span>
        <span data-slider-target="valueDisplay" class="font-bold text-primary">5</span>
        <span><%= question.settings.dig('labels', question.settings['max_value'].to_s) || question.settings['max_value'] %></span>
      </div>

      <div class="text-center mt-2">
        <span data-slider-target="label" class="badge badge-lg"></span>
      </div>

      <div class="mt-4">
        <%= f.submit "Next", class: "btn btn-primary w-full" %>
      </div>
    </label>
  <% end %>
</div>
```
**Verify**: Partial renders without errors

### T015 - Create admin config form partial for slider
**File**: `app/views/questions/_form_fields/_slider_config.html.erb`
```erb
<div class="space-y-4">
  <div class="form-control">
    <%= label_tag :settings_min_value, "Minimum Value", class: "label" %>
    <%= number_field_tag :settings_min_value,
                         @question.settings["min_value"] || 1,
                         class: "input input-bordered" %>
  </div>

  <div class="form-control">
    <%= label_tag :settings_max_value, "Maximum Value", class: "label" %>
    <%= number_field_tag :settings_max_value,
                         @question.settings["max_value"] || 10,
                         class: "input input-bordered" %>
  </div>

  <div class="form-control">
    <%= label_tag :settings_step, "Step Size", class: "label" %>
    <%= number_field_tag :settings_step,
                         @question.settings["step"] || 1,
                         min: 1,
                         class: "input input-bordered" %>
  </div>

  <div class="form-control">
    <%= label_tag :settings_labels, "Labels (JSON)", class: "label" %>
    <%= text_area_tag :settings_labels,
                      @question.settings["labels"]&.to_json || '{"1": "Low", "10": "High"}',
                      class: "textarea textarea-bordered",
                      rows: 3,
                      placeholder: '{"1": "Very Low", "5": "Neutral", "10": "Very High"}' %>
    <div class="label">
      <span class="label-text-alt">Format: {"value": "label"}</span>
    </div>
  </div>
</div>
```
**Verify**: Admin form displays fields

### T016 [P] - Write controller test for slider answer persistence
**File**: `test/controllers/responses_controller_test.rb`
```ruby
test "should save slider answer and navigate to next question" do
  @slider_question = questions(:slider)

  patch response_path(@response.unique_token), params: {
    answer: {
      question_id: @slider_question.id,
      numeric_value: 7
    },
    direction: "next"
  }

  assert_response :success
  answer = @response.answers.find_by(question: @slider_question)
  assert_equal 7, answer.numeric_value
end

test "should reject slider answer outside min/max range" do
  @slider_question = questions(:slider)
  @slider_question.update(settings: { min_value: 1, max_value: 10 })

  patch response_path(@response.unique_token), params: {
    answer: {
      question_id: @slider_question.id,
      numeric_value: 15  # Invalid: exceeds max
    }
  }

  assert_response :unprocessable_entity
end
```
**Verify**: Controller tests pass

### T017 - Update responses/edit view to render slider partial
**File**: `app/views/responses/edit.html.erb`
```erb
<!-- Find the question type case statement and add: -->
<% when "slider" %>
  <%= render "responses/question_types/slider",
             question: @question,
             answer: @answer,
             response: @response %>
```
**Verify**: Slider questions render correctly

### T018 - Manual UI testing for slider
**Steps**:
1. Create slider question via admin UI
2. Start questionnaire response
3. Interact with slider - verify real-time value display
4. Verify labels appear at endpoints
5. Save answer and navigate to next question
6. Navigate back - verify slider shows saved value

**Verify**: All acceptance scenarios pass

**Checkpoint Phase 3**: ✅ User Story 1 complete - Slider input fully functional with tests passing

---

## Phase 4: User Story 2 - Swipe Yes/No (P2)

**Story Goal**: Users experience engaging yes/no decisions through swipe gestures with Tinder-like animations

**Independent Test**: Present yes/no question, swipe right, verify positive animation plays and boolean_value=true persisted

**Dependencies**: Requires Phase 2 (foundation) but NOT dependent on other user stories

### T019 - Write system test for User Story 2
**File**: `test/system/swipe_yes_no_test.rb`
```ruby
require "application_system_test_case"

class SwipeYesNoTest < ApplicationSystemTestCase
  test "user can swipe right for yes answer" do
    # AS-1: Right swipe records "yes"
    @questionnaire = questionnaires(:default)
    @category = @questionnaire.categories.first
    @question = @category.questions.create!(
      text: "Do you prefer working remotely?",
      question_type: "swipe_yes_no",
      required: true,
      settings: {
        swipe_threshold: 0.3,
        positive_label: "Yes",
        negative_label: "No"
      }
    )
    @response = @questionnaire.responses.create!(unique_token: "test_swipe")

    visit edit_response_path(@response.unique_token)

    # Simulate swipe right gesture
    card = find('[data-swipe-target="card"]')
    # Note: Actual swipe simulation may require custom Capybara driver
    # For now, click the right button
    find('[data-action*="swipe#handleSwipe"]', text: "YES").click

    @response.reload
    answer = @response.answers.find_by(question: @question)
    assert_equal true, answer.boolean_value
  end

  test "user can swipe left for no answer" do
    # AS-2: Left swipe records "no"
    # ... implementation
  end

  test "incomplete swipe returns card to center" do
    # AS-3: Released before threshold
    # ... implementation
  end

  test "completed swipe automatically shows next question" do
    # AS-4: Animation then next question
    # ... implementation
  end
end
```
**Verify**: Test fails (red)

### T020 [P] - Add swipe_yes_no settings validation to Question model
**File**: `app/models/question.rb`
```ruby
validate :swipe_yes_no_settings_valid, if: :swipe_yes_no?

private

def swipe_yes_no_settings_valid
  return unless settings.present?

  threshold = settings["swipe_threshold"]

  if threshold.blank?
    errors.add(:settings, "must include swipe_threshold")
  elsif threshold < 0.1 || threshold > 0.9
    errors.add(:settings, "swipe_threshold must be between 0.1 and 0.9")
  end

  errors.add(:settings, "must include positive_label") if settings["positive_label"].blank?
  errors.add(:settings, "must include negative_label") if settings["negative_label"].blank?
end
```
**Test**: Add to `test/models/question_test.rb`
**Verify**: Validation tests pass

### T021 [P] - Update Answer model for swipe_yes_no type
**File**: `app/models/answer.rb`
```ruby
# Update answer_matches_question_type
when "swipe_yes_no"
  if question.required? && boolean_value.nil?
    errors.add(:boolean_value, "must be present for required swipe yes/no questions")
  end
```
**Test**: Add to `test/models/answer_test.rb`
**Verify**: Tests pass

### T022 - Create Stimulus controller for swipe gesture
**File**: `app/javascript/controllers/swipe_controller.js`
```javascript
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = {
    threshold: { type: Number, default: 0.3 }
  }
  static targets = ["card"]

  connect() {
    this.startX = 0
    this.currentX = 0
    this.isDragging = false
  }

  start(event) {
    this.isDragging = true
    this.startX = event.clientX
    this.element.style.transition = 'none'
    event.preventDefault()
  }

  move(event) {
    if (!this.isDragging) return

    this.currentX = event.clientX - this.startX
    const rotation = this.currentX * 0.1
    this.cardTarget.style.transform =
      `translateX(${this.currentX}px) rotate(${rotation}deg)`

    this.updateVisualFeedback()
  }

  end(event) {
    if (!this.isDragging) return

    this.isDragging = false
    const swipeDistance = Math.abs(this.currentX)
    const thresholdPx = window.innerWidth * this.thresholdValue

    this.element.style.transition = 'transform 0.3s ease-out'

    if (swipeDistance > thresholdPx) {
      const direction = this.currentX > 0 ? 'right' : 'left'
      this.handleSwipe(direction)
    } else {
      this.resetPosition()
    }
  }

  cancel(event) {
    if (this.isDragging) {
      this.isDragging = false
      this.resetPosition()
    }
  }

  handleSwipe(direction) {
    const offset = direction === 'right' ? window.innerWidth : -window.innerWidth
    this.cardTarget.style.transform =
      `translateX(${offset}px) rotate(${offset * 0.05}deg)`

    this.dispatch('swiped', {
      detail: { answer: direction === 'right' }
    })

    setTimeout(() => {
      this.submitAnswer(direction === 'right')
    }, 300)
  }

  submitAnswer(value) {
    // Find form and set boolean_value
    const form = this.element.querySelector('form')
    const input = form.querySelector('input[name="answer[boolean_value]"]')
    input.value = value
    form.requestSubmit()
  }

  resetPosition() {
    this.cardTarget.style.transform = 'translateX(0) rotate(0deg)'
    this.currentX = 0
  }

  updateVisualFeedback() {
    const thresholdPx = window.innerWidth * this.thresholdValue
    const progress = Math.min(Math.abs(this.currentX) / thresholdPx, 1)

    this.element.style.setProperty('--swipe-opacity', progress)
    this.element.style.setProperty('--swipe-color',
      this.currentX > 0 ? 'var(--success)' : 'var(--error)')
  }
}
```
**Verify**: Controller connects

### T023 - Create view partial for swipe_yes_no question type
**File**: `app/views/responses/_question_types/_swipe_yes_no.html.erb`
```erb
<div data-controller="swipe"
     data-swipe-threshold-value="<%= question.settings['swipe_threshold'] %>"
     data-action="pointerdown->swipe#start
                  pointermove->swipe#move
                  pointerup->swipe#end
                  pointercancel->swipe#cancel"
     class="swipe-container relative">

  <%= form_with model: [@response, @answer], url: response_path(@response.unique_token), method: :patch, data: { turbo_frame: "question_#{question.id}" } do |f| %>
    <%= f.hidden_field :question_id, value: question.id %>
    <%= f.hidden_field :boolean_value %>

    <div data-swipe-target="card" class="question-card card bg-base-100 shadow-xl">
      <div class="card-body text-center">
        <h2 class="card-title justify-center"><%= question.text %></h2>
        <% if question.required? %>
          <span class="badge badge-error">Required</span>
        <% end %>

        <div class="card-actions justify-center mt-6 gap-4">
          <button type="button" class="btn btn-error btn-lg"
                  data-action="click->swipe#handleSwipe"
                  data-swipe-direction="left">
            NO ✗
          </button>
          <button type="button" class="btn btn-success btn-lg"
                  data-action="click->swipe#handleSwipe"
                  data-swipe-direction="right">
            YES ✓
          </button>
        </div>

        <p class="text-sm opacity-50 mt-4">Swipe or tap to answer</p>
      </div>
    </div>

    <div class="swipe-indicator swipe-indicator--yes">YES ✓</div>
    <div class="swipe-indicator swipe-indicator--no">NO ✗</div>
  <% end %>
</div>

<style>
.swipe-container {
  touch-action: none;
  --swipe-opacity: 0;
  --swipe-color: transparent;
}

.question-card {
  transition: transform 0.3s ease-out;
  cursor: grab;
}

.question-card:active {
  cursor: grabbing;
}

.swipe-indicator {
  position: absolute;
  top: 50%;
  transform: translateY(-50%);
  font-size: 3rem;
  font-weight: bold;
  opacity: var(--swipe-opacity);
  transition: opacity 0.2s ease;
  pointer-events: none;
}

.swipe-indicator--yes {
  right: 2rem;
  color: oklch(var(--su));
}

.swipe-indicator--no {
  left: 2rem;
  color: oklch(var(--er));
}
</style>
```
**Verify**: Partial renders

### T024 - Create admin config form partial for swipe_yes_no
**File**: `app/views/questions/_form_fields/_swipe_yes_no_config.html.erb`
```erb
<div class="space-y-4">
  <div class="form-control">
    <%= label_tag :settings_swipe_threshold, "Swipe Threshold (0.1-0.9)", class: "label" %>
    <%= number_field_tag :settings_swipe_threshold,
                         @question.settings["swipe_threshold"] || 0.3,
                         step: 0.1,
                         min: 0.1,
                         max: 0.9,
                         class: "input input-bordered" %>
    <div class="label">
      <span class="label-text-alt">Percentage of screen width to trigger swipe</span>
    </div>
  </div>

  <div class="form-control">
    <%= label_tag :settings_positive_label, "Positive Label (Right/Yes)", class: "label" %>
    <%= text_field_tag :settings_positive_label,
                       @question.settings["positive_label"] || "Yes",
                       class: "input input-bordered" %>
  </div>

  <div class="form-control">
    <%= label_tag :settings_negative_label, "Negative Label (Left/No)", class: "label" %>
    <%= text_field_tag :settings_negative_label,
                       @question.settings["negative_label"] || "No",
                       class: "input input-bordered" %>
  </div>
</div>
```
**Verify**: Admin form works

### T025 - Update responses/edit view for swipe_yes_no
**File**: `app/views/responses/edit.html.erb`
```erb
<% when "swipe_yes_no" %>
  <%= render "responses/question_types/swipe_yes_no",
             question: @question,
             answer: @answer,
             response: @response %>
```
**Verify**: Renders correctly

### T026 - Manual UI testing for swipe
**Steps**:
1. Create swipe yes/no question
2. Test mouse drag right → yes
3. Test mouse drag left → no
4. Test incomplete drag (release early) → resets
5. Test button clicks as fallback
6. Verify animations play

**Verify**: All acceptance scenarios pass

**Checkpoint Phase 4**: ✅ User Story 2 complete - Swipe Yes/No functional

---

## Phase 5: User Story 3 - Card Sort (P2)

**Story Goal**: Users rank multiple options by importance through drag-and-drop interface

**Independent Test**: Present 5 cards, drag to reorder, save, verify jsonb_value contains ranked array

**Dependencies**: Requires Phase 1 (SortableJS) and Phase 2 (foundation)

### T027 - Write system test for User Story 3
**File**: `test/system/card_sorting_test.rb`
```ruby
require "application_system_test_case"

class CardSortingTest < ApplicationSystemTestCase
  test "user can drag cards to rank them" do
    # AS-1, AS-2: Drag and drop with visual feedback
    @questionnaire = questionnaires(:default)
    @category = @questionnaire.categories.first
    @question = @category.questions.create!(
      text: "Rank your top work values:",
      question_type: "card_sort",
      required: true,
      settings: {
        cards: [
          { id: "balance", text: "Work-life balance" },
          { id: "growth", text: "Career growth" },
          { id: "comp", text: "Compensation" },
          { id: "culture", text: "Team culture" },
          { id: "challenge", text: "Challenging work" }
        ],
        allow_partial_ranking: true
      }
    )
    @response = @questionnaire.responses.create!(unique_token: "test_cards")

    visit edit_response_path(@response.unique_token)

    # Drag first card to third position
    cards = all('.sortable-card')
    cards[0].drag_to(cards[2])

    click_button "Next"

    @response.reload
    answer = @response.answers.find_by(question: @question)
    ranked = answer.jsonb_value["ranked"]

    assert ranked.present?
    assert_equal "growth", ranked[0]["id"]  # Original second card now first
  end

  test "unranked cards are saved as such" do
    # AS-3: Partial ranking allowed
    # ... implementation
  end

  test "cards display rank numbers" do
    # AS-4: Visual rank indicators
    # ... implementation
  end
end
```
**Verify**: Test fails (red)

### T028 [P] - Add card_sort settings validation to Question model
**File**: `app/models/question.rb`
```ruby
validate :card_sort_settings_valid, if: :card_sort?

private

def card_sort_settings_valid
  return unless settings.present?

  cards = settings["cards"]
  errors.add(:settings, "must include cards array") if cards.blank?
  errors.add(:settings, "must have between 3 and 15 cards") if cards && !cards.size.between?(3, 15)

  if cards.present?
    ids = cards.map { |c| c["id"] }
    errors.add(:settings, "card IDs must be unique") if ids.uniq.size != ids.size
    errors.add(:settings, "each card must have an id and text") if cards.any? { |c| c["id"].blank? || c["text"].blank? }
  end
end
```
**Test**: Add to `test/models/question_test.rb`
**Verify**: Tests pass

### T029 [P] - Add card_sort answer validation to Answer model
**File**: `app/models/answer.rb`
```ruby
validate :card_sort_value_valid

# Update answer_matches_question_type
when "card_sort"
  if question.required? && (jsonb_value.blank? || jsonb_value["ranked"].blank?)
    errors.add(:jsonb_value, "must include at least one ranked card")
  end

private

def card_sort_value_valid
  return unless question&.card_sort? && jsonb_value.present?

  valid_card_ids = question.settings["cards"]&.map { |c| c["id"] } || []
  ranked = jsonb_value["ranked"] || []
  unranked = jsonb_value["unranked"] || []

  # Check all IDs are valid
  all_ids = ranked.map { |r| r["id"] } + unranked
  invalid_ids = all_ids - valid_card_ids

  if invalid_ids.any?
    errors.add(:jsonb_value, "contains invalid card IDs: #{invalid_ids.join(', ')}")
  end

  # Check for duplicates
  if all_ids.uniq.size != all_ids.size
    errors.add(:jsonb_value, "contains duplicate card IDs")
  end

  # Check ranks are sequential
  ranks = ranked.map { |r| r["rank"] }
  expected_ranks = (1..ranks.size).to_a
  if ranks.sort != expected_ranks
    errors.add(:jsonb_value, "ranks must be sequential starting from 1")
  end
end
```
**Test**: Add to `test/models/answer_test.rb`
**Verify**: Tests pass

### T030 - Create Stimulus controller for card sorting
**File**: `app/javascript/controllers/card_sort_controller.js`
```javascript
import { Controller } from "@hotwired/stimulus"
import Sortable from "sortablejs"

export default class extends Controller {
  static values = { animation: { type: Number, default: 150 } }

  connect() {
    this.sortable = Sortable.create(this.element, {
      animation: this.animationValue,
      delayOnTouchOnly: true,
      delay: 100,
      touchStartThreshold: 5,
      ghostClass: "opacity-50",
      chosenClass: "ring-2 ring-primary",
      dragClass: "rotate-2",
      onEnd: this.onEnd.bind(this)
    })

    this.updateRankNumbers()
  }

  onEnd(event) {
    this.updateRankNumbers()
    this.updateHiddenField()
  }

  updateRankNumbers() {
    const cards = this.element.querySelectorAll('.sortable-card')
    cards.forEach((card, index) => {
      const rankBadge = card.querySelector('.rank-badge')
      if (rankBadge) {
        rankBadge.textContent = `#${index + 1}`
      }
    })
  }

  updateHiddenField() {
    const cards = this.element.querySelectorAll('.sortable-card')
    const ranked = Array.from(cards).map((card, index) => ({
      id: card.dataset.cardId,
      rank: index + 1
    }))

    const hiddenField = this.element.closest('form').querySelector('input[name="answer[jsonb_value]"]')
    hiddenField.value = JSON.stringify({ ranked, unranked: [] })
  }

  disconnect() {
    if (this.sortable) this.sortable.destroy()
  }
}
```
**Verify**: Controller connects

### T031 - Create view partial for card_sort question type
**File**: `app/views/responses/_question_types/_card_sort.html.erb`
```erb
<div class="space-y-4">
  <div class="card bg-base-100">
    <div class="card-body">
      <h2 class="card-title"><%= question.text %></h2>
      <% if question.required? %>
        <span class="badge badge-error">Required</span>
      <% end %>
      <p class="text-sm opacity-70">Drag cards to rank from most to least important</p>
    </div>
  </div>

  <%= form_with model: [@response, @answer], url: response_path(@response.unique_token), method: :patch, data: { turbo_frame: "question_#{question.id}" } do |f| %>
    <%= f.hidden_field :question_id, value: question.id %>
    <%= f.hidden_field :jsonb_value, value: @answer.jsonb_value.to_json %>

    <div data-controller="card-sort" class="space-y-3">
      <% question.settings["cards"].each do |card| %>
        <div class="sortable-card card bg-base-200 shadow cursor-move hover:shadow-lg transition"
             data-card-id="<%= card['id'] %>">
          <div class="card-body py-4 px-6">
            <div class="flex items-center gap-4">
              <span class="rank-badge badge badge-primary badge-lg">#1</span>
              <div class="flex-1">
                <h3 class="font-semibold"><%= card['text'] %></h3>
                <% if card['description'].present? %>
                  <p class="text-sm opacity-70"><%= card['description'] %></p>
                <% end %>
              </div>
              <span class="text-2xl opacity-50">⋮⋮</span>
            </div>
          </div>
        </div>
      <% end %>
    </div>

    <div class="mt-6">
      <%= f.submit "Next", class: "btn btn-primary w-full" %>
    </div>
  <% end %>
</div>
```
**Verify**: Partial renders

### T032 - Create admin config form partial for card_sort
**File**: `app/views/questions/_form_fields/_card_sort_config.html.erb`
```erb
<div class="space-y-4">
  <div class="form-control">
    <label class="label cursor-pointer">
      <%= check_box_tag :settings_allow_partial_ranking,
                        "1",
                        @question.settings["allow_partial_ranking"],
                        class: "checkbox checkbox-primary" %>
      <span class="label-text ml-2">Allow partial ranking (users can leave some cards unranked)</span>
    </label>
  </div>

  <div id="cards-list" class="space-y-2">
    <label class="label">
      <span class="label-text font-semibold">Cards</span>
    </label>

    <% (@question.settings["cards"] || []).each_with_index do |card, index| %>
      <div class="card bg-base-200" data-card-index="<%= index %>">
        <div class="card-body py-3">
          <%= text_field_tag "settings_cards[#{index}][id]",
                             card["id"],
                             placeholder: "card-id",
                             class: "input input-sm input-bordered mb-2" %>
          <%= text_field_tag "settings_cards[#{index}][text]",
                             card["text"],
                             placeholder: "Card text",
                             class: "input input-bordered mb-2" %>
          <%= text_area_tag "settings_cards[#{index}][description]",
                            card["description"],
                            placeholder: "Optional description",
                            rows: 2,
                            class: "textarea textarea-bordered textarea-sm" %>
          <button type="button" class="btn btn-error btn-sm mt-2" onclick="this.closest('[data-card-index]').remove()">
            Remove Card
          </button>
        </div>
      </div>
    <% end %>
  </div>

  <button type="button" class="btn btn-primary btn-sm" onclick="addCard()">
    + Add Card
  </button>

  <script>
    function addCard() {
      const index = document.querySelectorAll('[data-card-index]').length
      const html = `
        <div class="card bg-base-200" data-card-index="${index}">
          <div class="card-body py-3">
            <input type="text" name="settings_cards[${index}][id]" placeholder="card-id" class="input input-sm input-bordered mb-2">
            <input type="text" name="settings_cards[${index}][text]" placeholder="Card text" class="input input-bordered mb-2">
            <textarea name="settings_cards[${index}][description]" placeholder="Optional description" rows="2" class="textarea textarea-bordered textarea-sm"></textarea>
            <button type="button" class="btn btn-error btn-sm mt-2" onclick="this.closest('[data-card-index]').remove()">Remove Card</button>
          </div>
        </div>
      `
      document.getElementById('cards-list').insertAdjacentHTML('beforeend', html)
    }
  </script>
</div>
```
**Verify**: Admin form works

### T033 - Update responses/edit view for card_sort
**File**: `app/views/responses/edit.html.erb`
```erb
<% when "card_sort" %>
  <%= render "responses/question_types/card_sort",
             question: @question,
             answer: @answer,
             response: @response %>
```
**Verify**: Renders correctly

### T034 - Manual UI testing for card sorting
**Steps**:
1. Create card_sort question with 5 cards
2. Drag cards to reorder
3. Verify rank badges update in real-time
4. Save and verify ranking persisted
5. Test partial ranking (leave some unranked)
6. Navigate back - verify order preserved

**Verify**: All acceptance scenarios pass

**Checkpoint Phase 5**: ✅ User Story 3 complete - Card Sort functional

---

## Phase 6: User Story 4 - Energy Map (P3)

**Story Goal**: Users map energy/mood levels across time periods with interactive graph

**Independent Test**: Display timeline with 7 periods, plot energy at 3 periods, save, verify jsonb_value contains data_points array

**Dependencies**: Requires Phase 1 (Chart.js) and Phase 2 (foundation)

### T035 - Write system test for User Story 4
**File**: `test/system/energy_mapping_test.rb`
```ruby
require "application_system_test_case"

class EnergyMappingTest < ApplicationSystemTestCase
  test "user can plot energy levels on timeline" do
    # AS-1, AS-2: Click time points, see connected line
    @questionnaire = questionnaires(:default)
    @category = @questionnaire.categories.first
    @question = @category.questions.create!(
      text: "Map your energy levels throughout a typical work week:",
      question_type: "energy_map",
      required: true,
      settings: {
        time_periods: ["Mon AM", "Mon PM", "Tue AM", "Tue PM", "Wed AM", "Wed PM", "Thu AM"],
        scale_min: 0,
        scale_max: 10,
        allow_partial: true
      }
    )
    @response = @questionnaire.responses.create!(unique_token: "test_energy")

    visit edit_response_path(@response.unique_token)

    # Click on chart to plot points (requires Chart.js + dragdata plugin)
    # Note: Direct chart interaction testing may require custom driver
    # For basic test, submit with data
    fill_in "answer[jsonb_value]", with: {
      data_points: [
        { period: "Mon AM", value: 7 },
        { period: "Mon PM", value: 5 }
      ]
    }.to_json

    click_button "Next"

    @response.reload
    answer = @response.answers.find_by(question: @question)
    assert_equal 2, answer.jsonb_value["data_points"].size
  end

  test "user can submit energy map with null periods" do
    # AS-3: Partial data allowed (FR-013)
    # ... implementation
  end

  test "user can edit previously set points" do
    # AS-4: Modify existing points
    # ... implementation
  end
end
```
**Verify**: Test fails (red)

### T036 [P] - Add energy_map settings validation to Question model
**File**: `app/models/question.rb`
```ruby
validate :energy_map_settings_valid, if: :energy_map?

private

def energy_map_settings_valid
  return unless settings.present?

  periods = settings["time_periods"]
  scale_min = settings["scale_min"]
  scale_max = settings["scale_max"]

  errors.add(:settings, "must include time_periods array") if periods.blank?
  errors.add(:settings, "must have between 3 and 24 time periods") if periods && !periods.size.between?(3, 24)
  errors.add(:settings, "must include scale_min") if scale_min.blank?
  errors.add(:settings, "must include scale_max") if scale_max.blank?
  errors.add(:settings, "scale_min must be less than scale_max") if scale_min && scale_max && scale_min >= scale_max
end
```
**Test**: Add to `test/models/question_test.rb`
**Verify**: Tests pass

### T037 [P] - Add energy_map answer validation to Answer model
**File**: `app/models/answer.rb`
```ruby
validate :energy_map_value_valid

# Update answer_matches_question_type
when "energy_map"
  if question.required? && (jsonb_value.blank? || jsonb_value["data_points"].blank?)
    errors.add(:jsonb_value, "must include at least one data point")
  end

private

def energy_map_value_valid
  return unless question&.energy_map? && jsonb_value.present?

  valid_periods = question.settings["time_periods"] || []
  scale_min = question.settings["scale_min"] || 0
  scale_max = question.settings["scale_max"] || 10
  data_points = jsonb_value["data_points"] || []

  data_points.each do |point|
    period = point["period"]
    value = point["value"]

    unless valid_periods.include?(period)
      errors.add(:jsonb_value, "contains invalid time period: #{period}")
    end

    if value.present? && (value < scale_min || value > scale_max)
      errors.add(:jsonb_value, "energy value #{value} for #{period} must be between #{scale_min} and #{scale_max}")
    end
  end

  # Check for duplicate periods
  periods = data_points.map { |p| p["period"] }
  if periods.uniq.size != periods.size
    errors.add(:jsonb_value, "contains duplicate time periods")
  end
end
```
**Test**: Add to `test/models/answer_test.rb`
**Verify**: Tests pass

### T038 - Create Stimulus controller for energy map
**File**: `app/javascript/controllers/energy_map_controller.js`
```javascript
import { Controller } from "@hotwired/stimulus"
import { Chart, registerables } from "chart.js"
import ChartJSDragDataPlugin from "chartjs-plugin-dragdata"

Chart.register(...registerables, ChartJSDragDataPlugin)

export default class extends Controller {
  static targets = ["canvas"]
  static values = {
    data: Array,
    labels: Array,
    scaleMin: { type: Number, default: 0 },
    scaleMax: { type: Number, default: 10 }
  }

  connect() {
    this.chart = new Chart(this.canvasTarget, {
      type: 'line',
      data: {
        labels: this.labelsValue,
        datasets: [{
          label: 'Energy Level',
          data: this.dataValue,
          borderColor: 'rgb(75, 192, 192)',
          backgroundColor: 'rgba(75, 192, 192, 0.2)',
          tension: 0.4,
          pointRadius: 8,
          pointHitRadius: 25
        }]
      },
      options: {
        responsive: true,
        maintainAspectRatio: false,
        plugins: {
          dragData: {
            round: 0,
            showTooltip: true,
            onDragEnd: (e, datasetIndex, index, value) => {
              this.saveDataPoint(index, value)
            }
          },
          legend: { display: false }
        },
        scales: {
          y: {
            min: this.scaleMinValue,
            max: this.scaleMaxValue,
            title: { display: true, text: 'Energy Level' }
          }
        },
        interaction: {
          mode: 'nearest',
          intersect: false
        },
        onClick: (event, elements) => {
          if (elements.length === 0) {
            // Click on empty point - initialize to mid-range
            const index = Math.round(event.chart.scales.x.getValueForPixel(event.x))
            if (index >= 0 && index < this.labelsValue.length) {
              const midValue = (this.scaleMinValue + this.scaleMaxValue) / 2
              this.chart.data.datasets[0].data[index] = midValue
              this.chart.update()
              this.saveDataPoint(index, midValue)
            }
          }
        }
      }
    })
  }

  saveDataPoint(index, value) {
    const dataPoints = this.labelsValue.map((label, i) => ({
      period: label,
      value: this.chart.data.datasets[0].data[i] || null
    }))

    this.dispatch('point-updated', {
      detail: { data_points: dataPoints }
    })

    // Update hidden field
    const hiddenField = this.element.closest('form').querySelector('input[name="answer[jsonb_value]"]')
    hiddenField.value = JSON.stringify({ data_points: dataPoints })
  }

  disconnect() {
    if (this.chart) this.chart.destroy()
  }
}
```
**Verify**: Controller connects

### T039 - Create view partial for energy_map question type
**File**: `app/views/responses/_question_types/_energy_map.html.erb`
```erb
<div class="space-y-4">
  <div class="card bg-base-100">
    <div class="card-body">
      <h2 class="card-title"><%= question.text %></h2>
      <% if question.required? %>
        <span class="badge badge-error">Required</span>
      <% end %>
      <p class="text-sm opacity-70">Click time periods to set energy levels. Drag points to adjust.</p>
    </div>
  </div>

  <%= form_with model: [@response, @answer], url: response_path(@response.unique_token), method: :patch, data: { turbo_frame: "question_#{question.id}" } do |f| %>
    <%= f.hidden_field :question_id, value: question.id %>
    <%= f.hidden_field :jsonb_value, value: @answer.jsonb_value.to_json %>

    <%
      # Prepare data array (nulls for unset periods)
      existing_points = (@answer.jsonb_value || {})["data_points"] || []
      data_map = existing_points.index_by { |p| p["period"] }
      chart_data = question.settings["time_periods"].map { |period| data_map[period]&.dig("value") }
    %>

    <div data-controller="energy-map"
         data-energy-map-data-value='<%= chart_data.to_json %>'
         data-energy-map-labels-value='<%= question.settings["time_periods"].to_json %>'
         data-energy-map-scale-min-value="<%= question.settings['scale_min'] %>"
         data-energy-map-scale-max-value="<%= question.settings['scale_max'] %>"
         style="height: 400px;">
      <canvas data-energy-map-target="canvas"></canvas>
    </div>

    <div class="alert alert-info mt-4">
      <span class="text-sm">
        💡 Tip: Click empty periods to plot points, drag existing points to adjust values
      </span>
    </div>

    <div class="mt-6">
      <%= f.submit "Next", class: "btn btn-primary w-full" %>
    </div>
  <% end %>
</div>
```
**Verify**: Partial renders

### T040 - Create admin config form partial for energy_map
**File**: `app/views/questions/_form_fields/_energy_map_config.html.erb`
```erb
<div class="space-y-4">
  <div class="form-control">
    <%= label_tag :settings_scale_min, "Scale Minimum", class: "label" %>
    <%= number_field_tag :settings_scale_min,
                         @question.settings["scale_min"] || 0,
                         class: "input input-bordered" %>
  </div>

  <div class="form-control">
    <%= label_tag :settings_scale_max, "Scale Maximum", class: "label" %>
    <%= number_field_tag :settings_scale_max,
                         @question.settings["scale_max"] || 10,
                         class: "input input-bordered" %>
  </div>

  <div class="form-control">
    <label class="label cursor-pointer">
      <%= check_box_tag :settings_allow_partial,
                        "1",
                        @question.settings["allow_partial"],
                        class: "checkbox checkbox-primary" %>
      <span class="label-text ml-2">Allow partial data (users can leave some periods empty)</span>
    </label>
  </div>

  <div class="form-control">
    <%= label_tag :settings_time_periods, "Time Periods (one per line)", class: "label" %>
    <%= text_area_tag :settings_time_periods,
                      (@question.settings["time_periods"] || []).join("\n"),
                      rows: 8,
                      placeholder: "Monday Morning\nMonday Afternoon\nTuesday Morning\n...",
                      class: "textarea textarea-bordered" %>
    <div class="label">
      <span class="label-text-alt">3-24 time periods</span>
    </div>
  </div>
</div>
```
**Verify**: Admin form works

### T041 - Update responses/edit view for energy_map
**File**: `app/views/responses/edit.html.erb`
```erb
<% when "energy_map" %>
  <%= render "responses/question_types/energy_map",
             question: @question,
             answer: @answer,
             response: @response %>
```
**Verify**: Renders correctly

### T042 - Manual UI testing for energy map
**Steps**:
1. Create energy_map question with 7 time periods
2. Click periods to plot points
3. Verify line connects points
4. Drag points to adjust values
5. Save with some periods empty (if allow_partial=true)
6. Verify data persisted correctly

**Verify**: All acceptance scenarios pass

**Checkpoint Phase 6**: ✅ User Story 4 complete - Energy Map functional

---

## Phase 7: User Story 5 - Emoji Reactions (P3)

**Story Goal**: Users express emotional responses through emoji selection with animations

**Independent Test**: Display 5 emoji options, tap one, verify animation plays and jsonb_value contains selected emoji

**Dependencies**: Requires Phase 2 (foundation) only

### T043 - Write system test for User Story 5
**File**: `test/system/emoji_reactions_test.rb`
```ruby
require "application_system_test_case"

class EmojiReactionsTest < ApplicationSystemTestCase
  test "user can select emoji reaction" do
    # AS-1: Tap emoji, see animation and highlight
    @questionnaire = questionnaires(:default)
    @category = @questionnaire.categories.first
    @question = @category.questions.create!(
      text: "How do you feel about meetings?",
      question_type: "emoji_reaction",
      required: true,
      settings: {
        emoji_options: [
          { emoji: "😍", label: "Love it", value: 5 },
          { emoji: "😊", label: "Like it", value: 4 },
          { emoji: "😐", label: "Neutral", value: 3 },
          { emoji: "😕", label: "Dislike", value: 2 },
          { emoji: "😤", label: "Hate it", value: 1 }
        ]
      }
    )
    @response = @questionnaire.responses.create!(unique_token: "test_emoji")

    visit edit_response_path(@response.unique_token)

    # Click emoji
    find('button[data-emoji="😍"]').click

    # Verify selected state
    assert_selector 'button[data-emoji="😍"].btn-primary'

    click_button "Next"

    @response.reload
    answer = @response.answers.find_by(question: @question)
    assert_equal "😍", answer.jsonb_value["emoji"]
    assert_equal "Love it", answer.jsonb_value["label"]
  end

  test "user can change emoji selection" do
    # AS-4: Change selection
    # ... implementation
  end

  test "emoji shows label on hover" do
    # AS-3: Preview on hover
    # ... implementation
  end
end
```
**Verify**: Test fails (red)

### T044 [P] - Add emoji_reaction settings validation to Question model
**File**: `app/models/question.rb`
```ruby
validate :emoji_reaction_settings_valid, if: :emoji_reaction?

private

def emoji_reaction_settings_valid
  return unless settings.present?

  options = settings["emoji_options"]
  errors.add(:settings, "must include emoji_options array") if options.blank?
  errors.add(:settings, "must have between 3 and 10 emoji options") if options && !options.size.between?(3, 10)

  if options.present?
    emojis = options.map { |o| o["emoji"] }
    errors.add(:settings, "emojis must be unique") if emojis.uniq.size != emojis.size
    errors.add(:settings, "each option must have an emoji and label") if options.any? { |o| o["emoji"].blank? || o["label"].blank? }
  end
end
```
**Test**: Add to `test/models/question_test.rb`
**Verify**: Tests pass

### T045 [P] - Add emoji_reaction answer validation to Answer model
**File**: `app/models/answer.rb`
```ruby
validate :emoji_reaction_value_valid

# Update answer_matches_question_type
when "emoji_reaction"
  if question.required? && (jsonb_value.blank? || jsonb_value["emoji"].blank?)
    errors.add(:jsonb_value, "must include selected emoji")
  end

private

def emoji_reaction_value_valid
  return unless question&.emoji_reaction? && jsonb_value.present?

  valid_emojis = question.settings["emoji_options"]&.map { |o| o["emoji"] } || []
  selected_emoji = jsonb_value["emoji"]

  unless valid_emojis.include?(selected_emoji)
    errors.add(:jsonb_value, "selected emoji is not a valid option")
  end
end
```
**Test**: Add to `test/models/answer_test.rb`
**Verify**: Tests pass

### T046 - Create Stimulus controller for emoji reactions
**File**: `app/javascript/controllers/emoji_reaction_controller.js`
```javascript
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["option"]

  select(event) {
    const clickedOption = event.currentTarget
    const emoji = clickedOption.dataset.emoji
    const label = clickedOption.dataset.label
    const value = clickedOption.dataset.value

    // Clear previous selection
    this.optionTargets.forEach(opt => {
      opt.classList.remove("btn-primary", "scale-125")
      opt.classList.add("btn-ghost")
    })

    // Highlight selected
    clickedOption.classList.remove("btn-ghost")
    clickedOption.classList.add("btn-primary", "scale-125")

    // Animate
    clickedOption.style.animation = "bounce 0.5s ease"
    setTimeout(() => {
      clickedOption.style.animation = ""
    }, 500)

    // Update hidden field
    const hiddenField = this.element.querySelector('input[name="answer[jsonb_value]"]')
    hiddenField.value = JSON.stringify({ emoji, label, value: parseInt(value) })

    this.dispatch('selected', { detail: { emoji, label, value } })
  }
}
```
**Verify**: Controller connects

### T047 - Create view partial for emoji_reaction question type
**File**: `app/views/responses/_question_types/_emoji_reaction.html.erb`
```erb
<div class="space-y-6">
  <div class="card bg-base-100">
    <div class="card-body text-center">
      <h2 class="card-title justify-center"><%= question.text %></h2>
      <% if question.required? %>
        <span class="badge badge-error">Required</span>
      <% end %>
    </div>
  </div>

  <%= form_with model: [@response, @answer], url: response_path(@response.unique_token), method: :patch, data: { turbo_frame: "question_#{question.id}" } do |f| %>
    <%= f.hidden_field :question_id, value: question.id %>
    <%= f.hidden_field :jsonb_value, value: @answer.jsonb_value.to_json %>

    <div data-controller="emoji-reaction"
         class="flex flex-wrap gap-4 justify-center">
      <% question.settings["emoji_options"].each do |option| %>
        <%
          is_selected = @answer.jsonb_value.present? && @answer.jsonb_value["emoji"] == option["emoji"]
          btn_class = is_selected ? "btn-primary scale-125" : "btn-ghost"
        %>
        <button type="button"
                class="btn btn-circle btn-lg <%= btn_class %>"
                data-emoji-reaction-target="option"
                data-emoji="<%= option['emoji'] %>"
                data-label="<%= option['label'] %>"
                data-value="<%= option['value'] %>"
                data-action="click->emoji-reaction#select"
                title="<%= option['label'] %>">
          <span class="text-4xl"><%= option['emoji'] %></span>
        </button>
      <% end %>
    </div>

    <div class="text-center mt-4 text-sm opacity-50">
      Tap an emoji to react
    </div>

    <div class="mt-6">
      <%= f.submit "Next", class: "btn btn-primary w-full" %>
    </div>
  <% end %>
</div>

<style>
@keyframes bounce {
  0%, 100% { transform: scale(1.25) translateY(0); }
  50% { transform: scale(1.35) translateY(-10px); }
}
</style>
```
**Verify**: Partial renders

### T048 - Create admin config form partial for emoji_reaction
**File**: `app/views/questions/_form_fields/_emoji_reaction_config.html.erb`
```erb
<div class="space-y-4">
  <div id="emoji-options-list" class="space-y-2">
    <label class="label">
      <span class="label-text font-semibold">Emoji Options</span>
    </label>

    <% (@question.settings["emoji_options"] || []).each_with_index do |option, index| %>
      <div class="card bg-base-200" data-emoji-index="<%= index %>">
        <div class="card-body py-3">
          <div class="grid grid-cols-3 gap-2">
            <%= text_field_tag "settings_emoji_options[#{index}][emoji]",
                               option["emoji"],
                               placeholder: "😊",
                               class: "input input-bordered" %>
            <%= text_field_tag "settings_emoji_options[#{index}][label]",
                               option["label"],
                               placeholder: "Label",
                               class: "input input-bordered" %>
            <%= number_field_tag "settings_emoji_options[#{index}][value]",
                                 option["value"],
                                 placeholder: "Value",
                                 class: "input input-bordered" %>
          </div>
          <button type="button" class="btn btn-error btn-sm mt-2" onclick="this.closest('[data-emoji-index]').remove()">
            Remove Option
          </button>
        </div>
      </div>
    <% end %>
  </div>

  <button type="button" class="btn btn-primary btn-sm" onclick="addEmojiOption()">
    + Add Emoji Option
  </button>

  <script>
    function addEmojiOption() {
      const index = document.querySelectorAll('[data-emoji-index]').length
      const html = `
        <div class="card bg-base-200" data-emoji-index="${index}">
          <div class="card-body py-3">
            <div class="grid grid-cols-3 gap-2">
              <input type="text" name="settings_emoji_options[${index}][emoji]" placeholder="😊" class="input input-bordered">
              <input type="text" name="settings_emoji_options[${index}][label]" placeholder="Label" class="input input-bordered">
              <input type="number" name="settings_emoji_options[${index}][value]" placeholder="Value" class="input input-bordered">
            </div>
            <button type="button" class="btn btn-error btn-sm mt-2" onclick="this.closest('[data-emoji-index]').remove()">Remove Option</button>
          </div>
        </div>
      `
      document.getElementById('emoji-options-list').insertAdjacentHTML('beforeend', html)
    }
  </script>
</div>
```
**Verify**: Admin form works

### T049 - Update responses/edit view for emoji_reaction
**File**: `app/views/responses/edit.html.erb`
```erb
<% when "emoji_reaction" %>
  <%= render "responses/question_types/emoji_reaction",
             question: @question,
             answer: @answer,
             response: @response %>
```
**Verify**: Renders correctly

### T050 - Manual UI testing for emoji reactions
**Steps**:
1. Create emoji_reaction question with 5 options
2. Click emoji - verify animation
3. Verify selected state (highlighted)
4. Change selection - verify previous clears
5. Hover - verify label shows (title attribute)
6. Save and verify persisted

**Verify**: All acceptance scenarios pass

**Checkpoint Phase 7**: ✅ User Story 5 complete - Emoji Reactions functional

---

## Phase 8: User Story 6 - Character Sheet (P3)

**Story Goal**: Users allocate points across multiple stats with budget constraints

**Independent Test**: Display character sheet with 4 stats and 20-point budget, allocate all points, verify submission blocked if incomplete, verify jsonb_value contains allocations when complete

**Dependencies**: Requires Phase 2 (foundation) only

### T051 - Write system test for User Story 6
**File**: `test/system/character_sheet_test.rb`
```ruby
require "application_system_test_case"

class CharacterSheetTest < ApplicationSystemTestCase
  test "user can allocate character sheet points" do
    # AS-1, AS-2: Allocate points, see remaining budget
    @questionnaire = questionnaires(:default)
    @category = @questionnaire.categories.first
    @question = @category.questions.create!(
      text: "Allocate 20 points across your work style attributes:",
      question_type: "character_sheet",
      required: true,
      settings: {
        total_points: 20,
        stats: [
          { id: "leadership", label: "Leadership", description: "...", min: 0, max: 10 },
          { id: "technical", label: "Technical", description: "...", min: 0, max: 10 },
          { id: "creative", label: "Creative", description: "...", min: 0, max: 10 },
          { id: "communication", label: "Communication", description: "...", min: 0, max: 10 }
        ]
      }
    )
    @response = @questionnaire.responses.create!(unique_token: "test_char")

    visit edit_response_path(@response.unique_token)

    # Allocate points
    within('[data-stat-id="leadership"]') do
      5.times { click_button "+" }
    end

    # Verify remaining updates
    assert_selector '[data-character-sheet-target="remaining"]', text: "15"

    # Complete allocation
    within('[data-stat-id="technical"]') { 10.times { click_button "+" } }
    within('[data-stat-id="creative"]') { 3.times { click_button "+" } }
    within('[data-stat-id="communication"]') { 2.times { click_button "+" } }

    # Verify submit enabled
    assert_selector 'button[type="button"]:not(.btn-disabled)', text: "Submit Character Sheet"

    click_button "Submit Character Sheet"

    @response.reload
    answer = @response.answers.find_by(question: @question)
    assert_equal 20, answer.jsonb_value["total_allocated"]
    assert_equal 5, answer.jsonb_value["allocations"]["leadership"]
  end

  test "system blocks submission with incomplete allocation" do
    # AS-4: Incomplete allocation prevents submit
    # ... implementation
  end

  test "system enforces min/max constraints per stat" do
    # AS-3: Visual constraint enforcement
    # ... implementation
  end
end
```
**Verify**: Test fails (red)

### T052 [P] - Add character_sheet settings validation to Question model
**File**: `app/models/question.rb`
```ruby
validate :character_sheet_settings_valid, if: :character_sheet?

private

def character_sheet_settings_valid
  return unless settings.present?

  total_points = settings["total_points"]
  stats = settings["stats"]

  errors.add(:settings, "must include total_points") if total_points.blank?
  errors.add(:settings, "total_points must be between 10 and 100") if total_points && !total_points.between?(10, 100)
  errors.add(:settings, "must include stats array") if stats.blank?
  errors.add(:settings, "must have between 3 and 10 stats") if stats && !stats.size.between?(3, 10)

  if stats.present?
    ids = stats.map { |s| s["id"] }
    errors.add(:settings, "stat IDs must be unique") if ids.uniq.size != ids.size
    errors.add(:settings, "each stat must have id, label, and description") if stats.any? { |s| s["id"].blank? || s["label"].blank? }

    max_sum = stats.sum { |s| s["max"] || 10 }
    errors.add(:settings, "total_points exceeds maximum possible allocation") if total_points && max_sum < total_points
  end
end
```
**Test**: Add to `test/models/question_test.rb`
**Verify**: Tests pass

### T053 [P] - Add character_sheet answer validation to Answer model
**File**: `app/models/answer.rb`
```ruby
validate :character_sheet_value_valid

# Update answer_matches_question_type
when "character_sheet"
  if question.required? && (jsonb_value.blank? || jsonb_value["allocations"].blank?)
    errors.add(:jsonb_value, "must include stat allocations")
  end

private

def character_sheet_value_valid
  return unless question&.character_sheet? && jsonb_value.present?

  total_points = question.settings["total_points"]
  stats = question.settings["stats"] || []
  allocations = jsonb_value["allocations"] || {}
  total_allocated = jsonb_value["total_allocated"]

  # Check all stats have allocations
  stat_ids = stats.map { |s| s["id"] }
  missing_stats = stat_ids - allocations.keys
  if missing_stats.any?
    errors.add(:jsonb_value, "missing allocations for stats: #{missing_stats.join(', ')}")
  end

  # Check no invalid stats
  invalid_stats = allocations.keys - stat_ids
  if invalid_stats.any?
    errors.add(:jsonb_value, "contains invalid stat IDs: #{invalid_stats.join(', ')}")
  end

  # Check each stat allocation within bounds
  stats.each do |stat|
    stat_id = stat["id"]
    allocation = allocations[stat_id]
    min = stat["min"] || 0
    max = stat["max"] || 10

    if allocation.present?
      if allocation < min
        errors.add(:jsonb_value, "#{stat_id} allocation must be at least #{min}")
      elsif allocation > max
        errors.add(:jsonb_value, "#{stat_id} allocation must be at most #{max}")
      end
    end
  end

  # Check total allocation (FR-018: must allocate ALL points)
  actual_total = allocations.values.sum
  if total_allocated != actual_total
    errors.add(:jsonb_value, "total_allocated (#{total_allocated}) does not match sum of allocations (#{actual_total})")
  end

  if actual_total != total_points
    errors.add(:jsonb_value, "must allocate all #{total_points} points (currently allocated: #{actual_total})")
  end
end
```
**Test**: Add to `test/models/answer_test.rb`
**Verify**: Tests pass

### T054 - Create service object for character sheet validation
**File**: `app/services/responses/validate_character_sheet.rb`
```ruby
module Responses
  class ValidateCharacterSheet
    def self.call(question:, allocations:)
      new(question: question, allocations: allocations).call
    end

    def initialize(question:, allocations:)
      @question = question
      @allocations = allocations
      @errors = []
    end

    def call
      validate_total_points
      validate_stat_constraints

      OpenStruct.new(valid?: @errors.empty?, errors: @errors)
    end

    private

    def validate_total_points
      total = @allocations.values.sum
      required = @question.settings["total_points"]

      if total != required
        @errors << "Must allocate all #{required} points (currently: #{total})"
      end
    end

    def validate_stat_constraints
      @question.settings["stats"].each do |stat|
        allocation = @allocations[stat["id"]]
        min = stat["min"] || 0
        max = stat["max"] || 10

        if allocation && (allocation < min || allocation > max)
          @errors << "#{stat['label']}: must be between #{min} and #{max}"
        end
      end
    end
  end
end
```
**Test**: `test/services/responses/validate_character_sheet_test.rb`
**Verify**: Service tests pass

### T055 - Create Stimulus controller for character sheet
**File**: `app/javascript/controllers/character_sheet_controller.js`
```javascript
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["stat", "remaining", "error", "submit"]
  static values = {
    totalPoints: { type: Number, default: 20 },
    minPerStat: { type: Number, default: 0 },
    maxPerStat: { type: Number, default: 10 }
  }

  connect() {
    this.updateBudget()
  }

  increment(event) {
    const statContainer = event.currentTarget.closest('[data-stat-id]')
    const statInput = statContainer.querySelector('input[type="number"]')
    const currentValue = parseInt(statInput.value) || 0

    if (currentValue >= this.maxPerStatValue) {
      this.showError(`Maximum ${this.maxPerStatValue} points per stat`)
      return
    }

    if (this.remainingPoints <= 0) {
      this.showError("No points remaining")
      return
    }

    statInput.value = currentValue + 1
    this.updateBudget()
  }

  decrement(event) {
    const statContainer = event.currentTarget.closest('[data-stat-id]')
    const statInput = statContainer.querySelector('input[type="number"]')
    const currentValue = parseInt(statInput.value) || 0

    if (currentValue <= this.minPerStatValue) {
      this.showError(`Minimum ${this.minPerStatValue} points per stat`)
      return
    }

    statInput.value = currentValue - 1
    this.updateBudget()
  }

  updateBudget() {
    const allocatedPoints = this.statTargets.reduce((sum, input) => {
      return sum + (parseInt(input.value) || 0)
    }, 0)

    this.remainingPoints = this.totalPointsValue - allocatedPoints
    this.remainingTarget.textContent = this.remainingPoints

    // Visual feedback
    if (this.remainingPoints === 0) {
      this.remainingTarget.classList.add("text-success", "font-bold")
      this.remainingTarget.classList.remove("text-error", "text-warning")
      this.submitTarget.disabled = false
      this.submitTarget.classList.remove("btn-disabled")
      this.hideError()
    } else if (this.remainingPoints < 0) {
      this.remainingTarget.classList.add("text-error", "font-bold")
      this.remainingTarget.classList.remove("text-success", "text-warning")
      this.submitTarget.disabled = true
      this.submitTarget.classList.add("btn-disabled")
      this.showError("Over budget!")
    } else {
      this.remainingTarget.classList.add("text-warning")
      this.remainingTarget.classList.remove("text-success", "text-error")
      this.submitTarget.disabled = true
      this.submitTarget.classList.add("btn-disabled")
    }

    this.updateHiddenField()
  }

  updateHiddenField() {
    const allocations = {}
    this.statTargets.forEach(input => {
      const statId = input.closest('[data-stat-id]').dataset.statId
      allocations[statId] = parseInt(input.value) || 0
    })

    const totalAllocated = Object.values(allocations).reduce((sum, val) => sum + val, 0)

    const hiddenField = this.element.querySelector('input[name="answer[jsonb_value]"]')
    hiddenField.value = JSON.stringify({
      allocations,
      total_allocated: totalAllocated
    })
  }

  submit(event) {
    if (this.remainingPoints !== 0) {
      event.preventDefault()
      this.showError(`Must allocate all ${this.totalPointsValue} points (${this.remainingPoints} remaining)`)
      return false
    }

    // Form will submit naturally
  }

  showError(message) {
    if (this.hasErrorTarget) {
      this.errorTarget.textContent = message
      this.errorTarget.classList.remove("hidden")
    }
  }

  hideError() {
    if (this.hasErrorTarget) {
      this.errorTarget.classList.add("hidden")
    }
  }
}
```
**Verify**: Controller connects

### T056 - Create view partial for character_sheet question type
**File**: `app/views/responses/_question_types/_character_sheet.html.erb`
```erb
<div data-controller="character-sheet"
     data-character-sheet-total-points-value="<%= question.settings['total_points'] %>"
     data-character-sheet-max-per-stat-value="10">

  <div class="card bg-base-100 mb-4">
    <div class="card-body">
      <h2 class="card-title"><%= question.text %></h2>
      <% if question.required? %>
        <span class="badge badge-error">Required</span>
      <% end %>
    </div>
  </div>

  <%= form_with model: [@response, @answer], url: response_path(@response.unique_token), method: :patch, data: { turbo_frame: "question_#{question.id}" } do |f| %>
    <%= f.hidden_field :question_id, value: question.id %>
    <%= f.hidden_field :jsonb_value, value: @answer.jsonb_value.to_json %>

    <div class="alert alert-info mb-4">
      <span>
        Allocate <strong><span data-character-sheet-target="remaining"><%= question.settings['total_points'] %></span></strong>
        points remaining
      </span>
    </div>

    <div class="alert alert-error hidden mb-4" data-character-sheet-target="error"></div>

    <div class="space-y-4">
      <% question.settings["stats"].each do |stat| %>
        <%
          existing_allocation = (@answer.jsonb_value || {}).dig("allocations", stat["id"]) || 0
        %>
        <div data-stat-id="<%= stat['id'] %>" class="card bg-base-200">
          <div class="card-body">
            <h3 class="card-title"><%= stat['label'] %></h3>
            <p class="text-sm opacity-70"><%= stat['description'] %></p>

            <div class="flex items-center gap-4 mt-2">
              <button type="button"
                      class="btn btn-circle btn-sm"
                      data-action="click->character-sheet#decrement">
                <span class="text-xl">−</span>
              </button>

              <input type="number"
                     value="<%= existing_allocation %>"
                     readonly
                     class="input input-bordered w-20 text-center font-bold text-xl"
                     data-character-sheet-target="stat">

              <button type="button"
                      class="btn btn-circle btn-sm"
                      data-action="click->character-sheet#increment">
                <span class="text-xl">+</span>
              </button>

              <progress class="progress progress-primary w-full"
                        value="<%= existing_allocation %>"
                        max="10"></progress>
            </div>
          </div>
        </div>
      <% end %>
    </div>

    <button type="submit"
            class="btn btn-primary btn-lg w-full mt-6 btn-disabled"
            data-character-sheet-target="submit"
            data-action="click->character-sheet#submit"
            disabled>
      Submit Character Sheet
    </button>
  <% end %>
</div>
```
**Verify**: Partial renders

### T057 - Create admin config form partial for character_sheet
**File**: `app/views/questions/_form_fields/_character_sheet_config.html.erb`
```erb
<div class="space-y-4">
  <div class="form-control">
    <%= label_tag :settings_total_points, "Total Points Budget (10-100)", class: "label" %>
    <%= number_field_tag :settings_total_points,
                         @question.settings["total_points"] || 20,
                         min: 10,
                         max: 100,
                         class: "input input-bordered" %>
  </div>

  <div id="stats-list" class="space-y-2">
    <label class="label">
      <span class="label-text font-semibold">Stats</span>
    </label>

    <% (@question.settings["stats"] || []).each_with_index do |stat, index| %>
      <div class="card bg-base-200" data-stat-index="<%= index %>">
        <div class="card-body py-3">
          <%= text_field_tag "settings_stats[#{index}][id]",
                             stat["id"],
                             placeholder: "stat-id",
                             class: "input input-sm input-bordered mb-2" %>
          <%= text_field_tag "settings_stats[#{index}][label]",
                             stat["label"],
                             placeholder: "Stat Label",
                             class: "input input-bordered mb-2" %>
          <%= text_area_tag "settings_stats[#{index}][description]",
                            stat["description"],
                            placeholder: "Description",
                            rows: 2,
                            class: "textarea textarea-bordered textarea-sm mb-2" %>

          <div class="grid grid-cols-2 gap-2">
            <%= number_field_tag "settings_stats[#{index}][min]",
                                 stat["min"] || 0,
                                 placeholder: "Min",
                                 class: "input input-sm input-bordered" %>
            <%= number_field_tag "settings_stats[#{index}][max]",
                                 stat["max"] || 10,
                                 placeholder: "Max",
                                 class: "input input-sm input-bordered" %>
          </div>

          <button type="button" class="btn btn-error btn-sm mt-2" onclick="this.closest('[data-stat-index]').remove()">
            Remove Stat
          </button>
        </div>
      </div>
    <% end %>
  </div>

  <button type="button" class="btn btn-primary btn-sm" onclick="addStat()">
    + Add Stat
  </button>

  <script>
    function addStat() {
      const index = document.querySelectorAll('[data-stat-index]').length
      const html = `
        <div class="card bg-base-200" data-stat-index="${index}">
          <div class="card-body py-3">
            <input type="text" name="settings_stats[${index}][id]" placeholder="stat-id" class="input input-sm input-bordered mb-2">
            <input type="text" name="settings_stats[${index}][label]" placeholder="Stat Label" class="input input-bordered mb-2">
            <textarea name="settings_stats[${index}][description]" placeholder="Description" rows="2" class="textarea textarea-bordered textarea-sm mb-2"></textarea>
            <div class="grid grid-cols-2 gap-2">
              <input type="number" name="settings_stats[${index}][min]" value="0" placeholder="Min" class="input input-sm input-bordered">
              <input type="number" name="settings_stats[${index}][max]" value="10" placeholder="Max" class="input input-sm input-bordered">
            </div>
            <button type="button" class="btn btn-error btn-sm mt-2" onclick="this.closest('[data-stat-index]').remove()">Remove Stat</button>
          </div>
        </div>
      `
      document.getElementById('stats-list').insertAdjacentHTML('beforeend', html)
    }
  </script>
</div>
```
**Verify**: Admin form works

### T058 - Update responses/edit view for character_sheet
**File**: `app/views/responses/edit.html.erb`
```erb
<% when "character_sheet" %>
  <%= render "responses/question_types/character_sheet",
             question: @question,
             answer: @answer,
             response: @response %>
```
**Verify**: Renders correctly

### T059 - Manual UI testing for character sheet
**Steps**:
1. Create character_sheet question with 4 stats, 20 points
2. Increment/decrement points
3. Verify remaining budget updates in real-time
4. Try to submit with incomplete allocation - verify blocked
5. Complete allocation - verify submit enabled
6. Save and verify persisted
7. Test over-allocation prevention

**Verify**: All acceptance scenarios pass

**Checkpoint Phase 8**: ✅ User Story 6 complete - Character Sheet functional

---

## Phase 9: Polish & Integration

**Goal**: Cross-cutting concerns, admin UI improvements, documentation

**Checkpoint**: ✓ Full feature integration complete

### T060 [P] - Create service object for saving answers
**File**: `app/services/responses/save_answer.rb`
```ruby
module Responses
  class SaveAnswer
    def self.call(response:, question:, answer_params:)
      new(response: response, question: question, answer_params: answer_params).call
    end

    def initialize(response:, question:, answer_params:)
      @response = response
      @question = question
      @answer_params = answer_params
    end

    def call
      answer = @response.answers.find_or_initialize_by(question: @question)

      # Clear unused value fields based on question type
      clear_unused_fields(answer)

      # Assign value to appropriate field
      assign_value(answer)

      if answer.save
        OpenStruct.new(success?: true, answer: answer)
      else
        OpenStruct.new(success?: false, errors: answer.errors)
      end
    end

    private

    def clear_unused_fields(answer)
      answer.text_value = nil
      answer.selected_option_id = nil
      answer.selected_option_ids = []
      answer.boolean_value = nil
      answer.numeric_value = nil
      answer.jsonb_value = {}
    end

    def assign_value(answer)
      case @question.question_type
      when "text"
        answer.text_value = @answer_params[:text_value]
      when "single_choice"
        answer.selected_option_id = @answer_params[:selected_option_id]
      when "multiple_choice"
        answer.selected_option_ids = @answer_params[:selected_option_ids]
      when "yes_no", "swipe_yes_no"
        answer.boolean_value = @answer_params[:boolean_value]
      when "slider"
        answer.numeric_value = @answer_params[:numeric_value]
      when "card_sort", "energy_map", "emoji_reaction", "character_sheet"
        answer.jsonb_value = JSON.parse(@answer_params[:jsonb_value]) if @answer_params[:jsonb_value].is_a?(String)
        answer.jsonb_value = @answer_params[:jsonb_value] if @answer_params[:jsonb_value].is_a?(Hash)
      end
    end
  end
end
```
**Test**: `test/services/responses/save_answer_test.rb`
**Verify**: Service tests pass

### T061 [P] - Update ResponsesController to use SaveAnswer service
**File**: `app/controllers/responses_controller.rb`
```ruby
def update
  @response = Response.find_by!(unique_token: params[:unique_token])
  @question = Question.find(answer_params[:question_id])

  result = Responses::SaveAnswer.call(
    response: @response,
    question: @question,
    answer_params: answer_params
  )

  if result.success?
    # Navigate to next/previous question
    direction = params[:direction] || "next"
    @next_question = find_next_question(@question, direction)

    if @next_question
      redirect_to edit_response_path(@response.unique_token, question_id: @next_question.id)
    else
      redirect_to edit_response_path(@response.unique_token, direction: 'submit_prompt')
    end
  else
    @answer = result.answer
    render :edit, status: :unprocessable_entity
  end
end

private

def find_next_question(current_question, direction)
  questions = @response.questionnaire.questions.order(:position)

  if direction == "next"
    questions.where("position > ?", current_question.position).first
  elsif direction == "previous"
    questions.where("position < ?", current_question.position).last
  end
end
```
**Verify**: Controller uses service

### T062 [P] - Add dynamic question type config loading route
**File**: `config/routes.rb`
```ruby
resources :questions, only: [:update, :destroy] do
  collection do
    get :config_fields
  end
end
```
**Verify**: Route exists

### T063 [P] - Add QuestionsController#config_fields action
**File**: `app/controllers/questions_controller.rb`
```ruby
def config_fields
  @question = Question.new(question_type: params[:type])

  render partial: "questions/form_fields/#{params[:type]}_config",
         locals: { question: @question },
         layout: false
end
```
**Verify**: Action returns partial

### T064 [P] - Create Stimulus controller for dynamic question form
**File**: `app/javascript/controllers/question_form_controller.js`
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
**Verify**: Controller loads config forms dynamically

### T065 - Add comprehensive model tests for all question types
**File**: `test/models/question_test.rb`
```ruby
# Add tests for each new question type validation
test "slider question validates settings" do
  question = Question.new(
    category: categories(:default),
    text: "Test",
    question_type: "slider",
    settings: { min_value: 10, max_value: 5 }  # Invalid: min > max
  )

  assert_not question.valid?
  assert_includes question.errors[:settings], "min_value must be less than max_value"
end

# ... tests for swipe_yes_no, card_sort, energy_map, emoji_reaction, character_sheet
```
**Verify**: All model validations tested

### T066 - Add comprehensive answer tests for all question types
**File**: `test/models/answer_test.rb`
```ruby
# Add tests for each answer type validation
test "card_sort answer rejects invalid card IDs" do
  question = questions(:card_sort)
  answer = Answer.new(
    response: responses(:one),
    question: question,
    jsonb_value: {
      ranked: [{ id: "invalid-card", rank: 1 }],
      unranked: []
    }
  )

  assert_not answer.valid?
  assert_includes answer.errors[:jsonb_value].join, "invalid card IDs"
end

# ... tests for slider, energy_map, emoji_reaction, character_sheet
```
**Verify**: All answer validations tested

### T067 [P] - Add controller tests for all question types
**File**: `test/controllers/responses_controller_test.rb`
```ruby
# Add tests for each question type persistence
test "should save energy map answer with null periods" do
  @energy_question = questions(:energy_map)

  patch response_path(@response.unique_token), params: {
    answer: {
      question_id: @energy_question.id,
      jsonb_value: {
        data_points: [
          { period: "Monday", value: 7 },
          { period: "Tuesday", value: null }
        ]
      }.to_json
    }
  }

  assert_response :success
  answer = @response.answers.find_by(question: @energy_question)
  assert_equal 2, answer.jsonb_value["data_points"].size
end

# ... tests for other types
```
**Verify**: Controller tests cover all types

### T068 - Create seed data with example questions
**File**: `db/seeds.rb`
```ruby
# Add example questions for each new type
puts "Creating example questions..."

org = Organization.first_or_create!(name: "Demo Organization", unique_token: SecureRandom.hex(8))
questionnaire = org.questionnaires.first_or_create!(
  title: "Work Style Assessment",
  unique_token: SecureRandom.hex(8)
)
category = questionnaire.categories.first_or_create!(name: "Preferences", position: 1)

# Slider example
category.questions.create!(
  text: "How introverted or extroverted are you?",
  question_type: "slider",
  position: 1,
  settings: {
    min_value: 1,
    max_value: 10,
    labels: { "1" => "Very Introverted", "5" => "Balanced", "10" => "Very Extroverted" }
  }
)

# ... examples for other types
puts "✓ Example questions created"
```
**Verify**: Seeds run successfully

### T069 - Update README with new question types
**File**: `README.md`
```markdown
## Question Types

This application supports 10 question types:

### Original Types
- **Text**: Free-form text input
- **Single Choice**: Radio buttons
- **Multiple Choice**: Checkboxes
- **Yes/No**: Boolean choice

### Enhanced Types (Feature 002)
- **Slider**: Numeric scale with labeled endpoints (e.g., 1-10)
- **Swipe Yes/No**: Tinder-like swipe gestures for binary choices
- **Card Sort**: Drag-and-drop ranking of multiple options
- **Energy Map**: Interactive timeline graph for temporal data
- **Emoji Reaction**: Emoji-based sentiment selection
- **Character Sheet**: Point allocation across multiple stats with budget constraints

See [specs/002-more-input-methods/](./specs/002-more-input-methods/) for detailed documentation.
```
**Verify**: README updated

### T070 - Add CSS animations to application stylesheet
**File**: `app/assets/stylesheets/application.tailwind.css`
```css
/* Swipe gesture animations */
.swipe-container {
  position: relative;
  touch-action: none;
  --swipe-opacity: 0;
  --swipe-color: transparent;
}

.swipe-indicator {
  position: absolute;
  top: 50%;
  transform: translateY(-50%);
  font-size: 3rem;
  font-weight: bold;
  opacity: var(--swipe-opacity);
  transition: opacity 0.2s ease;
  pointer-events: none;
}

/* Emoji reaction animations */
@keyframes bounce {
  0%, 100% { transform: scale(1.25) translateY(0); }
  50% { transform: scale(1.35) translateY(-10px); }
}

/* Card sorting visual feedback */
.sortable-ghost {
  opacity: 0.4;
}

.sortable-drag {
  transform: rotate(5deg);
}
```
**Verify**: Styles applied

### T071 - Run full test suite
**Command**: `rails test`
**Verify**: All tests pass (green)

### T072 - Run Rubocop for code style
**Command**: `bundle exec rubocop`
**Verify**: No violations

### T073 - Manual end-to-end testing
**Steps**:
1. Create questionnaire with all 6 new question types
2. Complete full questionnaire as employee
3. Navigate forward and backward between questions
4. Verify all answers persist correctly
5. Submit questionnaire
6. View profile

**Verify**: Complete user flow works

---

## Dependencies Graph

```
Phase 1 (Setup)
    ↓
Phase 2 (Foundation) ← Required by ALL user stories
    ↓
    ├─→ Phase 3 (User Story 1 - Slider) [P1] ← MVP
    ├─→ Phase 4 (User Story 2 - Swipe) [P2]
    ├─→ Phase 5 (User Story 3 - Card Sort) [P2]
    ├─→ Phase 6 (User Story 4 - Energy Map) [P3]
    ├─→ Phase 7 (User Story 5 - Emoji) [P3]
    └─→ Phase 8 (User Story 6 - Character Sheet) [P3]
    ↓
Phase 9 (Polish)
```

**User Story Independence**: Phases 3-8 have NO dependencies on each other (all depend only on Phases 1-2)

---

## Parallel Execution Examples

### MVP Only (User Story 1)
```
Team Member 1: T010 (test) + T011 (Question validation) + T013 (Stimulus)
Team Member 2: T012 (Answer validation) + T014 (view partial)
Team Member 3: T015 (admin form) + T016 (controller test)
```

### All P2 Stories (Stories 2-3)
```
Agent 1: Phase 4 (Swipe) - T019-T026
Agent 2: Phase 5 (Card Sort) - T027-T034
```

### All P3 Stories (Stories 4-6)
```
Agent 1: Phase 6 (Energy Map) - T035-T042
Agent 2: Phase 7 (Emoji) - T043-T050
Agent 3: Phase 8 (Character Sheet) - T051-T059
```

### Polish Phase
```
Agent 1: T060-T064 (Services + routes)
Agent 2: T065-T067 (Tests)
Agent 3: T068-T070 (Seeds + docs + styles)
```

---

## Testing Strategy

### TDD Workflow (MANDATORY per Constitution)
1. **Write Test First** (Red) - Task includes writing failing test
2. **Implement Feature** (Green) - Make test pass with minimal code
3. **Refactor** (Green) - Improve code while tests stay green

### Test Coverage by Phase
- **Phase 3-8** (User Stories): System test + Model tests + Controller test per story
- **Phase 9** (Polish): Service object tests, integration tests

### Test Organization
```
test/
├── models/
│   ├── question_test.rb         # All 6 question type validations
│   └── answer_test.rb           # All 6 answer type validations
├── controllers/
│   ├── responses_controller_test.rb  # Answer persistence for all types
│   └── questions_controller_test.rb  # Admin config for all types
├── services/
│   ├── responses/
│   │   ├── save_answer_test.rb
│   │   └── validate_character_sheet_test.rb
│   └── questions/
│       └── validate_configuration_test.rb
└── system/
    ├── slider_input_test.rb          # User Story 1
    ├── swipe_yes_no_test.rb          # User Story 2
    ├── card_sorting_test.rb          # User Story 3
    ├── energy_mapping_test.rb        # User Story 4
    ├── emoji_reactions_test.rb       # User Story 5
    └── character_sheet_test.rb       # User Story 6
```

---

## MVP Recommendation

**Suggested MVP**: Phase 3 only (User Story 1 - Slider)

**Justification**:
- Simplest implementation (native HTML5 range input)
- 0 KB bundle impact
- Provides immediate value for dimensional feedback
- Fully functional and testable independently
- 13 tasks (can be completed in 1-2 days with TDD)

**Post-MVP Increments**:
- **Increment 1**: Add Phases 4-5 (Swipe + Card Sort - P2 stories)
- **Increment 2**: Add Phases 6-8 (Energy, Emoji, Character Sheet - P3 stories)
- **Increment 3**: Phase 9 (Polish)

---

## Task Summary

| Phase | Description | Task Count | Parallelizable | Priority | Story |
|-------|-------------|------------|----------------|----------|-------|
| 1 | Setup | 4 | 3 [P] | - | Setup |
| 2 | Foundation | 5 | 0 | - | Foundation |
| 3 | Slider | 9 | 3 [P] | P1 | US1 |
| 4 | Swipe Yes/No | 8 | 2 [P] | P2 | US2 |
| 5 | Card Sort | 8 | 2 [P] | P2 | US3 |
| 6 | Energy Map | 8 | 2 [P] | P3 | US4 |
| 7 | Emoji Reactions | 7 | 2 [P] | P3 | US5 |
| 8 | Character Sheet | 9 | 2 [P] | P3 | US6 |
| 9 | Polish | 14 | 7 [P] | - | Integration |
| **Total** | | **72** | **23 [P]** | | |

---

## Next Steps

1. ✅ Review this tasks.md for completeness
2. ⏭️ Begin implementation with Phase 1 (Setup - 4 tasks)
3. ⏭️ Complete Phase 2 (Foundation - 5 tasks) - BLOCKS all user stories
4. ⏭️ Implement MVP: Phase 3 only (User Story 1 - 9 tasks)
5. ⏭️ Deploy MVP for early user feedback
6. ⏭️ Iterate: Add remaining user stories in priority order

**Development Mode**: TDD (Test-Driven Development) - Write tests first, then implementation
