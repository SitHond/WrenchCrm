import { Controller } from "@hotwired/stimulus"
import { Turbo } from "@hotwired/turbo-rails"

// Drag a work order card to another column to change its status.
export default class extends Controller {
  static targets = ["column"]
  static values = { url: String, enabled: Boolean, action: { type: String, default: "status" } }

  start(event) {
    if (!this.enabledValue) return event.preventDefault()
    this.card = event.currentTarget
    event.dataTransfer.effectAllowed = "move"
    const allowed = this.card.dataset.allowed.split(" ")
    this.columnTargets.forEach((column) => {
      column.classList.toggle("drop-allowed", allowed.includes(column.dataset.status))
    })
  }

  end() {
    this.columnTargets.forEach((column) => column.classList.remove("drop-allowed", "drop-over"))
  }

  over(event) {
    if (!this.card || !event.currentTarget.classList.contains("drop-allowed")) return
    event.preventDefault()
    event.currentTarget.classList.add("drop-over")
  }

  leave(event) {
    event.currentTarget.classList.remove("drop-over")
  }

  async drop(event) {
    event.preventDefault()
    const status = event.currentTarget.dataset.status
    const id = this.card?.dataset.id
    this.end()
    if (!id) return

    const token = document.querySelector("meta[name=csrf-token]")?.content
    const body = new URLSearchParams({ status })
    await fetch(`${this.urlValue}/${id}/${this.actionValue}`, {
      method: "PATCH",
      headers: { "X-CSRF-Token": token, "Content-Type": "application/x-www-form-urlencoded" },
      body,
      redirect: "manual"
    })
    Turbo.visit(window.location.href, { action: "replace" })
  }
}
