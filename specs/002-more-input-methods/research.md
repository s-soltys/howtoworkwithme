# Research Report: Enhanced Question Input Methods

**Feature**: 002-more-input-methods
**Date**: 2025-10-08
**Phase**: Phase 0 - Technology Research

## Overview

This document captures research findings for implementing six new interactive question input methods in the Rails 8.0.3 questionnaire application. All recommendations prioritize lightweight solutions that integrate seamlessly with the existing Stimulus + Hotwire + DaisyUI stack.

---

## 1. Drag-and-Drop Card Sorting

### Decision
**SortableJS** with custom Stimulus controller

### Rationale
- **Community Adoption**: 2.1M weekly downloads, 30.7K GitHub stars, dominant in Rails ecosystem
- **Active Maintenance**: Last updated 10 months ago (vs dragula abandoned 5 years ago)
- **Excellent Touch Support**: Built-in mobile optimization with `delayOnTouchOnly: true` and `touchStartThreshold` configuration
- **Lightweight**: 15.5 kB minified + gzipped (smallest fully-featured option)
- **Rails-Friendly**: Works with importmaps (no bundler), integrates with Turbo Frames/Streams, pairs with `acts_as_list` gem
- **Performance**: CSS transform-based animations

### Integration Approach

**Setup:**
```bash
bin/importmap pin sortablejs
```

**Stimulus Controller** (`app/javascript/controllers/card_sort_controller.js`):
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
  }

  onEnd(event) {
    // Dispatch custom event with new order
    const order = Array.from(this.element.children).map(el => el.dataset.id)
    this.dispatch("sorted", { detail: { order } })
  }

  disconnect() {
    if (this.sortable) this.sortable.destroy()
  }
}
```

**HTML Usage:**
```erb
<div data-controller="card-sort"
     data-action="card-sort:sorted->responses#saveRanking"
     class="space-y-4">
  <% @cards.each do |card| %>
    <div class="card bg-base-100 shadow-xl cursor-move" data-id="<%= card.id %>">
      <div class="card-body">
        <p><%= card.text %></p>
      </div>
    </div>
  <% end %>
</div>
```

### Alternatives Considered
- **Native HTML5 Drag and Drop**: No touch support, browser inconsistencies, too much boilerplate
- **dragula.js**: Abandoned since 2020, poor mobile scrolling
- **interact.js**: Abandoned 9 years ago, 2x larger bundle (30.1 kB), overkill for card sorting
- **Shopify Draggable**: Less Rails community adoption, more complex API

---

## 2. Swipe Gesture Detection (Tinder-like Yes/No)

### Decision
**Native Pointer Events API** in custom Stimulus controller

### Rationale
- **Zero Dependencies**: 0 KB bundle size, perfect for importmap setup
- **Unified Touch + Mouse**: Single event model for `pointerdown`, `pointermove`, `pointerup`, `pointercancel`
- **Excellent Browser Support**: Safari iOS 13+ (Oct 2019), all modern browsers, no polyfill needed
- **Perfect Stimulus Integration**: Action syntax works seamlessly, clean separation of concerns
- **Rails/Hotwire Compatible**: No interference with Turbo Frames or View Transitions
- **Performance**: Native browser APIs, no library overhead

### Implementation Notes

**Stimulus Controller** (`app/javascript/controllers/swipe_controller.js`):
```javascript
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = {
    threshold: { type: Number, default: 0.3 } // 30% screen width
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
    event.preventDefault() // Prevent text selection
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

  handleSwipe(direction) {
    const offset = direction === 'right' ? window.innerWidth : -window.innerWidth
    this.cardTarget.style.transform = `translateX(${offset}px)`

    this.dispatch('swiped', {
      detail: { answer: direction === 'right' ? 'yes' : 'no' }
    })
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

**HTML Usage:**
```erb
<div data-controller="swipe"
     data-swipe-threshold-value="0.3"
     data-action="pointerdown->swipe#start
                  pointermove->swipe#move
                  pointerup->swipe#end
                  pointercancel->swipe#cancel
                  swipe:swiped->question#handleAnswer"
     class="swipe-container">

  <div data-swipe-target="card" class="question-card card bg-base-100">
    <div class="card-body">
      <p><%= @question.text %></p>
    </div>
  </div>

  <div class="swipe-indicator swipe-indicator--yes">YES ✓</div>
  <div class="swipe-indicator swipe-indicator--no">NO ✗</div>
</div>
```

**CSS** (DaisyUI compatible):
```css
.swipe-container {
  position: relative;
  touch-action: none; /* Prevent browser pan/zoom */
  --swipe-opacity: 0;
  --swipe-color: transparent;
}

.question-card {
  transition: transform 0.3s ease-out;
  cursor: grab;
}

.question-card:active { cursor: grabbing; }

.swipe-indicator {
  position: absolute;
  top: 50%;
  transform: translateY(-50%);
  font-size: 2rem;
  font-weight: bold;
  opacity: var(--swipe-opacity);
  transition: opacity 0.2s ease;
  pointer-events: none;
}

.swipe-indicator--yes {
  right: 2rem;
  color: oklch(var(--su)); /* DaisyUI success */
}

.swipe-indicator--no {
  left: 2rem;
  color: oklch(var(--er)); /* DaisyUI error */
}
```

**Key Implementation Points:**
- Set `touch-action: none` on swipeable elements to prevent browser scrolling/zooming
- Use `event.preventDefault()` in `pointerdown` to prevent text selection
- Use CSS `transform` (GPU-accelerated) for smooth 60fps animations
- Add `pointercancel` handler for when user switches apps on mobile
- Add keyboard alternatives: ArrowLeft/ArrowRight for accessibility

### Alternatives Considered
- **Hammer.js**: Abandoned 9 years ago, not recommended for new projects
- **interact.js**: 30.1 KB bundle (overkill), abandoned, but still maintained with 84 open issues
- **ZingTouch**: 7.05 KB, limited maintenance, another dependency to manage
- **Native Touch Events API**: Good but requires separate mouse handling, Pointer Events supersedes this

---

## 3. Interactive Energy/Mood Mapping Graph

### Decision
**Chart.js** (v4.x) + **chartjs-plugin-dragdata** (v2.x)

### Rationale
- **Smallest Bundle Size**: ~11 KB gzipped (lightest feature-complete option)
- **Native Drag-to-Edit**: Plugin provides exactly what's needed - drag points with mouse or touch
- **Excellent Rails + Stimulus Integration**: Dedicated `stimulus-chartjs` component exists, well-documented importmap setup
- **Active Rails Community Usage**: Recent tutorials (2025), well-supported
- **Touch Support**: Built-in touch event support, set `pointHitRadius: 25+` for better mobile targets
- **Canvas-Based Performance**: HTML5 Canvas provides better performance than SVG for interactive charts
- **Simple API**: Just add `dragData: true` to chart config
- **Smooth Curves**: Use `tension: 0.4` for curved lines connecting points

### Implementation Notes

**Setup:**
```bash
bin/importmap pin chart.js
bin/importmap pin chartjs-plugin-dragdata
```

**Stimulus Controller** (`app/javascript/controllers/energy_map_controller.js`):
```javascript
import { Controller } from "@hotwired/stimulus"
import { Chart, registerables } from "chart.js"
import ChartJSDragDataPlugin from "chartjs-plugin-dragdata"

Chart.register(...registerables, ChartJSDragDataPlugin)

export default class extends Controller {
  static targets = ["canvas"]
  static values = {
    data: Array,
    labels: Array
  }

  connect() {
    this.chart = new Chart(this.canvasTarget, {
      type: 'line',
      data: {
        labels: this.labelsValue, // e.g., ['Morning', 'Noon', 'Afternoon', 'Evening']
        datasets: [{
          label: 'Energy Level',
          data: this.dataValue, // e.g., [null, null, null, null] initially
          borderColor: 'rgb(75, 192, 192)',
          backgroundColor: 'rgba(75, 192, 192, 0.2)',
          tension: 0.4, // Smooth curves
          pointRadius: 8,
          pointHitRadius: 25 // Better touch targets
        }]
      },
      options: {
        responsive: true,
        plugins: {
          dragData: {
            round: 0, // Round to integers (0-10 scale)
            showTooltip: true,
            onDragEnd: (e, datasetIndex, index, value) => {
              this.saveDataPoint(index, value)
            }
          },
          legend: { display: false }
        },
        scales: {
          y: {
            min: 0,
            max: 10,
            title: { display: true, text: 'Energy Level' }
          }
        },
        interaction: {
          mode: 'nearest',
          intersect: false
        }
      }
    })
  }

  saveDataPoint(index, value) {
    this.dispatch('point-updated', {
      detail: { index, value, label: this.labelsValue[index] }
    })
  }

  disconnect() {
    if (this.chart) this.chart.destroy()
  }
}
```

**HTML Usage:**
```erb
<div data-controller="energy-map"
     data-energy-map-data-value="<%= @energy_data.to_json %>"
     data-energy-map-labels-value="<%= @time_periods.to_json %>"
     data-action="energy-map:point-updated->responses#saveEnergyPoint">
  <canvas data-energy-map-target="canvas" class="w-full" height="300"></canvas>
</div>
```

**Configuration Tips:**
- Use `tension: 0.4` for smooth curves between points
- Set `dragDataRound: 0` for integer values, `1` for one decimal place
- Allow null values initially: `data: [null, null, null]` (user fills in progressively)
- Set `pointHitRadius: 25` or higher for better mobile interaction
- Keep `dragX: false` (default) to only drag vertically (energy level), not horizontally (time)

### Alternatives Considered
- **D3.js**: Too complex, steep learning curve, requires building everything from scratch, overkill for MVP
- **ApexCharts**: No native drag-to-edit points (feature requested but unavailable), SVG-based (slower updates)
- **Plotly.js**: Largest bundle (~3MB uncompressed), draggable points require custom implementation, overkill
- **Custom Canvas/SVG**: Minimal bundle but significant dev time, maintenance burden, not worth effort
- **TradingView Lightweight Charts**: Wrong UX for mood tracking, no built-in drag-to-edit

---

## 4. Slider Input with Labels

### Decision
**Native HTML5 Range Input** + **DaisyUI Styling** + **Stimulus Controller**

### Rationale
- **Zero Dependencies**: Native `<input type="range">` supported in all browsers
- **DaisyUI Support**: Built-in `range` class with consistent styling
- **Simple Implementation**: No external library needed for basic slider
- **Accessibility**: Native input supports keyboard navigation (arrow keys)
- **Touch Support**: Native touch interaction on mobile devices

### Implementation Notes

**Stimulus Controller** (`app/javascript/controllers/slider_controller.js`):
```javascript
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["input", "valueDisplay", "label"]
  static values = {
    min: { type: Number, default: 1 },
    max: { type: Number, default: 10 },
    labels: Object // e.g., { 1: "Introvert", 10: "Extrovert" }
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

**HTML Usage:**
```erb
<div data-controller="slider"
     data-slider-min-value="1"
     data-slider-max-value="10"
     data-slider-labels-value='<%= { 1: "Introvert", 5: "Balanced", 10: "Extrovert" }.to_json %>'
     data-action="slider:changed->responses#saveAnswer">

  <label class="form-control">
    <div class="label">
      <span class="label-text"><%= @question.text %></span>
    </div>

    <input type="range"
           min="1"
           max="10"
           value="5"
           class="range range-primary"
           data-slider-target="input"
           data-action="input->slider#updateDisplay change->slider#save">

    <div class="flex justify-between text-xs px-2 mt-2">
      <span>Introvert (1)</span>
      <span data-slider-target="valueDisplay" class="font-bold text-primary">5</span>
      <span>Extrovert (10)</span>
    </div>

    <div class="text-center mt-2">
      <span data-slider-target="label" class="badge badge-lg"></span>
    </div>
  </label>
</div>
```

**DaisyUI Classes:**
- `range` - Base slider styling
- `range-primary` - Primary color theme
- `range-sm`, `range-lg` - Size variants
- Add step markers: `<input class="range" step="25">` with `<div class="flex justify-between"><span>|</span>...`

**Note**: For very complex slider requirements (e.g., dual range, non-linear scales), consider `noUiSlider` library, but native input is sufficient for the specified requirements.

---

## 5. Emoji Reactions

### Decision
**Native Unicode Emojis** + **Stimulus Controller** for selection animation

### Rationale
- **Zero Dependencies**: Unicode emojis render natively in all modern browsers
- **Cross-Platform Consistency**: Modern browsers and mobile devices have good emoji support
- **Lightweight**: No image assets or icon fonts needed
- **Accessible**: Screen readers can announce emoji labels
- **DaisyUI Integration**: Use `btn` and `btn-circle` classes for consistent styling

### Implementation Notes

**Stimulus Controller** (`app/javascript/controllers/emoji_reaction_controller.js`):
```javascript
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["option"]

  select(event) {
    const clickedOption = event.currentTarget
    const emoji = clickedOption.dataset.emoji
    const label = clickedOption.dataset.label

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

    this.dispatch('selected', { detail: { emoji, label } })
  }
}
```

**HTML Usage:**
```erb
<div data-controller="emoji-reaction"
     data-action="emoji-reaction:selected->responses#saveEmoji"
     class="flex flex-wrap gap-4 justify-center">

  <% @question.emoji_options.each do |option| %>
    <button type="button"
            class="btn btn-circle btn-lg btn-ghost"
            data-emoji-reaction-target="option"
            data-emoji="<%= option[:emoji] %>"
            data-label="<%= option[:label] %>"
            data-action="click->emoji-reaction#select">
      <span class="text-4xl"><%= option[:emoji] %></span>
    </button>
  <% end %>
</div>

<div class="text-center mt-4">
  <span class="text-sm opacity-50">Tap an emoji to react</span>
</div>
```

**Example Configuration in Question.settings:**
```ruby
{
  emoji_options: [
    { emoji: "😍", label: "Love it" },
    { emoji: "😊", label: "Like it" },
    { emoji: "😐", label: "Neutral" },
    { emoji: "😕", label: "Dislike" },
    { emoji: "😤", label: "Hate it" }
  ]
}
```

**CSS Animation** (add to application.css):
```css
@keyframes bounce {
  0%, 100% { transform: scale(1.25) translateY(0); }
  50% { transform: scale(1.35) translateY(-10px); }
}
```

**Accessibility Considerations:**
- Provide `aria-label` on buttons with emoji meaning
- Ensure sufficient contrast for selected state
- Support keyboard navigation (tab + enter)

---

## 6. RPG Character Sheet Point Allocation

### Decision
**Custom Stimulus Controller** with **DaisyUI Progress Bars** or **Radial Progress**

### Rationale
- **No External Dependencies**: Simple increment/decrement logic in Stimulus
- **DaisyUI Components**: Use `progress`, `radial-progress`, or custom styled inputs
- **Real-Time Validation**: Budget tracking in client-side controller
- **Visual Feedback**: DaisyUI alert classes for validation errors

### Implementation Notes

**Stimulus Controller** (`app/javascript/controllers/character_sheet_controller.js`):
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
    const statInput = event.currentTarget.closest('[data-stat-id]').querySelector('input')
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
    const statInput = event.currentTarget.closest('[data-stat-id]').querySelector('input')
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

    this.hideError()
  }

  showError(message) {
    if (this.hasErrorTarget) {
      this.errorTarget.textContent = message
      this.errorTarget.classList.remove("hidden")
    }
  }

  hideError() {
    if (this.hasErrorTarget && this.remainingPoints >= 0 && this.remainingPoints <= this.totalPointsValue) {
      this.errorTarget.classList.add("hidden")
    }
  }

  submit(event) {
    if (this.remainingPoints !== 0) {
      event.preventDefault()
      this.showError(`Must allocate all ${this.totalPointsValue} points (${this.remainingPoints} remaining)`)
      return false
    }

    const stats = {}
    this.statTargets.forEach(input => {
      const statName = input.closest('[data-stat-id]').dataset.statId
      stats[statName] = parseInt(input.value) || 0
    })

    this.dispatch('allocated', { detail: { stats } })
  }
}
```

**HTML Usage:**
```erb
<div data-controller="character-sheet"
     data-character-sheet-total-points-value="20"
     data-character-sheet-max-per-stat-value="10"
     data-action="character-sheet:allocated->responses#saveCharacterSheet">

  <div class="alert alert-info mb-4">
    <span>
      Allocate <strong><span data-character-sheet-target="remaining">20</span></strong>
      points remaining
    </span>
  </div>

  <div class="alert alert-error hidden mb-4" data-character-sheet-target="error"></div>

  <div class="space-y-4">
    <% @question.stats.each do |stat| %>
      <div data-stat-id="<%= stat[:name] %>" class="card bg-base-200">
        <div class="card-body">
          <h3 class="card-title"><%= stat[:label] %></h3>
          <p class="text-sm opacity-70"><%= stat[:description] %></p>

          <div class="flex items-center gap-4 mt-2">
            <button type="button"
                    class="btn btn-circle btn-sm"
                    data-action="click->character-sheet#decrement">
              <span class="text-xl">−</span>
            </button>

            <input type="number"
                   value="0"
                   readonly
                   class="input input-bordered w-20 text-center font-bold text-xl"
                   data-character-sheet-target="stat">

            <button type="button"
                    class="btn btn-circle btn-sm"
                    data-action="click->character-sheet#increment">
              <span class="text-xl">+</span>
            </button>

            <progress class="progress progress-primary w-full"
                      value="0"
                      max="10"></progress>
          </div>
        </div>
      </div>
    <% end %>
  </div>

  <button type="button"
          class="btn btn-primary btn-lg w-full mt-6 btn-disabled"
          data-character-sheet-target="submit"
          data-action="click->character-sheet#submit"
          disabled>
    Submit Character Sheet
  </button>
</div>
```

**Example Configuration in Question.settings:**
```ruby
{
  total_points: 20,
  stats: [
    { name: "leadership", label: "Leadership", description: "Ability to guide and inspire" },
    { name: "technical", label: "Technical Skills", description: "Coding and system design" },
    { name: "creative", label: "Creativity", description: "Innovative thinking" },
    { name: "communication", label: "Communication", description: "Written and verbal skills" }
  ]
}
```

**Visual Alternatives:**
- Use `radial-progress` for circular stat display
- Use `range` sliders instead of increment/decrement buttons
- Add visual comparison with existing team averages

---

## Summary: Technology Decisions

| Input Method | Primary Technology | Bundle Impact | Complexity |
|--------------|-------------------|---------------|------------|
| **Card Sorting** | SortableJS | +15.5 KB | Low |
| **Swipe Yes/No** | Native Pointer Events | 0 KB | Low-Medium |
| **Energy Mapping** | Chart.js + dragdata plugin | +11 KB | Medium |
| **Slider** | Native HTML5 range | 0 KB | Low |
| **Emoji Reactions** | Native Unicode emojis | 0 KB | Low |
| **Character Sheet** | Custom Stimulus logic | 0 KB | Medium |
| **TOTAL** | | **~27 KB** | |

All solutions integrate seamlessly with:
- Rails 8.0.3 conventions
- Stimulus.js controllers
- DaisyUI component styling
- Turbo Frames for navigation
- Existing importmap configuration

## Next Steps

Proceed to Phase 1:
1. Generate data-model.md (database schema extensions)
2. Generate API contracts (controller actions, parameters)
3. Generate quickstart.md (developer onboarding)
4. Update agent context with new technologies
