import { Controller } from "@hotwired/stimulus"
import { Chart, registerables } from "chart.js"
import ChartDataLabels from "chartjs-plugin-datalabels"
import { DragDataPlugin } from "chartjs-plugin-dragdata"

// Register Chart.js components
Chart.register(...registerables, ChartDataLabels, DragDataPlugin)

export default class extends Controller {
  static targets = ["canvas", "hiddenInput"]
  static values = {
    data: Array,
    labels: Array,
    scaleMin: { type: Number, default: 0 },
    scaleMax: { type: Number, default: 10 },
    yAxisLabel: { type: String, default: "Energy Level" }
  }

  connect() {
    this.initializeChart()
  }

  initializeChart() {
    const ctx = this.canvasTarget.getContext("2d")

    // Prepare initial data (null values for empty periods)
    const initialData = this.dataValue.length > 0
      ? this.dataValue
      : this.labelsValue.map(() => null)

    this.chart = new Chart(ctx, {
      type: "line",
      data: {
        labels: this.labelsValue,
        datasets: [{
          label: this.yAxisLabelValue,
          data: initialData,
          borderColor: "rgb(75, 192, 192)",
          backgroundColor: "rgba(75, 192, 192, 0.2)",
          tension: 0.4, // Smooth curves
          pointRadius: 8,
          pointHoverRadius: 10,
          pointHitRadius: 25, // Better touch targets
          fill: true
        }]
      },
      options: {
        responsive: true,
        maintainAspectRatio: false,
        plugins: {
          dragData: {
            round: 0, // Round to integers
            showTooltip: true,
            dragX: false, // Only drag vertically
            onDragStart: (e, datasetIndex, index, value) => {
              // Return false to cancel drag if needed
              return true
            },
            onDrag: (e, datasetIndex, index, value) => {
              // Constrain value to min/max
              if (value < this.scaleMinValue) return false
              if (value > this.scaleMaxValue) return false
              return true
            },
            onDragEnd: (e, datasetIndex, index, value) => {
              this.saveDataPoint(index, value)
            }
          },
          legend: {
            display: false
          },
          tooltip: {
            callbacks: {
              label: (context) => {
                const value = context.parsed.y
                return value !== null ? `${this.yAxisLabelValue}: ${value}` : "Not set"
              }
            }
          }
        },
        scales: {
          y: {
            min: this.scaleMinValue,
            max: this.scaleMaxValue,
            ticks: {
              stepSize: 1
            },
            title: {
              display: true,
              text: this.yAxisLabelValue
            }
          },
          x: {
            ticks: {
              maxRotation: 45,
              minRotation: 0
            }
          }
        },
        interaction: {
          mode: "nearest",
          intersect: false
        },
        // Allow clicking on empty points to set initial value
        onClick: (e, activeElements) => {
          if (activeElements.length === 0) {
            const canvasPosition = Chart.helpers.getRelativePosition(e, this.chart)
            const dataX = this.chart.scales.x.getValueForPixel(canvasPosition.x)
            const dataY = this.chart.scales.y.getValueForPixel(canvasPosition.y)

            if (dataX !== undefined && dataY !== undefined) {
              const index = Math.round(dataX)
              const value = Math.round(Math.max(this.scaleMinValue, Math.min(this.scaleMaxValue, dataY)))

              if (index >= 0 && index < this.labelsValue.length) {
                this.chart.data.datasets[0].data[index] = value
                this.chart.update()
                this.saveDataPoint(index, value)
              }
            }
          }
        }
      }
    })
  }

  saveDataPoint(index, value) {
    // Update the chart data
    this.chart.data.datasets[0].data[index] = value

    // Build the complete data_points structure
    const dataPoints = this.labelsValue.map((label, i) => ({
      period: label,
      value: this.chart.data.datasets[0].data[i]
    }))

    // Update hidden input with JSON data
    const jsonbData = { data_points: dataPoints }
    if (this.hasHiddenInputTarget) {
      this.hiddenInputTarget.value = JSON.stringify(jsonbData)
    }

    // Dispatch custom event for auto-save or other handlers
    this.dispatch("point-updated", {
      detail: {
        index,
        value,
        label: this.labelsValue[index],
        allData: dataPoints
      }
    })
  }

  disconnect() {
    if (this.chart) {
      this.chart.destroy()
    }
  }
}
