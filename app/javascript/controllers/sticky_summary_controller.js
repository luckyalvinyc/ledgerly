import { Controller } from "@hotwired/stimulus"

// Reveals a compact summary bar once the full P&L receipt scrolls out of view.
export default class extends Controller {
  static targets = ["full", "compact"]

  connect() {
    this.observer = new IntersectionObserver(
      ([entry]) => { this.compactTarget.hidden = entry.isIntersecting },
      { threshold: 0 }
    )
    this.observer.observe(this.fullTarget)
  }

  disconnect() {
    if (this.observer) this.observer.disconnect()
  }
}
