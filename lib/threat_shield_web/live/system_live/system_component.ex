defmodule ThreatShieldWeb.SystemLive.SystemComponent do
  use ThreatShieldWeb, :live_component

  @impl true
  def render(assigns) do
    ~H"""
    <div class="systems">
      <.stacked_list_header>
        <:name><%= dgettext("systems", "Systems") %></:name>
        <:buttons>
          <.link
            :if={ThreatShield.Members.Rights.may(:create_system, @membership)}
            patch={~p"/organisations/#{@organisation.id}/systems/new"}
          >
            <.button_primary>
              <.icon name="hero-pencil" /><%= dgettext("systems", "New System") %>
            </.button_primary>
          </.link>
        </:buttons>
      </.stacked_list_header>
      <.stacked_list
        id={"systems_for_org_#{@organisation.id}"}
        rows={@organisation.systems}
        row_click={
          fn system -> JS.navigate(~p"/organisations/#{@organisation.id}/systems/#{system.id}") end
        }
      >
        <:col :let={system}><%= system.name %></:col>
        <:col :let={system}><%= system.description %></:col>
      </.stacked_list>
    </div>
    """
  end
end
