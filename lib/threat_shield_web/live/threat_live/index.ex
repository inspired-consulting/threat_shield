defmodule ThreatShieldWeb.ThreatLive.Index do
  use ThreatShieldWeb, :live_view

  alias ThreatShield.Threats
  alias ThreatShield.Threats.Threat

  @impl true
  def mount(_params, _session, socket) do
    {:ok, stream(socket, :threats, Threats.list_threats())}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :edit, %{"id" => id}) do
    socket
    |> assign(:page_title, "Edit Threat")
    |> assign(:threat, Threats.get_threat!(id))
  end

  defp apply_action(socket, :new, _params) do
    socket
    |> assign(:page_title, "New Threat")
    |> assign(:threat, %Threat{})
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, "Listing Threats")
    |> assign(:threat, nil)
  end

  @impl true
  def handle_info({ThreatShieldWeb.ThreatLive.FormComponent, {:saved, threat}}, socket) do
    {:noreply, stream_insert(socket, :threats, threat)}
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    threat = Threats.get_threat!(id)
    {:ok, _} = Threats.delete_threat(threat)

    {:noreply, stream_delete(socket, :threats, threat)}
  end
end
