import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["option", "hiddenInput"]

  select(event) {
    const clickedOption = event.currentTarget
    const emoji = clickedOption.dataset.emoji
    const label = clickedOption.dataset.label
    const value = clickedOption.dataset.value ? parseInt(clickedOption.dataset.value) : null

    // Clear previous selection
    this.optionTargets.forEach(opt => {
      opt.classList.remove("btn-primary", "scale-125", "ring-4", "ring-primary", "ring-offset-2")
      opt.classList.add("btn-ghost")
    })

    // Highlight selected
    clickedOption.classList.remove("btn-ghost")
    clickedOption.classList.add("btn-primary", "scale-125", "ring-4", "ring-primary", "ring-offset-2")

    // Animate with bounce
    clickedOption.style.animation = "bounce 0.5s ease"
    setTimeout(() => {
      clickedOption.style.animation = ""
    }, 500)

    // Update hidden input with JSON data
    const jsonbData = {
      emoji: emoji,
      label: label,
      value: value
    }

    if (this.hasHiddenInputTarget) {
      this.hiddenInputTarget.value = JSON.stringify(jsonbData)
    }

    // Dispatch custom event for auto-save or other handlers
    this.dispatch("selected", {
      detail: {
        emoji,
        label,
        value
      }
    })
  }

  connect() {
    // Restore previous selection if any
    if (this.hasHiddenInputTarget && this.hiddenInputTarget.value) {
      try {
        const data = JSON.parse(this.hiddenInputTarget.value)
        const selectedEmoji = data.emoji

        // Find and highlight the matching option
        this.optionTargets.forEach(opt => {
          if (opt.dataset.emoji === selectedEmoji) {
            opt.classList.remove("btn-ghost")
            opt.classList.add("btn-primary", "scale-125", "ring-4", "ring-primary", "ring-offset-2")
          }
        })
      } catch (e) {
        // Invalid JSON, ignore
      }
    }
  }
}
