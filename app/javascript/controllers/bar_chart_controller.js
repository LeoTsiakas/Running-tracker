import { Controller } from "@hotwired/stimulus"
import { Chart, registerables } from "chart.js"

// Register every chart type, scale and plugin (what "chart.js/auto" does with a bundler)
Chart.register(...registerables)

export default class extends Controller {
  static targets = ["timeCanvas", "distanceCanvas"]

  static values = {
    metrics: Array
  }

  connect() {
    this.charts = [
      this.buildChart(this.timeCanvasTarget, "Time by Date", "time", "#60a5fa"),
      this.buildChart(this.distanceCanvasTarget, "Distance by Date", "distance", "#fb923c")
    ]
  }

  disconnect() {
    this.charts?.forEach(chart => chart.destroy())
  }

  buildChart(canvas, label, attribute, color) {
    return new Chart(canvas, {
      type: "line",
      data: {
        labels: this.labels(),
        datasets: [
          {
            label: label,
            data: this.metricsValue.map(metric => metric[attribute]),
            backgroundColor: color
          }
        ]
      },
      options: {
        responsive: true,
        maintainAspectRatio: false
      }
    })
  }

  labels() {
    return this.metricsValue.map(metric =>
      new Date(metric.date).toLocaleDateString(undefined, { day: "numeric", month: "short" })
    )
  }
}
