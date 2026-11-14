import { Controller } from "@hotwired/stimulus"

// Points the "add to group" form at the group chosen in the select.
export default class extends Controller {
  change(event) {
    this.element.action = this.element.action.replace(/\/groups\/\d+\//, `/groups/${event.target.value}/`)
  }
}
