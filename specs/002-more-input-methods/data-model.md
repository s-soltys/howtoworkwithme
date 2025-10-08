# Data Model: Enhanced Question Input Methods

**Feature**: 002-more-input-methods
**Date**: 2025-10-08
**Phase**: Phase 1 - Design

## Overview

This document defines the data model extensions required to support six new question input methods. The design leverages the existing schema's polymorphic Answer fields and Question.settings JSONB field to minimize database changes while maintaining data integrity.

---

## Existing Schema (Relevant Portions)

### Questions Table

```ruby
create_table "questions" do |t|
  t.bigint "category_id", null: false
  t.string "question_type", null: false      # ENUM - will be extended
  t.text "text", null: false
  t.integer "position", null: false
  t.boolean "required", default: true, null: false
  t.jsonb "settings", default: {}           # Configuration for each type
  t.datetime "created_at", null: false
  t.datetime "updated_at", null: false
  t.index ["category_id", "position"]
  t.index ["category_id"]
end
```

**Current Enum Values**: `text`, `single_choice`, `multiple_choice`, `yes_no`

### Answers Table

```ruby
create_table "answers" do |t|
  t.bigint "response_id", null: false
  t.bigint "question_id", null: false
  t.text "text_value"                       # For text questions
  t.integer "selected_option_id"            # For single_choice
  t.integer "selected_option_ids", default: [], array: true  # For multiple_choice
  t.boolean "boolean_value"                 # For yes_no
  t.datetime "created_at", null: false
  t.datetime "updated_at", null: false
  t.index ["response_id", "question_id"], unique: true
  t.index ["response_id"]
  t.index ["question_id"]
  t.index ["selected_option_ids"], using: :gin
end
```

---

## Required Schema Changes

### Migration 1: Add New Question Types

**File**: `db/migrate/TIMESTAMP_add_new_question_input_types.rb`

```ruby
class AddNewQuestionInputTypes < ActiveRecord::Migration[8.0]
  def up
    # Add new enum values to question_type
    # Rails 8 approach: no enum type in DB, just string values

    # Validate existing data before migration
    Question.where.not(question_type: ['text', 'single_choice', 'multiple_choice', 'yes_no']).each do |q|
      raise "Invalid question_type found: #{q.question_type} for Question ID #{q.id}"
    end

    # No schema change needed - enum is managed in model
    # This migration serves as documentation and checkpoint
  end

  def down
    # Remove questions with new types before downgrading
    Question.where(question_type: ['slider', 'swipe_yes_no', 'card_sort', 'energy_map', 'emoji_reaction', 'character_sheet']).destroy_all
  end
end
```

**Model Change** (`app/models/question.rb`):

```ruby
enum :question_type, {
  text: "text",
  single_choice: "single_choice",
  multiple_choice: "multiple_choice",
  yes_no: "yes_no",
  slider: "slider",                          # NEW
  swipe_yes_no: "swipe_yes_no",              # NEW
  card_sort: "card_sort",                    # NEW
  energy_map: "energy_map",                  # NEW
  emoji_reaction: "emoji_reaction",          # NEW
  character_sheet: "character_sheet"         # NEW
}
```

### Migration 2: Add Numeric and JSONB Value Fields to Answers

**File**: `db/migrate/TIMESTAMP_add_value_fields_to_answers.rb`

```ruby
class AddValueFieldsToAnswers < ActiveRecord::Migration[8.0]
  def change
    # For slider, character sheet numeric values
    add_column :answers, :numeric_value, :integer

    # For complex data: card rankings, energy maps, character sheets
    add_column :answers, :jsonb_value, :jsonb, default: {}

    # Add index for JSONB queries (optional but recommended)
    add_index :answers, :jsonb_value, using: :gin
  end
end
```

**Rationale**:
- `numeric_value`: Simple integer for slider values
- `jsonb_value`: Flexible structure for complex data (rankings, temporal data, stat allocations)
- GIN index on `jsonb_value` enables efficient queries on nested JSON data

---

## Data Structures by Question Type

### 1. Slider

**Question.settings Structure:**
```ruby
{
  min_value: 1,                    # Integer, minimum slider value
  max_value: 10,                   # Integer, maximum slider value
  step: 1,                         # Integer, step increment (default: 1)
  labels: {                        # Hash of value => label mappings
    1: "Strongly Disagree",
    5: "Neutral",
    10: "Strongly Agree"
  },
  default_value: 5                 # Integer, optional initial value
}
```

**Answer Storage:**
- **Field**: `numeric_value`
- **Type**: Integer
- **Example**: `42` (value between min_value and max_value)
- **Validation**: `min_value <= numeric_value <= max_value`

**Validations:**
```ruby
# In Question model
validates :settings, presence: true, if: :slider?
validate :slider_settings_valid, if: :slider?

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

---

### 2. Swipe Yes/No

**Question.settings Structure:**
```ruby
{
  swipe_threshold: 0.3,            # Float, percentage of screen width (0.0-1.0)
  positive_label: "Yes",           # String, label for right swipe
  negative_label: "No",            # String, label for left swipe
  animation_duration: 300          # Integer, milliseconds for animation
}
```

**Answer Storage:**
- **Field**: `boolean_value`
- **Type**: Boolean
- **Example**: `true` (right swipe = yes), `false` (left swipe = no)
- **Validation**: Same as existing yes_no type

**Note**: Uses existing `boolean_value` field from yes_no questions. Settings provide UX customization only.

---

### 3. Card Sort

**Question.settings Structure:**
```ruby
{
  cards: [                         # Array of card objects
    {
      id: "card-1",               # String, unique identifier
      text: "Work-life balance",   # String, card display text
      description: "Optional longer description"  # String, optional
    },
    {
      id: "card-2",
      text: "Career growth"
    },
    # ... 3-15 cards total
  ],
  allow_partial_ranking: true      # Boolean, per FR-008 clarification
}
```

**Answer Storage:**
- **Field**: `jsonb_value`
- **Type**: JSONB
- **Structure**:
```ruby
{
  ranked: [                        # Array, ordered list of ranked cards
    { id: "card-2", rank: 1 },
    { id: "card-1", rank: 2 }
  ],
  unranked: ["card-3", "card-4"]  # Array, cards not ranked (if allow_partial_ranking)
}
```
- **Validation**:
  - All card IDs in answer must exist in question.settings.cards
  - No duplicate IDs in ranked or unranked arrays
  - Ranks must be sequential (1, 2, 3, ...)

**Validations:**
```ruby
# In Question model
validates :settings, presence: true, if: :card_sort?
validate :card_sort_settings_valid, if: :card_sort?

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

---

### 4. Energy Map

**Question.settings Structure:**
```ruby
{
  time_periods: [                  # Array of time period labels
    "Monday Morning",
    "Monday Afternoon",
    "Tuesday Morning",
    "Tuesday Afternoon",
    # ... custom periods
  ],
  scale_min: 0,                    # Integer, minimum energy level
  scale_max: 10,                   # Integer, maximum energy level
  scale_labels: {                  # Hash, optional semantic labels
    0: "Exhausted",
    5: "Moderate",
    10: "Energized"
  },
  y_axis_label: "Energy Level",    # String, chart Y-axis label
  allow_partial: true              # Boolean, per FR-013 clarification (allow null periods)
}
```

**Answer Storage:**
- **Field**: `jsonb_value`
- **Type**: JSONB
- **Structure**:
```ruby
{
  data_points: [
    { period: "Monday Morning", value: 7 },
    { period: "Monday Afternoon", value: 5 },
    { period: "Tuesday Morning", value: null },  # Empty period (per FR-013)
    { period: "Tuesday Afternoon", value: 8 }
  ]
}
```
- **Validation**:
  - All periods in answer must exist in question.settings.time_periods
  - Values must be between scale_min and scale_max, or null
  - Each period can appear only once

**Validations:**
```ruby
# In Question model
validates :settings, presence: true, if: :energy_map?
validate :energy_map_settings_valid, if: :energy_map?

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

---

### 5. Emoji Reaction

**Question.settings Structure:**
```ruby
{
  emoji_options: [                 # Array of emoji option objects
    {
      emoji: "😍",                # String, Unicode emoji
      label: "Love it",           # String, semantic label
      value: 5                    # Integer, optional numeric value for analysis
    },
    {
      emoji: "😊",
      label: "Like it",
      value: 4
    },
    # ... 3-10 emoji options
  ]
}
```

**Answer Storage:**
- **Field**: `jsonb_value`
- **Type**: JSONB
- **Structure**:
```ruby
{
  emoji: "😍",                     # String, selected emoji
  label: "Love it",                # String, semantic label
  value: 5                         # Integer, optional numeric value
}
```
- **Validation**: Selected emoji must exist in question.settings.emoji_options

**Validations:**
```ruby
# In Question model
validates :settings, presence: true, if: :emoji_reaction?
validate :emoji_reaction_settings_valid, if: :emoji_reaction?

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

---

### 6. Character Sheet

**Question.settings Structure:**
```ruby
{
  total_points: 20,                # Integer, point budget
  stats: [                         # Array of stat objects
    {
      id: "leadership",           # String, unique identifier
      label: "Leadership",         # String, display name
      description: "Ability to guide and inspire others",  # String
      min: 0,                     # Integer, minimum points (default: 0)
      max: 10                     # Integer, maximum points per stat
    },
    {
      id: "technical",
      label: "Technical Skills",
      description: "Coding and system design",
      min: 0,
      max: 10
    },
    # ... 3-10 stats total
  ],
  require_full_allocation: true    # Boolean, per FR-018/FR-020 (must allocate all points)
}
```

**Answer Storage:**
- **Field**: `jsonb_value`
- **Type**: JSONB
- **Structure**:
```ruby
{
  allocations: {                   # Hash of stat_id => points
    "leadership": 5,
    "technical": 8,
    "creative": 3,
    "communication": 4
  },
  total_allocated: 20              # Integer, sum of all allocations (for validation)
}
```
- **Validation**:
  - All stat IDs in answer must exist in question.settings.stats
  - Each stat allocation must be between min and max for that stat
  - total_allocated must equal total_points (per FR-018)
  - All stats must have an allocation (even if 0)

**Validations:**
```ruby
# In Question model
validates :settings, presence: true, if: :character_sheet?
validate :character_sheet_settings_valid, if: :character_sheet?

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

---

## Answer Model Updates

### Extended Validation Logic

**File**: `app/models/answer.rb`

```ruby
class Answer < ApplicationRecord
  # Associations
  belongs_to :response
  belongs_to :question
  belongs_to :selected_option, class_name: "QuestionOption", optional: true

  # Validations
  validate :answer_matches_question_type
  validate :selected_options_exist
  validate :slider_value_valid
  validate :card_sort_value_valid
  validate :energy_map_value_valid
  validate :emoji_reaction_value_valid
  validate :character_sheet_value_valid

  private

  def answer_matches_question_type
    return unless question

    case question.question_type
    when "text"
      # ... existing validation ...
    when "single_choice"
      # ... existing validation ...
    when "multiple_choice"
      # ... existing validation ...
    when "yes_no"
      # ... existing validation ...
    when "slider"
      if question.required? && numeric_value.blank?
        errors.add(:numeric_value, "must be present for required slider questions")
      end
    when "swipe_yes_no"
      if question.required? && boolean_value.nil?
        errors.add(:boolean_value, "must be present for required swipe yes/no questions")
      end
    when "card_sort"
      if question.required? && (jsonb_value.blank? || jsonb_value["ranked"].blank?)
        errors.add(:jsonb_value, "must include at least one ranked card for required card sort questions")
      end
    when "energy_map"
      if question.required? && (jsonb_value.blank? || jsonb_value["data_points"].blank?)
        errors.add(:jsonb_value, "must include at least one data point for required energy map questions")
      end
    when "emoji_reaction"
      if question.required? && (jsonb_value.blank? || jsonb_value["emoji"].blank?)
        errors.add(:jsonb_value, "must include selected emoji for required emoji reaction questions")
      end
    when "character_sheet"
      if question.required? && (jsonb_value.blank? || jsonb_value["allocations"].blank?)
        errors.add(:jsonb_value, "must include stat allocations for required character sheet questions")
      end
    end
  end

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

  def emoji_reaction_value_valid
    return unless question&.emoji_reaction? && jsonb_value.present?

    valid_emojis = question.settings["emoji_options"]&.map { |o| o["emoji"] } || []
    selected_emoji = jsonb_value["emoji"]

    unless valid_emojis.include?(selected_emoji)
      errors.add(:jsonb_value, "selected emoji is not a valid option")
    end
  end

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

    # Check each stat allocation is within bounds
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

    # Check total allocation (per FR-018: must allocate all points)
    actual_total = allocations.values.sum
    if total_allocated != actual_total
      errors.add(:jsonb_value, "total_allocated (#{total_allocated}) does not match sum of allocations (#{actual_total})")
    end

    if actual_total != total_points
      errors.add(:jsonb_value, "must allocate all #{total_points} points (currently allocated: #{actual_total})")
    end
  end

  def selected_options_exist
    # ... existing validation for single_choice and multiple_choice ...
  end
end
```

---

## Entity Relationship Summary

```
Questionnaire (1) ──── (many) Category ──── (many) Question
                                                      │
                                                      │ question_type (enum)
                                                      │ settings (jsonb)
                                                      │
                                                      └─── (many) QuestionOption
                                                               (for single_choice, multiple_choice only)

Employee ──── (many) Response ──── (many) Answer
                                            │
                                            ├── question_id (FK)
                                            ├── text_value
                                            ├── selected_option_id
                                            ├── selected_option_ids[]
                                            ├── boolean_value
                                            ├── numeric_value        [NEW]
                                            └── jsonb_value          [NEW]
```

---

## Storage Efficiency Analysis

| Question Type | Settings Size (avg) | Answer Size (avg) | Storage Field |
|---------------|---------------------|-------------------|---------------|
| Slider | ~200 bytes | 4 bytes | numeric_value |
| Swipe Yes/No | ~100 bytes | 1 byte | boolean_value |
| Card Sort (10 cards) | ~1.5 KB | ~500 bytes | jsonb_value |
| Energy Map (7 periods) | ~800 bytes | ~350 bytes | jsonb_value |
| Emoji Reaction (5 options) | ~400 bytes | ~100 bytes | jsonb_value |
| Character Sheet (5 stats) | ~1 KB | ~200 bytes | jsonb_value |

**Total New Fields**: 2 columns (numeric_value, jsonb_value) + 2 indexes
**Impact**: Minimal schema changes, leverages PostgreSQL JSONB performance

---

## Data Migration Considerations

### Backward Compatibility

- Existing questions (text, single_choice, multiple_choice, yes_no) are unaffected
- New fields (numeric_value, jsonb_value) default to NULL for existing answers
- No data migration needed for existing records

### Forward Compatibility

- Adding new question types in the future: extend enum + add validation logic
- New answer structures: add to jsonb_value (no schema migration needed)
- Settings schema versioning: include `schema_version: 1` in settings for future changes

---

## Next Steps

1. Generate API contracts (controller actions, parameters, responses)
2. Generate quickstart.md (developer onboarding guide)
3. Update agent context with data model decisions
