defmodule ThreatShieldWeb.OrganisationLive.Index do
  use ThreatShieldWeb, :live_view

  alias ThreatShield.Organsations
  alias ThreatShield.Organsations.Organisation

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     stream(
       socket,
       :organisations,
       Organsations.list_organisations(socket.assigns.current_user) |> IO.inspect()
     )}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :edit, %{"id" => id}) do
    user = socket.assigns.current_user

    socket
    |> assign(:page_title, "Edit Organisation")
    |> assign(:organisation, Organsations.get_organisation_for_user!(id, user))
  end

  defp apply_action(socket, :new, _params) do
    socket
    |> assign(:page_title, "New Organisation")
    |> assign(:organisation, %Organisation{})
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, "Listing Organisations")
    |> assign(:organisation, nil)
  end

  @impl true
  def handle_info(
        {ThreatShieldWeb.OrganisationLive.FormComponent, {:saved, organisation}},
        socket
      ) do
    {:noreply, stream_insert(socket, :organisations, organisation)}
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    user = socket.assigns.user
    organisation = Organsations.get_organisation_for_user!(id, user)
    {:ok, _} = Organsations.delete_organisation(organisation)

    {:noreply, stream_delete(socket, :organisations, organisation)}
  end
end
