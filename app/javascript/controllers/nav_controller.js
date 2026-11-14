import { Controller } from "@hotwired/stimulus"

// Opens and closes the sidebar as a drawer on small screens.
export default class extends Controller {
  static targets = ["toggle"]

  connect() {
    this.close = this.close.bind(this)
    document.addEventListener("turbo:before-visit", this.close)
  }

  disconnect() {
    document.removeEventListener("turbo:before-visit", this.close)
  }

  toggle() {
    this.element.classList.contains("nav-open") ? this.close() : this.open()
  }

  open() {
    this.element.classList.add("nav-open")
    this.toggleTargets.forEach((button) => button.setAttribute("aria-expanded", "true"))
  }

  close() {
    this.element.classList.remove("nav-open")
    this.toggleTargets.forEach((button) => button.setAttribute("aria-expanded", "false"))
  }
}
