import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="question-type"
export default class extends Controller {
  static targets = ["typeSelect", "optionsContainer", "optionFields"]
  static values = { minOptions: { type: Number, default: 2 } }

  connect() {
    this.updateOptionsVisibility()
  }

  typeChanged() {
    this.updateOptionsVisibility()
  }

  updateOptionsVisibility() {
    const questionType = this.typeSelectTarget.value
    const needsOptions = questionType === "single_choice" || questionType === "multiple_choice"

    if (this.hasOptionsContainerTarget) {
      if (needsOptions) {
        this.optionsContainerTarget.classList.remove("hidden")
        this.ensureMinimumOptions()
      } else {
        this.optionsContainerTarget.classList.add("hidden")
      }
    }
  }

  addOption(event) {
    event.preventDefault()
    const container = this.optionFieldsTarget
    const timestamp = new Date().getTime()
    const newOptionHtml = this.createOptionField(timestamp)
    container.insertAdjacentHTML("beforeend", newOptionHtml)
  }

  removeOption(event) {
    event.preventDefault()
    const optionField = event.target.closest(".option-field")
    if (this.countVisibleOptions() > this.minOptionsValue) {
      optionField.remove()
    } else {
      alert(`Choice questions require at least ${this.minOptionsValue} options`)
    }
  }

  ensureMinimumOptions() {
    const currentCount = this.countVisibleOptions()
    if (currentCount < this.minOptionsValue) {
      for (let i = currentCount; i < this.minOptionsValue; i++) {
        const timestamp = new Date().getTime() + i
        const newOptionHtml = this.createOptionField(timestamp)
        this.optionFieldsTarget.insertAdjacentHTML("beforeend", newOptionHtml)
      }
    }
  }

  countVisibleOptions() {
    return this.optionFieldsTarget.querySelectorAll(".option-field:not(.hidden)").length
  }

  createOptionField(timestamp) {
    return `
      <div class="option-field form-control mb-2">
        <div class="flex gap-2 items-center">
          <input
            type="text"
            name="question[question_options_attributes][${timestamp}][text]"
            placeholder="Option text"
            class="input input-bordered flex-1"
            required
          />
          <input
            type="hidden"
            name="question[question_options_attributes][${timestamp}][position]"
            value="${timestamp}"
          />
          <button
            type="button"
            data-action="question-type#removeOption"
            class="btn btn-error btn-sm"
          >
            Remove
          </button>
        </div>
      </div>
    `
  }
}
