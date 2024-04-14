defmodule ThreatShieldWeb.AdminLive.OrganisationsManagement do
  use ThreatShieldWeb, :live_view

  alias ThreatShield.Organisations
  alias ThreatShield.Const.Locations

  import ThreatShield.Accounts.Organisation, only: [attributes: 0]

  @impl true
  def mount(_params, _session, socket) do
    locations_options = Locations.list_locations()

    organisations = Organisations.list_organisations(socket.assigns.current_user)

    socket
    |> assign(locations_options: locations_options)
    |> stream_organisations(organisations)
    |> assign(:attributes, attributes())
    |> ok()
  end

  defp stream_organisations(socket, organisations) do
    stream(
      socket,
      :organisations,
      organisations
    )
  end
end
