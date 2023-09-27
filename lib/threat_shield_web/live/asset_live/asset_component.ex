defmodule ThreatShieldWeb.AssetLive.AssetComponent do
  use ThreatShieldWeb, :live_component

  import ThreatShield.Assets.Asset,
    only: [system_name: 1]

  @impl true
  def render(assigns) do
    ~H"""
    <div class="assets" id="assets">
      <.table
        id={"assets_for_org_#{@organisation.id}"}
        rows={@assets}
        row_click={fn asset -> JS.navigate(@path_prefix <> "/assets/#{asset.id}") end}
      >
        <:col :let={asset} label="Name"><%= asset.name %></:col>
        <:col :let={asset} :if={!assigns[:hide_system]} label="System">
          <%= system_name(asset) %>
        </:col>
      </.table>
    </div>
    """
  end
end
