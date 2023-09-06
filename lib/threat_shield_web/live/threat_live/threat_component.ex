defmodule ThreatShieldWeb.ThreatLive.ThreatComponent do
  use ThreatShieldWeb, :live_component

  import ThreatShield.Threats.Threat,
    only: [system_name: 1]

  @impl true
  def render(assigns) do
    ~H"""
    <div class="threats">
    <.table
      id="threats"
      rows={@threats}
    >
      <:col :let={{_id, threat}} label="Description"><%= threat.description %></:col>
      <:col :let={{_id, threat}} label="System"><%= system_name(threat) %></:col>
    </.table>
    </div>
    """
  end
end
