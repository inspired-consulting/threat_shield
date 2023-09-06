defmodule ThreatShieldWeb.DashboardLive do
  use ThreatShieldWeb, :live_view

  alias ThreatShieldWeb.OrganisationLive.Index
  alias ThreatShieldWeb.ThreatLive.Index

  alias ThreatShield.Organisations

  def mount(params, _session, socket) do
    user = socket.assigns.current_user

    org_id = Map.get(params, "org_id")

    if org_id do
      org = Organisations.get_organisation!(user, org_id)
      {:ok, assign(socket, :organisation, org)}
    else
      case Organisations.get_first_organisation_if_existent(user) do
        {:ok, org} -> {:ok, assign(socket, :organisation, org)}
        _ -> {:ok, redirect(socket, to: "/organisations/new")}
      end
    end
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
      <p><%= @organisation.name %></p>
    """
  end
end
