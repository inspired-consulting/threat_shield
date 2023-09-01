defmodule ThreatShieldWeb.DashboardLive do
  use ThreatShieldWeb, :live_view

  alias ThreatShieldWeb.OrganisationLive.Index
  alias ThreatShieldWeb.ThreatLive.Index
  alias ThreatShieldWeb.RiskLive.Index

  def mount(_params, _session, socket) do
    {:ok, assign(socket, active_component: :organisations)}
  end

  def handle_event("show_organisations", _params, socket) do
    {:noreply, assign(socket, active_component: :organisations)}
  end

  def handle_event("show_threats", _params, socket) do
    {:noreply, assign(socket, active_component: :threats)}
  end

  def handle_event("show_risks", _params, socket) do
    {:noreply, assign(socket, active_component: :risks)}
  end

  def render(assigns) do
    active_component = Map.get(assigns, :active_component)

    ~L"""

    """
  end
end
