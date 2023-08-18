defmodule ThreatShieldWeb.RiskLive.Index do
  use ThreatShieldWeb, :live_view

  alias ThreatShield.Risks
  alias ThreatShield.Risks.Risk

  @impl true
  def mount(_params, _session, socket) do
    {:ok, stream(socket, :risks, Risks.list_risks())}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :edit, %{"id" => id}) do
    socket
    |> assign(:page_title, "Edit Risk")
    |> assign(:risk, Risks.get_risk!(id))
  end

  defp apply_action(socket, :new, _params) do
    socket
    |> assign(:page_title, "New Risk")
    |> assign(:risk, %Risk{})
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, "Listing Risks")
    |> assign(:risk, nil)
  end

  @impl true
  def handle_info({ThreatShieldWeb.RiskLive.FormComponent, {:saved, risk}}, socket) do
    {:noreply, stream_insert(socket, :risks, risk)}
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    risk = Risks.get_risk!(id)
    {:ok, _} = Risks.delete_risk(risk)

    {:noreply, stream_delete(socket, :risks, risk)}
  end
end
