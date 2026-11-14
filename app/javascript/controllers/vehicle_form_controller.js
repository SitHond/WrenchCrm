import { Controller } from "@hotwired/stimulus"

// Suggests models for the chosen make and fills empty fields from the VIN.
export default class extends Controller {
  static targets = ["make", "model", "modelList", "year", "vin", "hint"]
  static values = { models: Object, decodeUrl: String, vehicleId: String, labels: Object }

  connect() {
    this.updateModels()
  }

  updateModels() {
    const make = this.findMake(this.makeTarget.value)
    const models = make ? this.modelsValue[make] : Object.values(this.modelsValue).flat()
    this.modelListTarget.replaceChildren(...[...new Set(models)].map((model) => new Option(model)))
  }

  async decodeVin() {
    const vin = this.vinTarget.value.trim().toUpperCase()
    if (vin.length !== 17) {
      this.showHint("")
      return
    }

    const url = new URL(this.decodeUrlValue, window.location.origin)
    url.searchParams.set("vin", vin)
    if (this.vehicleIdValue) url.searchParams.set("vehicle_id", this.vehicleIdValue)

    const response = await fetch(url, { headers: { Accept: "application/json" } })
    if (!response.ok) return
    this.applyDecoded(await response.json())
  }

  applyDecoded(data) {
    if (!data.valid) {
      this.showHint(this.labelsValue.invalid, "danger")
      return
    }

    if (data.makes.length === 1 && !this.makeTarget.value) {
      this.makeTarget.value = data.makes[0]
      this.updateModels()
    }
    if (data.year && !this.yearTarget.value) this.yearTarget.value = data.year

    const parts = [data.makes.join(" / "), data.country, data.year && `${data.year} ${this.labelsValue.year_note}`].filter(Boolean)
    const hint = document.createElement("span")
    hint.textContent = parts.length ? `${this.labelsValue.decoded}: ${parts.join(", ")}` : this.labelsValue.unknown

    if (data.existing) {
      const warning = document.createElement("strong")
      warning.className = "danger"
      warning.append(` ${this.labelsValue.existing} `)
      const link = document.createElement("a")
      link.href = data.existing.url
      link.textContent = `${data.existing.label} (${data.existing.client})`
      warning.append(link)
      hint.append(warning)
    }
    this.hintTarget.className = "hint"
    this.hintTarget.replaceChildren(hint)
    if (data.makes.length > 1 && !this.makeTarget.value) this.makeTarget.focus()
  }

  showHint(text, className = "") {
    this.hintTarget.className = `hint ${className}`
    this.hintTarget.textContent = text
  }

  findMake(value) {
    const name = value.trim().toLowerCase()
    return Object.keys(this.modelsValue).find((make) => make.toLowerCase() === name)
  }
}
