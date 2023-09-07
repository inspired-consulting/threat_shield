defmodule ThreatShieldWeb.RiskLive.RiskComponent do
  use ThreatShieldWeb, :live_component

  @impl true
  def render(assigns) do
    ~H"""
    <div class="risks">
    <h3><%= @threat.description %></h3>
    <.table
      id={"risks_for_threat_#{@threat.id}"}
      rows={@threat.risks}
    >
    <:col :let={risk} label="Name"><%= risk.name %></:col>
      <:col :let={risk} label="Description"><%= risk.description %></:col>
      <:col :let={risk} label="Estimated cost"><%= risk.estimated_cost %></:col>
      <:col :let={risk} label="Probability"><%= risk.probability %></:col>
    </.table>
    </div>
    """
  end
end
