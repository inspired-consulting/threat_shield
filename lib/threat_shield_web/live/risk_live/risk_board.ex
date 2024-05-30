defmodule ThreatShieldWeb.RiskLive.RiskBoard do
  require Logger
  alias ThreatShield.Accounts.Organisation
  use ThreatShieldWeb, :live_view

  alias ThreatShield.{Risks, Threats, Mitigations, Members}
  alias ThreatShield.Risks.Risk

  import ThreatShieldWeb.Helpers
  import ThreatShieldWeb.Gettext
  import ThreatShieldWeb.Icons
  import ThreatShieldWeb.InfoVis

  @moduledoc """
  See an overview of all risks in the organisation.
  """

  @impl true
  def render(assigns) do
    ~H"""
    <section class="w-full bg-white py-4 shadow-primary-200 shadow-sm">
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
        <div class="flex gap-4">
          <div :for={item <- @summary}>
            <span class="text-gray-700 inline-block"><%= item.label %>:</span>
            <span class="text-gray-700 inline-block"><%= item.value %></span>
          </div>
        </div>
      </div>
    </section>

    <section class="mx-2 lg:mx-auto mt-4 flex flex-wrap gap-4 justify-center lg:max-w-[82rem] 2xl:max-w-[92rem]">
      <div class="none md:block px-6 py-6 bg-white rounded-lg shadow">
        <.risk_quadrants risk_model={@risk_model} size={700} show_labels={true} />
      </div>

      <div class="px-4 pt-4 bg-white rounded-lg shadow" id="risks_by_status" phx-update="ignore">
        <h2 class="px-2 font-semibold flex">
          <.risk_icon class="w-5 h-6 mr-2" /><%= dgettext("risks", "Risk by status") %>
        </h2>
        <div
          class="chart px-2 lg:px-4 w-[16rem] lg:w-[22rem] xl:w-[22rem] "
          data-chart-type="doughnut"
          data-data-point-label={dgettext("risk-board", "Number of risks")}
          data-datasets={@risks_by_status.data |> Jason.encode!()}
          data-dataset-labels={@risks_by_status.labels |> Jason.encode!()}
          data-colors={@risks_by_status.colors |> Jason.encode!()}
        >
          <canvas></canvas>
        </div>
        <h2 class="px-2 font-semibold flex">
          <.mitigation_icon class="w-6 h-6 mr-2" /><%= dgettext("risks", "Mitigations by status") %>
        </h2>
        <div
          class="chart px-2 lg:px-4 py-2 w-[16rem] lg:w-[22rem]"
          data-chart-type="doughnut"
          data-data-point-label={dgettext("risk-board", "Number of mitigations")}
          data-datasets={@mitigations_by_status.data |> Jason.encode!()}
          data-dataset-labels={@mitigations_by_status.labels |> Jason.encode!()}
          data-colors={@mitigations_by_status.colors |> Jason.encode!()}
        >
          <canvas></canvas>
        </div>
      </div>

      <div class="px-6 py-6 bg-white rounded-lg shadow w-[24rem] lg:w-[34rem] xl:w-[38rem]">
        <h2 class="px-2 font-semibold"><%= dgettext("risks", "Top 10 risks by severity") %></h2>
        <table class="mt-2 w-full">
          <tr
            :for={risk <- @top_10_severity}
            phx-click="risk-selected"
            phx-value-risk-id={risk.id}
            class="cursor-pointer hover:bg-gray-100"
          >
            <td class="pl-2 leading-1"><%= risk.name %></td>
            <td class="pl-8 py-1">
              <.criticality_badge value={risk.severity} title={dgettext("risks", "Severity")} />
            </td>
          </tr>
        </table>
      </div>

      <div class="px-6 py-6 bg-white rounded-lg shadow w-[24rem] lg:w-[34rem] xl:w-[38rem]">
        <h2 class="px-2 font-semibold"><%= dgettext("risks", "Top 10 risks by costs") %></h2>
        <table class="mt-2 w-full">
          <tr
            :for={risk <- @top_10_costs}
            phx-click="risk-selected"
            phx-value-risk-id={risk.id}
            class="cursor-pointer hover:bg-gray-100"
          >
            <td class="pl-2 leading-1"><%= risk.name %></td>
            <td class="px-4 py-2 text-end">
              <%= risk_cost(risk) |> format_monetary_amount() %>
            </td>
          </tr>
        </table>
      </div>
    </section>
    """
  end

  @impl true
  def mount(%{"org_id" => org_id}, _session, socket) do
    user = socket.assigns.current_user
    organisation = Members.get_organisation!(user, org_id)

    risks = Risks.get_all_risks(user, organisation.id)
    mitigations = Mitigations.get_all_mitigations(user, organisation.id)

    socket
    |> assign(:organisation, organisation)
    |> assign(:risks, risks)
    |> assign(:risk_model, risk_model(risks, organisation))
    |> assign(:top_10_severity, top_10_severity(risks))
    |> assign(:top_10_costs, top_10_risk_costs(risks))
    |> assign(:risks_by_status, risks_by_status(risks))
    |> assign(:mitigations_by_status, mitigations_by_status(mitigations))
    |> assign(:summary, summary(organisation, risks))
    |> ok()
  end

  @impl true
  def handle_event("risk-selected", %{"risk-id" => risk_id}, socket) do
    {risk_id, _} = Integer.parse(risk_id)

    %Risk{} =
      risk =
      socket.assigns.risks
      |> Enum.find(&(&1.id == risk_id))

    socket
    |> push_navigate(to: link_to(risk, socket.assigns.organisation))
    |> noreply()
  end

  # internal

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

  defp mitigations_by_status(mitigations) do
    groups = %{
      open: 0,
      in_progress: 0,
      implemented: 0,
      verified: 0,
      failed: 0,
      deferred: 0,
      obsolete: 0
    }

    groups =
      mitigations
      |> Enum.reduce(groups, fn m, acc ->
        Map.update(acc, m.status, 1, &(&1 + 1))
      end)

    %{
      labels: [
        dgettext("mitigations", "State:open"),
        dgettext("mitigations", "State:in_progress"),
        dgettext("mitigations", "State:implemented"),
        dgettext("mitigations", "State:verified"),
        dgettext("mitigations", "State:failed"),
        dgettext("mitigations", "State:deferred"),
        dgettext("mitigations", "State:obsolete")
      ],
      data: [
        groups[:open],
        groups[:in_progress],
        groups[:implemented],
        groups[:verified],
        groups[:failed],
        groups[:deferred],
        groups[:obsolete]
      ],
      colors: ["#E89E2E", "#CCCC10", "#59CE56", "#47A545", "#B53139", "#6997EA", "#6997EA"]
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

  defp risk_cost(%Risk{} = risk), do: Risk.estimated_risk_cost(risk)

  defp risk_model([], _organisation), do: []

  defp risk_model(risks, %Organisation{} = organisation) when is_list(risks) do
    max_cost =
      risks
      |> Enum.filter(&(Risk.estimated_risk_cost(&1) != nil))
      |> Enum.max_by(&Risk.estimated_risk_cost(&1))
      |> Risk.estimated_risk_cost()

    max_frequency =
      risks
      |> Enum.filter(&(Risk.frequency_per_year(&1) != nil))
      |> Enum.max_by(&Risk.frequency_per_year(&1))
      |> Risk.frequency_per_year()

    risks
    |> Enum.sort_by(&Risk.severity/1)
    |> Enum.map(fn risk ->
      %{
        id: risk.id,
        name: risk.name,
        cost: normalized_risk_cost(risk, max_cost),
        frequency: normalized_risk_frequency(risk, max_frequency),
        severity: normalized_risk_severity(risk),
        color: color_code_for_criticality(risk.severity, 0.7),
        cost_label: format_monetary_amount(risk_cost(risk)),
        frequency_label: format_number(risk.probability),
        severity_label: format_number(risk.severity),
        link: link_to(risk, organisation)
      }
    end)
  end

  defp normalized_risk_cost(%Risk{} = risk, max_cost) do
    case risk_cost(risk) do
      nil -> 0.0
      cost -> 0.1 + cost / max_cost
    end
  end

  defp normalized_risk_frequency(%Risk{} = risk, max_frequency) do
    case risk.probability do
      nil -> 0
      frequency -> 0.05 + frequency / max_frequency * 0.9
    end
  end

  defp normalized_risk_severity(%Risk{} = risk, max_severity \\ 5.0) do
    case risk.severity do
      nil -> 0
      severity -> severity / max_severity
    end
  end
end
