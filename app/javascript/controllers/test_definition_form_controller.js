import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [ "allModels", "modelField" ]

  connect() {
    this.toggleModel()
  }

  toggleModel() {
    const hide = this.allModelsTarget.checked
    this.modelFieldTarget.classList.toggle("d-none", hide)
  }
}
