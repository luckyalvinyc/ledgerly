// Configure your import map in config/importmap.rb. Read more: https://github.com/rails/importmap-rails
import "@hotwired/turbo-rails"
import "controllers"

// When a frame request's response has no matching frame (e.g. the session expired and the
// server redirected to sign in), do a full-page visit instead of showing "content missing".
document.addEventListener("turbo:frame-missing", (event) => {
  event.preventDefault()
  event.detail.visit(event.detail.response)
})
