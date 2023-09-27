defmodule ThreatShieldWeb.ThreatLive.ThreatComponent do
  use ThreatShieldWeb, :live_component

  @impl true
  def render(assigns) do
    ~H"""
    <div class="threats">
      <div class="mt-4 px-8 py-6 bg-white rounded-lg shadow">
        <.stacked_list_header>
          <:name><%= dgettext("threats", "Threats") %></:name>

          <:subtitle>
            Threats are any potential event or action that can compromise the security of a system, organisation, or individual. Threats are not the negative outcome, i.e. not the loss, damage, or harm resulting from the exploitation of vulnerabilities by threats.
          </:subtitle>

          <:buttons>
            <.link
              :if={ThreatShield.Members.Rights.may(:create_threat, @membership)}
              patch={@path_prefix <> "/threats/new"}
            >
              <.button_primary>
                <.icon name="hero-hand-raised" class="mr-1 mb-1" /><%= dgettext(
                  "threats",
                  "New Threat"
                ) %>
              </.button_primary>
            </.link>
            <.link>
              <.button_primary
                :if={ThreatShield.Members.Rights.may(:create_threat, @membership)}
                disabled={not is_nil(@asking_ai_for_threats)}
                phx-click="suggest_threats"
                phx-value-org_id={@organisation.id}
                phx-value-sys_id={if is_nil(assigns[:system]), do: nil, else: @system.id}
              >
                <.icon name="hero-shield-check" class="mr-1 mb-1" /><%= dgettext(
                  "assets",
                  "Suggest Threats"
                ) %>
              </.button_primary>
            </.link>
          </:buttons>
        </.stacked_list_header>
        <.stacked_list
          :if={not Enum.empty?(@threats)}
          id={"threats_for_org_#{@organisation.id}"}
          rows={@threats}
          row_click={fn threat -> JS.navigate(@path_prefix <> "/threats/#{threat.id}") end}
        >
          <:col :let={threat}>
            <%= threat.name %>
          </:col>
          <:col :let={threat}><%= threat.description %></:col>
        </.stacked_list>

        <p :if={Enum.empty?(@threats)} class="mt-4">
          There are no threats. Please add them manually.
        </p>
      </div>
    </div>
    """
  end
end
