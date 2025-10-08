import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="autosave"
export default class extends Controller {
  static targets = ["form"]
  static values = { delay: { type: Number, default: 2000 } }

  connect() {
    this.timeout = null
  }

  disconnect() {
    if (this.timeout) {
      clearTimeout(this.timeout)
    }
  }

  // Debounced save - triggered by input events
  save(event) {
    // Clear existing timeout
    if (this.timeout) {
      clearTimeout(this.timeout)
    }

    // Show saving status immediately
    this.showStatus("saving")

    // Set new timeout to save after delay
    this.timeout = setTimeout(() => {
      this.submitForm()
    }, this.delayValue)
  }

  // Immediate save - triggered by blur events
  saveImmediate(event) {
    // Clear any pending debounced save
    if (this.timeout) {
      clearTimeout(this.timeout)
    }

    this.showStatus("saving")
    this.submitForm()
  }

  submitForm() {
    const form = this.formTarget

    // Use Turbo to submit the form
    form.requestSubmit()
  }

  showStatus(status) {
    const statusElement = document.getElementById("autosave_status")
    if (!statusElement) return

    if (status === "saving") {
      statusElement.innerHTML = `
        <div class="flex items-center gap-2 text-base-content/70">
          <span class="loading loading-spinner loading-sm"></span>
          <span>Saving...</span>
        </div>
      `
    }
  }
}
