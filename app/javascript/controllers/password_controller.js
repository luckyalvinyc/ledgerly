import { Controller } from "@hotwired/stimulus"

// Reveals or hides a password field so people can check what they typed.
export default class extends Controller {
  static targets = ["input", "toggle"]

  toggle() {
    const reveal = this.inputTarget.type === "password"
    this.inputTarget.type = reveal ? "text" : "password"
    this.element.classList.toggle("is-revealed", reveal)
    this.toggleTarget.setAttribute("aria-label", reveal ? "Hide password" : "Show password")
    this.toggleTarget.setAttribute("aria-pressed", reveal)
  }
}
