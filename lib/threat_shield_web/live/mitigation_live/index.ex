defmodule ThreatShieldWeb.MitigationLive.Index do
  use ThreatShieldWeb, :live_view

  alias ThreatShield.Mitigations
  alias ThreatShield.Mitigations.Mitigation

  @impl true
  def mount(%{"risk_id" => risk_id}, _session, socket) do
    user = socket.assigns.current_user

    risk = Mitigations.get_risk!(user, risk_id)

    {:ok,
     socket
     |> assign(:risk, risk)
     |> assign(:threat, risk.threat)
     |> assign(:organisation, risk.threat.organisation)
     |> stream(:mitigations, risk.mitigations)}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :edit, %{"mitigation_id" => id}) do
    user = socket.assigns.current_user

    socket
    |> assign(:page_title, "Edit Mitigation")
    |> assign(:mitigation, Mitigations.get_mitigation!(user, id))
  end

  defp apply_action(socket, :new, _params) do
    socket
    |> assign(:page_title, "New Mitigation")
    |> assign(:mitigation, %Mitigation{})
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, "Listing Mitigations")
    |> assign(:mitigation, nil)
  end

  @impl true
  def handle_info({ThreatShieldWeb.MitigationLive.FormComponent, {:saved, mitigation}}, socket) do
    {:noreply, stream_insert(socket, :mitigations, mitigation)}
  end

  @impl true
  def handle_event("delete", %{"mitigation_id" => id}, socket) do
    user = socket.assigns.current_user

    {1, [mitigation | _]} = Mitigations.delete_mitigation_by_id!(user, id)

    {:noreply, stream_delete(socket, :mitigations, mitigation)}
  end
end
