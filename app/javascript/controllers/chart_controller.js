import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["timeChart", "distanceChart"]

  openTimeChart() {
    this.timeChartTarget.classList.remove("hidden")
    this.distanceChartTarget.classList.add("hidden")
  }

  openDistanceChart() {
    this.timeChartTarget.classList.add("hidden")
    this.distanceChartTarget.classList.remove("hidden")
  }
}
