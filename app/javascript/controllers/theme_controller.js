import { Controller } from "@hotwired/stimulus"

// Toggles light/dark, overriding the OS default, and remembers the choice in a
// cookie so the server can render the right theme with no flash on reload.
export default class extends Controller {
  toggle() {
    const root = document.documentElement
    const current = root.getAttribute("data-theme")
    const resolved = current || (window.matchMedia("(prefers-color-scheme: dark)").matches ? "dark" : "light")
    const next = resolved === "dark" ? "light" : "dark"

    root.setAttribute("data-theme", next)
    document.cookie = `theme=${next};path=/;max-age=31536000;samesite=lax`
  }
}
