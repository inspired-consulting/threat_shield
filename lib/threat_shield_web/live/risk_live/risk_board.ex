defmodule ThreatShieldWeb.RiskLive.RiskBoard do
  use ThreatShieldWeb, :live_view

  alias ThreatShield.{Risks, Threats, Members}

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
    <section class="ts-container mt-8 grid grid-cols-2 gap-6">
      <div class="mt-4 px-8 py-6 bg-white rounded-lg shadow">
        <h2 class="font-semibold"><%= dgettext("risks", "Summary") %></h2>
        <.table id="top_10_risks" rows={@summary}>
          <:col :let={item}><%= item.label %></:col>
          <:col :let={item}><%= item.value %></:col>
        </.table>
      </div>

      <div class="mt-4 px-8 py-6 bg-white rounded-lg shadow">
        <h2 class="font-semibold"><%= dgettext("risks", "Top 10 Risks") %></h2>
        <.table
          id="top_10_risks"
          rows={@top_10_risks}
          row_click={fn risk -> JS.navigate(link_to(risk, @organisation)) end}
        >
          <:col :let={risk} label={dgettext("common", "Risk")}><%= risk.name %></:col>
          <:col :let={risk} label={dgettext("common", "Severity")}>
            <.criticality_badge value={risk.severity} title={dgettext("risks", "Severity")} />
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
    |> assign(:top_10_risks, top_10(risks))
    |> assign(:summary, summary(organisation, risks))
    |> ok()
  end

  defp top_10(risks) do
    risks
    |> Enum.sort_by(& &1.severity)
    |> Enum.reverse()
    |> Enum.take(10)
  end

  defp summary(organisation, risks) do
    [
      %{label: dgettext("common", "Number of risks"), value: Enum.count(risks)},
      %{
        label: dgettext("common", "Number of threats"),
        value: Threats.count_all_threats(organisation)
      }
    ]
  end
end
