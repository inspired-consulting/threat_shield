defmodule ThreatShieldWeb.RiskLive.RiskBoard do
  use ThreatShieldWeb, :live_view

  alias ThreatShield.{Risks, Threats, Mitigations, Members}
  alias ThreatShield.Risks.Risk

  import ThreatShieldWeb.Helpers
  import ThreatShieldWeb.Gettext

  @moduledoc """
  See an overview of all risks in the organisation.
  """

  @impl true
  def render(assigns) do
    ~H"""
    <section class="w-full bg-white py-6 shadow-primary-200 shadow-sm">
      <div class="ts-container">
        <.header>
          <.h1><%= dgettext("risks", "Risk board") %></.h1>
          <.h3>
            <span class="text-gray-700 inline-block">
              <Icons.organisation_icon class="w-5 h-5" />
            </span>
            <%= @organisation.name %>
          </.h3>
        </.header>
        <div class="grid grid-cols-4 gap-2 mt-2 px-2 py-2 bg-primary-100">
          <.input_attribute attributes={@organisation.attributes}></.input_attribute>
        </div>
      </div>
    </section>
    <section class="ts-container mt-2 grid grid-cols-2 gap-6">
      <div class="mt-4 px-8 py-6 bg-white rounded-lg shadow">
        <h2 class="font-semibold"><%= dgettext("risks", "Risk summary") %></h2>
        <.table id="risk_summary" rows={@summary}>
          <:col :let={item}><%= item.label %></:col>
          <:col :let={item}><%= item.value %></:col>
        </.table>
      </div>

      <div class="mt-4 px-8 py-6 bg-white rounded-lg shadow" id="risks_by_status" phx-update="ignore">
        <h2 class="font-semibold"><%= dgettext("risks", "Risk by status") %></h2>
        <div
          class="chart p-4 w-[30rem]"
          data-chart-type="doughnut"
          data-data-point-label={dgettext("risk-board", "Number of risks")}
          data-datasets={@risks_by_status.data |> Jason.encode!()}
          data-dataset-labels={@risks_by_status.labels |> Jason.encode!()}
          data-colors={@risks_by_status.colors |> Jason.encode!()}
        >
          <canvas></canvas>
        </div>
      </div>

      <div class="mt-4 px-8 py-6 bg-white rounded-lg shadow">
        <h2 class="font-semibold"><%= dgettext("risks", "Top 10 risks by severity") %></h2>
        <.table
          id="top_10_severity"
          rows={@top_10_severity}
          row_click={fn risk -> JS.navigate(link_to(risk, @organisation)) end}
        >
          <:col :let={risk} label={dgettext("common", "Risk")}><%= risk.name %></:col>
          <:col :let={risk} label={dgettext("common", "Severity")}>
            <.criticality_badge value={risk.severity} title={dgettext("risks", "Severity")} />
          </:col>
        </.table>
      </div>

      <div class="mt-4 px-8 py-6 bg-white rounded-lg shadow">
        <h2 class="font-semibold"><%= dgettext("risks", "Top 10 risks by costs") %></h2>
        <.table
          id="top_10_costs"
          rows={@top_10_costs}
          row_click={fn risk -> JS.navigate(link_to(risk, @organisation)) end}
        >
          <:col :let={risk} label={dgettext("common", "Risk")}><%= risk.name %></:col>
          <:col :let={risk} label={dgettext("common", "Costs")}>
            <%= format_monetary_amount(Risk.estimated_risk_cost(risk)) %>
          </:col>
        </.table>
      </div>
    </section>
    """
  end

  @impl true
  def mount(%{"org_id" => org_id}, _session, socket) do
    user = socket.assigns.current_user
    organisation = Members.get_organisation!(user, org_id)

    risks = Risks.get_all_risks(user, organisation.id)

    socket
    |> assign(:organisation, organisation)
    |> assign(:top_10_severity, top_10_severity(risks))
    |> assign(:top_10_costs, top_10_risk_costs(risks))
    |> assign(:risks_by_status, risks_by_status(risks))
    |> assign(:summary, summary(organisation, risks))
    |> ok()
  end

  defp top_10_severity(risks) do
    risks
    |> Enum.sort_by(& &1.severity)
    |> Enum.reverse()
    |> Enum.take(10)
  end

  defp top_10_risk_costs(risks) do
    risks
    |> Enum.filter(&(Risk.estimated_risk_cost(&1) != nil))
    |> Enum.sort_by(fn risk -> Risk.estimated_risk_cost(risk) end)
    |> Enum.reverse()
    |> Enum.take(10)
  end

  defp risks_by_status(risks) do
    groups = %{identified: 0, assessed: 0, mitigated: 0, accepted: 0}

    groups =
      risks
      |> Enum.reduce(groups, fn risk, acc ->
        Map.update(acc, risk.status, 1, &(&1 + 1))
      end)

    %{
      labels: [
        dgettext("risks", "State:identified"),
        dgettext("risks", "State:assessed"),
        dgettext("risks", "State:mitigated"),
        dgettext("risks", "State:accepted")
      ],
      data: [groups[:identified], groups[:assessed], groups[:mitigated], groups[:accepted]],
      colors: ["#E23D47", "#E89E2E", "#59CE56", "#3664B7"]
    }
  end

  defp summary(organisation, risks) do
    total_cost =
      risks
      |> Enum.filter(&(Risk.estimated_risk_cost(&1) != nil))
      |> Enum.reduce(0, fn risk, acc ->
        acc + Risk.estimated_risk_cost(risk)
      end)

    [
      %{label: dgettext("common", "Number of risks"), value: Enum.count(risks)},
      %{
        label: dgettext("common", "Number of threats"),
        value: Threats.count_all_threats(organisation)
      },
      %{
        label: dgettext("common", "Number of mitigations"),
        value: Mitigations.count_all_mitigations(organisation)
      },
      %{
        label: dgettext("common", "Total risk cost"),
        value: format_monetary_amount(total_cost)
      }
    ]
  end
end
