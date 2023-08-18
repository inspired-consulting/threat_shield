defmodule ThreatShieldWeb.RiskLive.Index do
  use ThreatShieldWeb, :live_view

  alias ThreatShield.Risks
  alias ThreatShield.Risks.Risk

  @impl true
  def mount(%{"org_id" => org_id, "threat_id" => threat_id}, _session, socket) do
    current_user = socket.assigns.current_user
    threat = Risks.get_threat!(current_user, org_id, threat_id)

    {:ok,
     socket
     |> assign(:organisation, threat.organisation)
     |> assign(:threat, threat)
     |> stream(:risks, threat.risks)}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :edit, %{"risk_id" => id}) do
    user = socket.assigns.current_user

    socket
    |> assign(:page_title, "Edit Risk")
    |> assign(:risk, Risks.get_risk!(user, id))
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
  def handle_event("delete", %{"risk_id" => id}, socket) do
    current_user = socket.assigns.current_user

    {1, [risk | _]} = Risks.delete_risk_by_id!(current_user, id)

    {:noreply, stream_delete(socket, :risks, risk)}
  end
end
