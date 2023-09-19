defmodule ThreatShieldWeb.DashboardLive.Index do
  use ThreatShieldWeb, :live_view

  alias ThreatShield.Organisations
  alias ThreatShield.Organisations.Organisation

  @impl true
  def mount(params, _session, socket) do
    user = socket.assigns.current_user

    org_id = Map.get(params, "org_id")

    if org_id do
      org = Organisations.get_organisation_for_dashboard!(user, org_id)

      {:ok,
       socket
       |> get_dashboard_data(org)}
    else
      case Organisations.get_first_organisation_if_existent(user) do
        {:ok, org} ->
          {:ok, socket |> get_dashboard_data(org)}

        _ ->
          {:ok, redirect(socket, to: "/organisations/new")}
      end
    end
  end

  defp get_dashboard_data(socket, organisation) do
    socket
    |> assign(:organisation, organisation)
    |> assign(:threats, organisation.threats)
    |> assign(:path_prefix, "/organisations/#{organisation.id}")
    |> assign(
      :membership,
      Organisation.get_membership(organisation, socket.assigns.current_user)
    )
  end
end
