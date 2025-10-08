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
    } else {
      this.labelTarget.textContent = ""
    }
  }

  save() {
    const value = parseInt(this.inputTarget.value)
    this.dispatch('changed', { detail: { value } })
  }
}
