import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="loading"
export default class extends Controller {
  static targets = ["submit", "spinner"]

  connect() {
    // Listen for turbo:submit-start and turbo:submit-end events
    this.element.addEventListener("turbo:submit-start", this.showLoading.bind(this))
    this.element.addEventListener("turbo:submit-end", this.hideLoading.bind(this))
  }

  disconnect() {
    this.element.removeEventListener("turbo:submit-start", this.showLoading.bind(this))
    this.element.removeEventListener("turbo:submit-end", this.hideLoading.bind(this))
  }

  showLoading() {
    if (this.hasSubmitTarget) {
      this.submitTarget.disabled = true
      this.submitTarget.classList.add("loading")
    }
  }

  hideLoading() {
    if (this.hasSubmitTarget) {
      this.submitTarget.disabled = false
      this.submitTarget.classList.remove("loading")
    }
  }
}
