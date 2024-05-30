defmodule ThreatShieldWeb.InfoVis do
  @moduledoc """
  Provides icons as components
  """
  use Phoenix.Component

  import ThreatShieldWeb.Gettext

  @doc """
  Components for Information Visualisation.
  """
  attr :risk_model, :list, required: true
  attr :size, :integer, default: 500
  attr :show_labels, :boolean, default: true

  def risk_quadrants(assigns) do
    ~H"""
    <svg width={@size} height={@size} style="border: 1px solid black;">
      <style>
        svg a text {
          font-size: 9px;
          fill: rgba(150, 150, 150, 50);
        }
        svg circle {
          transition: all 0.2s;
          stroke: rgba(100, 100, 100, 100);
          stroke-width: 1;
        }
        svg a:hover text {
          fill: rgba(100, 90, 90, 255);
          background: white;
        }
        svg a:hover circle {
          stroke: rgba(100, 100, 100, 200);
          stroke-width: 2;
        }
      </style>
      <!-- Quadrants -->
      <line x1={0} y1={@size / 2} x2={@size} y2={@size / 2} stroke="gray" stroke-width="1" />
      <line x1={@size / 2} y1={0} x2={@size / 2} y2={@size} stroke="gray" stroke-width="1" />
      <!-- Axis Labels -->
      <text x={@size / 8} y={@size - 10} font-size="12">
        <%= dgettext("risks", "Severity") %> &rarr;
      </text>
      <text
        x={@size / 25}
        y={@size * 0.92}
        font-size="12"
        transform={"rotate(-90, #{@size / 25}, #{@size * 0.92})"}
      >
        <%= dgettext("risks", "Frequency") %> &rarr;
      </text>

      <a :for={risk <- @risk_model} xlink:href={risk.link}>
        <circle
          cx={risk.severity * @size}
          cy={@size - risk.frequency * @size}
          r={risk.cost * @size / 10}
          fill={risk.color}
        >
          <title><%= "#{risk.name}: EUR #{risk.cost_label}" %></title>
        </circle>
        <text
          :if={@show_labels && risk.severity < 0.7}
          x={risk.severity * @size + risk.cost * @size / 10 + 5}
          y={@size - risk.frequency * @size + 3}
          text-anchor="start"
        >
          <%= risk.name %>
        </text>
        <text
          :if={@show_labels && risk.severity >= 0.7}
          x={risk.severity * @size - risk.cost * @size / 10 - 5}
          y={@size - risk.frequency * @size + 3}
          text-anchor="end"
        >
          <%= risk.name %>
        </text>
      </a>
    </svg>
    """
  end
end
