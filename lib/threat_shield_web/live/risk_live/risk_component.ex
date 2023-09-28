defmodule ThreatShieldWeb.RiskLive.RiskComponent do
  use ThreatShieldWeb, :live_component

  @impl true
  def render(assigns) do
    ~H"""
    <div class="mt-4 px-8 py-6 bg-white rounded-lg shadow">
      <.stacked_list_header>
        <:name><%= dgettext("risks", "Risks") %></:name>

        <:subtitle>
          Risks are the potential negative outcome — loss, damage, or harm resulting from the exploitation of vulnerabilities by threats.
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
            <.button_primary
              :if={ThreatShield.Members.Rights.may(:create_threat, @membership)}
              disabled={not is_nil(@asking_ai_for_risks)}
              phx-click="suggest_risks"
              phx-value-threat_id={@threat.id}
            >
              <.icon name="hero-shield-check" class="mr-1 mb-1" /><%= dgettext(
                "risks",
                "Suggest Risks"
              ) %>
            </.button_primary>
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
        <:col :let={risk}><%= risk.description %></:col>
      </.stacked_list>

      <p :if={Enum.empty?(@risks)} class="mt-4">
        There are no risks. Please add them manually.
      </p>
    </div>
    """
  end
end
