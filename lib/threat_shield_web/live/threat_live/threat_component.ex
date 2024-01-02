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
            <%= dgettext("threats", "Threat: short description") %>
          </:subtitle>

          <:buttons>
            <.link
              :if={ThreatShield.Members.Rights.may(:create_threat, @membership)}
              patch={@path_prefix <> "/threats/new"}
            >
              <.button_primary>
                <.icon name="hero-cursor-arrow-ripple" class="mr-1 mb-1" /><%= dgettext(
                  "threats",
                  "New Threat"
                ) %>
              </.button_primary>
            </.link>
            <.link>
              <.button_magic
                :if={ThreatShield.Members.Rights.may(:create_threat, @membership)}
                disabled={not is_nil(@asking_ai_for_threats)}
                phx-click="suggest_threats"
                phx-value-org_id={@organisation.id}
                phx-value-sys_id={if is_nil(assigns[:system]), do: nil, else: @system.id}
              >
                <.icon name="hero-sparkles" class="mr-1 mb-1" /><%= dgettext(
                  "assets",
                  "Suggest Threats"
                ) %>
              </.button_magic>
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
