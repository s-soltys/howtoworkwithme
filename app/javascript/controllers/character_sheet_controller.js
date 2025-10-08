import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["stat", "remaining", "error", "submit", "hiddenInput", "progress"]
  static values = {
    totalPoints: { type: Number, default: 20 },
    minPerStat: { type: Number, default: 0 },
    maxPerStat: { type: Number, default: 10 }
  }

  connect() {
    this.updateBudget()
  }

  increment(event) {
    const statCard = event.currentTarget.closest("[data-stat-id]")
    const statInput = statCard.querySelector("input[type='number']")
    const statId = statCard.dataset.statId
    const statMax = parseInt(statCard.dataset.statMax) || this.maxPerStatValue
    const currentValue = parseInt(statInput.value) || 0

    if (currentValue >= statMax) {
      this.showError(`Maximum ${statMax} points for this stat`)
      return
    }

    if (this.remainingPoints <= 0) {
      this.showError("No points remaining")
      return
    }

    statInput.value = currentValue + 1
    this.updateStatProgress(statCard, currentValue + 1, statMax)
    this.updateBudget()
  }

  decrement(event) {
    const statCard = event.currentTarget.closest("[data-stat-id]")
    const statInput = statCard.querySelector("input[type='number']")
    const statId = statCard.dataset.statId
    const statMin = parseInt(statCard.dataset.statMin) || this.minPerStatValue
    const currentValue = parseInt(statInput.value) || 0

    if (currentValue <= statMin) {
      this.showError(`Minimum ${statMin} points for this stat`)
      return
    }

    statInput.value = currentValue - 1
    this.updateStatProgress(statCard, currentValue - 1, parseInt(statCard.dataset.statMax) || this.maxPerStatValue)
    this.updateBudget()
  }

  updateStatProgress(statCard, value, max) {
    const progressBar = statCard.querySelector("progress")
    const radialProgress = statCard.querySelector(".radial-progress")

    if (progressBar) {
      progressBar.value = value
      progressBar.max = max
    }

    if (radialProgress) {
      const percentage = (value / max) * 100
      radialProgress.style.setProperty("--value", percentage)
      radialProgress.textContent = value
    }
  }

  updateBudget() {
    const allocatedPoints = this.statTargets.reduce((sum, input) => {
      return sum + (parseInt(input.value) || 0)
    }, 0)

    this.remainingPoints = this.totalPointsValue - allocatedPoints

    if (this.hasRemainingTarget) {
      this.remainingTarget.textContent = this.remainingPoints
    }

    // Visual feedback
    if (this.remainingPoints === 0) {
      // Perfect allocation - enable submit
      if (this.hasRemainingTarget) {
        this.remainingTarget.classList.add("text-success", "font-bold")
        this.remainingTarget.classList.remove("text-error", "text-warning")
      }
      if (this.hasSubmitTarget) {
        this.submitTarget.disabled = false
        this.submitTarget.classList.remove("btn-disabled")
      }
      this.hideError()
    } else if (this.remainingPoints < 0) {
      // Over budget
      if (this.hasRemainingTarget) {
        this.remainingTarget.classList.add("text-error", "font-bold")
        this.remainingTarget.classList.remove("text-success", "text-warning")
      }
      if (this.hasSubmitTarget) {
        this.submitTarget.disabled = true
        this.submitTarget.classList.add("btn-disabled")
      }
      this.showError("Over budget!")
    } else {
      // Under budget
      if (this.hasRemainingTarget) {
        this.remainingTarget.classList.add("text-warning")
        this.remainingTarget.classList.remove("text-success", "text-error")
      }
      if (this.hasSubmitTarget) {
        this.submitTarget.disabled = true
        this.submitTarget.classList.add("btn-disabled")
      }
      this.hideError()
    }

    // Update hidden input
    this.updateHiddenInput()
  }

  updateHiddenInput() {
    const allocations = {}

    document.querySelectorAll("[data-stat-id]").forEach(statCard => {
      const statId = statCard.dataset.statId
      const statInput = statCard.querySelector("input[type='number']")
      const value = parseInt(statInput.value) || 0
      allocations[statId] = value
    })

    const total = Object.values(allocations).reduce((sum, val) => sum + val, 0)

    const jsonbData = {
      allocations: allocations,
      total_allocated: total
    }

    if (this.hasHiddenInputTarget) {
      this.hiddenInputTarget.value = JSON.stringify(jsonbData)
    }

    // Dispatch event for auto-save
    if (total === this.totalPointsValue) {
      this.dispatch("allocated", { detail: jsonbData })
    }
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

  submit(event) {
    if (this.remainingPoints !== 0) {
      event.preventDefault()
      this.showError(`Must allocate all ${this.totalPointsValue} points (${this.remainingPoints} remaining)`)
      return false
    }

    this.updateHiddenInput()
  }
}
