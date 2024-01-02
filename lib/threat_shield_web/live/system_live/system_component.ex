defmodule ThreatShieldWeb.SystemLive.SystemComponent do
  use ThreatShieldWeb, :live_component

  @impl true
  def render(assigns) do
    ~H"""
    <div class="systems" id="systems">
      <div class="px-8 py-6 bg-white rounded-lg shadow">
        <.stacked_list_header>
          <:name><%= dgettext("systems", "Systems") %></:name>

          <:subtitle>
            An IT system can consist of hardware, software or data or a combination of them. It helps organisations manage and process information efficiently. Examples are ERPs, CRMS, online shops, customer portals or enterprise applications.>
          </:subtitle>

          <:buttons>
            <.link
              :if={ThreatShield.Members.Rights.may(:create_system, @membership)}
              patch={~p"/organisations/#{@organisation.id}/systems/new"}
            >
              <.button_primary>
                <.icon name="hero-pencil" class="mr-1 mb-1" /><%= dgettext("systems", "New System") %>
              </.button_primary>
            </.link>
          </:buttons>
        </.stacked_list_header>
        <.stacked_list
          :if={not Enum.empty?(@organisation.systems)}
          id={"systems_for_org_#{@organisation.id}"}
          rows={@organisation.systems}
          row_click={
            fn system -> JS.navigate(~p"/organisations/#{@organisation.id}/systems/#{system.id}") end
          }
        >
          <:col :let={system}>
            <%= system.name %>
            <p class="text-gray-500 text-xs font-normal">
              <%= @threat_count %><span> Threats</span>
              <span>•</span>
              <%= @asset_count %><span> Assets</span>
            </p>
          </:col>
          <:col :let={system}><%= system.description %></:col>
        </.stacked_list>

        <p :if={Enum.empty?(@organisation.systems)} class="mt-4">
          There are no systems associated with this organisation. Please add them manually.
        </p>
      </div>
    </div>
    """
  end
end
