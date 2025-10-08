import { Controller } from "@hotwired/stimulus"
import Sortable from "sortablejs"

// Connects to data-controller="card-sort"
export default class extends Controller {
  static values = {
    animation: { type: Number, default: 150 }
  }
  static targets = ["card", "hiddenInput"]

  connect() {
    this.sortable = Sortable.create(this.element, {
      animation: this.animationValue,
      delayOnTouchOnly: true,
      delay: 100,
      touchStartThreshold: 5,
      ghostClass: "opacity-50",
      chosenClass: "ring-2 ring-primary",
      dragClass: "rotate-2 scale-105",
      onEnd: this.onEnd.bind(this)
    })

    // Initialize ranking
    this.updateRanking()
  }

  onEnd(event) {
    // Update ranking after drag ends
    this.updateRanking()

    // Dispatch custom event with new order
    const ranking = this.getRanking()
    this.dispatch("sorted", { detail: { ranking } })
  }

  getRanking() {
    const cards = Array.from(this.cardTargets)
    const ranked = cards.map((card, index) => ({
      id: card.dataset.cardId,
      rank: index + 1
    }))

    return {
      ranked: ranked,
      unranked: []
    }
  }

  updateRanking() {
    // Update visual rank numbers
    this.cardTargets.forEach((card, index) => {
      const rankBadge = card.querySelector('[data-rank-badge]')
      if (rankBadge) {
        rankBadge.textContent = index + 1
      }
    })

    // Update hidden input with ranking data
    const ranking = this.getRanking()
    if (this.hasHiddenInputTarget) {
      this.hiddenInputTarget.value = JSON.stringify(ranking)
    }
  }

  disconnect() {
    if (this.sortable) {
      this.sortable.destroy()
    }
  }
}
