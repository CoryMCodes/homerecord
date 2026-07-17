import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [ "form", "input", "panel" ]

  connect() {
    this.timeout = null
  }

  disconnect() {
    clearTimeout(this.timeout)
  }

  queueSearch() {
    clearTimeout(this.timeout)

    if (this.query.length === 0) {
      this.close()
      return
    }

    this.open()
    this.timeout = setTimeout(() => {
      this.formTarget.requestSubmit()
    }, 180)
  }

  openIfPresent() {
    if (this.query.length > 0) {
      this.open()
    }
  }

  close() {
    this.panelTarget.classList.add("hidden")
  }

  closeOnOutsideClick(event) {
    if (!this.element.contains(event.target)) {
      this.close()
    }
  }

  open() {
    this.panelTarget.classList.remove("hidden")
  }

  get query() {
    return this.inputTarget.value.trim()
  }
}
