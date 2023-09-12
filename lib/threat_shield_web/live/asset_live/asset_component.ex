defmodule ThreatShieldWeb.AssetLive.AssetComponent do
  use ThreatShieldWeb, :live_component

  import ThreatShield.Assets.Asset,
    only: [system_name: 1]

  @impl true
  def render(assigns) do
    ~H"""
    <div class="assets">
    <.table
      id={"assets_for_org_#{@organisation.id}"}
      rows={@assets}
      row_click={
        fn asset -> JS.navigate(~p"/organisations/#{@organisation.id}/assets/#{asset.id}") end
        }
    >
      <:col :let={asset} label="Description"><%= asset.description %></:col>
       <:col :let={asset} label="System" :if={!assigns[:hide_system]}><%= system_name(asset) %></:col>
    </.table>
    </div>
    """
  end
end
