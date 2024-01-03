defmodule ThreatShieldWeb.RiskLive.RisksList do
  use ThreatShieldWeb, :live_component

  @moduledoc """
  This component renders a list of risks for a given threat.
  """

  @impl true
  def render(assigns) do
    ~H"""
    <div class="mt-4 px-8 py-6 bg-white rounded-lg shadow">
      <.stacked_list_header>
        <:name><%= dgettext("risks", "Risks") %></:name>

        <:subtitle>
          <%= dgettext("risks", "Risk: short description") %>
        </:subtitle>

        <:buttons>
          <.link
            :if={ThreatShield.Members.Rights.may(:create_risk, @membership)}
            patch={@path_prefix <> "/threats/#{@threat.id}/risks/new"}
          >
            <.button_primary>
              <.icon name="hero-hand-raised" class="mr-1 mb-1" /><%= dgettext(
                "risks",
                "New Risk"
              ) %>
            </.button_primary>
          </.link>
          <.link>
            <.button_magic
              :if={ThreatShield.Members.Rights.may(:create_threat, @membership)}
              disabled={not is_nil(@asking_ai_for_risks)}
              phx-click="suggest_risks"
              phx-value-threat_id={@threat.id}
            >
              <.icon name="hero-sparkles" class="mr-1 mb-1" /><%= dgettext(
                "risks",
                "Suggest Risks"
              ) %>
            </.button_magic>
          </.link>
        </:buttons>
      </.stacked_list_header>
      <.stacked_list
        :if={not Enum.empty?(@risks)}
        id={"risks_for_threat_#{@threat.id}"}
        rows={@risks}
        row_click={
          fn risk -> JS.navigate(@path_prefix <> "/threats/#{@threat.id}/risks/#{risk.id}") end
        }
      >
        <:col :let={risk}>
          <%= risk.name %>
        </:col>
        <:col :let={risk}>
          <.risk_status_badge status={risk.status} light={true} />
        </:col>
        <:col :let={risk}><%= risk.description %></:col>
        <:col :let={risk}>
          <.criticality_badge value={risk.severity} title={dgettext("risks", "Severity")} />
        </:col>
      </.stacked_list>

      <p :if={Enum.empty?(@risks)} class="mt-4">
        There are no risks. Please add them manually.
      </p>
    </div>
    """
  end
end
