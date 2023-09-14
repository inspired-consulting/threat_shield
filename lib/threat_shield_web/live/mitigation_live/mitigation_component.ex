defmodule ThreatShieldWeb.MitigationLive.MitigationComponent do
  use ThreatShieldWeb, :live_component

  @impl true
  def render(assigns) do
    ~H"""
    <div class="mitigations">
    <.table
      id={"mitigations_for_risk_#{@risk.id}"}
      rows={@risk.mitigations}
      row_click={
        fn mitigation -> JS.navigate(@path_prefix <> "/threats/#{@threat.id}/risks/#{@risk.id}/mitigations/#{mitigation.id}") end
        }
    >
      <:col :let={mitigation} label="Name"><%= mitigation.name %></:col>
      <:col :let={mitigation} label="Description"><%= mitigation.description %></:col>
      <:col :let={mitigation} label="Is implemented"><%= mitigation.is_implemented %></:col>
    </.table>
    </div>
    """
  end
end
