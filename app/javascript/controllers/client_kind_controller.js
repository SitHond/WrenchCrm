import { Controller } from "@hotwired/stimulus"

// Shows name fields for individuals and company fields for companies.
export default class extends Controller {
  static targets = ["individual", "company"]

  connect() {
    this.toggle()
  }

  toggle() {
    const kind = this.element.querySelector("input[name$='[kind]']:checked")?.value
    this.individualTarget.hidden = kind === "company"
    this.companyTarget.hidden = kind !== "company"
  }
}
