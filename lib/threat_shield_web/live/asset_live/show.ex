defmodule ThreatShieldWeb.AssetLive.Show do
  use ThreatShieldWeb, :live_view

  alias ThreatShield.Assets
  alias ThreatShield.Assets.Asset

  import ThreatShieldWeb.ScopeUrlBinding

  import ThreatShield.Organisations.Organisation,
    only: [list_system_options: 1, list_asset_options: 1]

  import ThreatShieldWeb.Helpers, only: [add_breadcrumbs: 2, get_path_prefix: 1]

  import ThreatShieldWeb.Labels, only: [system_label: 1]

  @impl true
  def mount(%{"asset_id" => asset_id} = params, _session, socket) do
    current_user = socket.assigns.current_user
    asset = Assets.get_asset!(current_user, asset_id)

    scope = asset_scope_from_params(current_user, asset, params)

    socket
    |> assign(scope: scope)
    |> assign(asset: asset)
    |> assign(organisation: asset.organisation)
    |> assign(system: asset.system)
    |> assign(system_options: list_system_options(asset.organisation))
    |> assign(asset_options: list_asset_options(asset.organisation))
    |> assign(origin: asset_scope_to_url(scope))
    |> assign(ai_suggestions: %{})
    |> ok()
  end

  @impl true
  def handle_params(_params, url, socket) do
    {:noreply,
     socket
     |> add_breadcrumbs(url)
     |> assign(:page_title, page_title(socket.assigns.live_action))}
  end

  @impl true
  def handle_event("delete", %{"asset_id" => asset_id}, socket) do
    user = socket.assigns.current_user
    {1, [_asset]} = Assets.delete_asset_by_id(user, asset_id)

    {:noreply, push_navigate(socket, to: get_path_prefix(socket.assigns))}
  end

  @impl true
  def handle_info({ThreatShieldWeb.ThreatLive.ThreatForm, {:saved, threat}}, socket) do
    stale_asset = %Asset{} = socket.assigns.asset

    socket
    |> assign(asset: %Asset{stale_asset | threats: stale_asset.threats ++ [threat]})
    |> noreply()
  end

  @impl true
  def handle_info(
        {ThreatShieldWeb.AssetLive.AssetForm, {:saved, asset}},
        socket
      ) do
    asset = Assets.get_asset!(socket.assigns.current_user, asset.id)

    {:noreply,
     socket
     |> assign(asset: asset)
     |> assign(organisation: asset.organisation)
     |> assign(:system, asset.system)
     |> assign(page_title: "Show Asset")}
  end

  @impl true
  def handle_info({task_ref, {:new_ai_suggestion, suggestion}}, socket) do
    %{type: entity_type, result: result} = suggestion

    # stop monitoring the task
    Process.demonitor(task_ref, [:flush])

    suggestions =
      (socket.assigns[:suggestions] || %{})
      |> Map.put(entity_type, result)

    socket
    |> assign(ai_suggestions: suggestions)
    |> noreply()
  end

  defp page_title(:show), do: "Show Asset"
  defp page_title(:edit), do: "Edit Asset"
end
