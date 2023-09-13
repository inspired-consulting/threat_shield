defmodule ThreatShieldWeb.SystemLive.SystemComponent do
  use ThreatShieldWeb, :live_component

  @impl true
  def render(assigns) do
    ~H"""
    <div class="systems">
    <.table
      id={"systems_for_org_#{@organisation.id}"}
      rows={@organisation.systems}
      row_click={
        fn system -> JS.navigate(~p"/organisations/#{@organisation.id}/systems/#{system.id}") end
        }
    >
    <:col :let={system} label="Name"><%= system.name %></:col>
      <:col :let={system} label="Description"><%= system.description %></:col>
      <:col :let={system} label="Attributes">
        <%= for {key, value} <- system.attributes do %>
          <div><%= "#{key} → #{value}" %></div>
        <% end %>
      </:col>
    </.table>
    </div>
    """
  end
end
