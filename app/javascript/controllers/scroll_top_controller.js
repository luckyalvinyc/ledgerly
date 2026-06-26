import { Controller } from "@hotwired/stimulus"

// Shows the button once the page is scrolled past a threshold, and scrolls back to the top.
export default class extends Controller {
  static values = { threshold: { type: Number, default: 400 } }

  connect() {
    this.onScroll = this.onScroll.bind(this)
    window.addEventListener("scroll", this.onScroll, { passive: true })
    this.onScroll()
  }

  disconnect() {
    window.removeEventListener("scroll", this.onScroll)
  }

  onScroll() {
    this.element.classList.toggle("is-visible", window.scrollY > this.thresholdValue)
  }

  top() {
    window.scrollTo({ top: 0, behavior: "smooth" })
  }
}
