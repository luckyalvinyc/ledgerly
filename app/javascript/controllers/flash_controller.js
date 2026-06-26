import { Controller } from "@hotwired/stimulus"

// Auto closes a flash message after a timeout, and lets the user dismiss it now.
export default class extends Controller {
  static values = { timeout: { type: Number, default: 5000 } }

  connect() {
    if (this.timeoutValue > 0) {
      this.timer = setTimeout(() => this.dismiss(), this.timeoutValue)
    }
  }

  disconnect() {
    if (this.timer) clearTimeout(this.timer)
  }

  dismiss() {
    this.element.remove()
  }
}
