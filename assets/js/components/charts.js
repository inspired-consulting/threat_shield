import { once } from "../utils/common";

import Chart from "chart.js/auto";

/**
 * Helper to integrate Chart.js.
 *
 * <div class="chart-js" data-chart>
 * </div>
 *
 *
 */

export default function (container, selector) {
  container.querySelectorAll(selector).forEach(function (match) {
    once(match, "chart-js", init);
  });
}

function init(container) {
  let canvas = container.querySelector("canvas");
  let chartType = container.dataset.chartType || "doughnut";
  let label = container.dataset.dataPointLabel || "count";

  let datasets = JSON.parse(container.dataset.datasets) || [];
  let datasetLabels = JSON.parse(container.dataset.datasetLabels) || [];
  let colors = JSON.parse(container.dataset.colors) || [];

  new Chart(canvas, {
    type: chartType,
    data: {
      labels: datasetLabels,
      datasets: [
        {
          label: label,
          data: datasets,
          borderWidth: 1,
          backgroundColor: colors,
        },
      ],
    },
    options: {
      scales: {
        y: {
          beginAtZero: true,
        },
      },
      plugins: {
        legend: {
          position: "bottom",
        },
      },
    },
  });
}
