defmodule ThreatShieldWeb.DashboardLive.Index do
  use ThreatShieldWeb, :live_view

  alias ThreatShield.Organisations

  @impl true
  def mount(params, _session, socket) do
    user = socket.assigns.current_user

    org_id = Map.get(params, "org_id")

    if org_id do
      org = Organisations.get_organisation_for_dashboard!(user, org_id)

      {:ok,
       socket
       |> assign(:organisation, org)
       |> stream(:threats, org.threats)}
    else
      case Organisations.get_first_organisation_if_existent(user) do
        {:ok, org} -> {:ok, socket |> assign(:organisation, org) |> stream(:threats, org.threats)}
        _ -> {:ok, redirect(socket, to: "/organisations/new")}
      end
    end
  end
end
