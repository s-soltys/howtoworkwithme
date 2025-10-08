import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = {
    threshold: { type: Number, default: 0.3 } // 30% screen width
  }
  static targets = ["card", "yesIndicator", "noIndicator"]

  connect() {
    this.startX = 0
    this.currentX = 0
    this.isDragging = false
  }

  start(event) {
    this.isDragging = true
    this.startX = event.clientX || event.touches[0].clientX
    this.element.style.transition = 'none'
    event.preventDefault() // Prevent text selection
  }

  move(event) {
    if (!this.isDragging) return

    const clientX = event.clientX || (event.touches && event.touches[0].clientX)
    this.currentX = clientX - this.startX
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
    // Handle when user switches apps or gesture is interrupted
    if (this.isDragging) {
      this.isDragging = false
      this.resetPosition()
    }
  }

  handleSwipe(direction) {
    const offset = direction === 'right' ? window.innerWidth : -window.innerWidth
    this.cardTarget.style.transform = `translateX(${offset}px) rotate(${direction === 'right' ? 30 : -30}deg)`

    // Wait for animation to complete before dispatching
    setTimeout(() => {
      this.dispatch('swiped', {
        detail: { answer: direction === 'right' }
      })
    }, 300)
  }

  resetPosition() {
    this.cardTarget.style.transform = 'translateX(0) rotate(0deg)'
    this.currentX = 0
    if (this.hasYesIndicatorTarget) this.yesIndicatorTarget.style.opacity = '0'
    if (this.hasNoIndicatorTarget) this.noIndicatorTarget.style.opacity = '0'
  }

  updateVisualFeedback() {
    const thresholdPx = window.innerWidth * this.thresholdValue
    const progress = Math.min(Math.abs(this.currentX) / thresholdPx, 1)

    if (this.currentX > 0 && this.hasYesIndicatorTarget) {
      // Swiping right (yes)
      this.yesIndicatorTarget.style.opacity = progress.toString()
      if (this.hasNoIndicatorTarget) this.noIndicatorTarget.style.opacity = '0'
    } else if (this.currentX < 0 && this.hasNoIndicatorTarget) {
      // Swiping left (no)
      this.noIndicatorTarget.style.opacity = progress.toString()
      if (this.hasYesIndicatorTarget) this.yesIndicatorTarget.style.opacity = '0'
    }
  }

  // Keyboard support for accessibility
  keyDown(event) {
    if (event.key === 'ArrowRight') {
      event.preventDefault()
      this.handleSwipe('right')
    } else if (event.key === 'ArrowLeft') {
      event.preventDefault()
      this.handleSwipe('left')
    }
  }
}
