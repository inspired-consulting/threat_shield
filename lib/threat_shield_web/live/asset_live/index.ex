defmodule ThreatShieldWeb.AssetLive.Index do
  use ThreatShieldWeb, :live_view

  alias ThreatShield.Assets
  alias ThreatShield.Assets.Asset
  alias ThreatShield.AI

  import ThreatShield.Assets.Asset,
    only: [system_name: 1]

  import ThreatShield.Organisations.Organisation,
    only: [list_system_options: 1]

  @impl true
  def mount(%{"org_id" => org_id}, _session, socket) do
    current_user = socket.assigns.current_user

    organisation = Assets.get_organisation!(current_user, org_id)
    assets = organisation.assets

    socket =
      socket
      |> assign(
        organisation: organisation,
        asking_ai: nil,
        asset_suggestions: []
      )

    {:ok, stream(socket, :assets, assets)}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :edit, %{"asset_id" => id}) do
    socket
    |> assign(:page_title, "Edit Asset")
    |> assign(:asset, Assets.get_asset!(socket.assigns.current_user, id))
  end

  defp apply_action(socket, :new, _params) do
    socket
    |> assign(:page_title, "New Asset")
    |> assign(:asset, %Asset{})
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, "Listing Assets")
    |> assign(:asset, nil)
  end

  @impl true
  def handle_info({ThreatShieldWeb.AssetLive.FormComponent, {:saved, asset}}, socket) do
    {:noreply, stream_insert(socket, :assets, asset)}
  end

  def handle_info({_from, {:ai_results, new_assets}}, socket) do
    %{asking_ai: ref} = socket.assigns

    Process.demonitor(ref, [:flush])

    {:noreply,
     socket
     |> assign(
       asking_ai: nil,
       asset_suggestions: socket.assigns.asset_suggestions ++ new_assets
     )}
  end

  @impl true
  def handle_event("delete", %{"description" => description}, socket) do
    suggestions =
      Enum.filter(socket.assigns.asset_suggestions, fn s -> s.description != description end)
      |> Enum.to_list()

    {:noreply, socket |> assign(asset_suggestions: suggestions)}
  end

  @impl true
  def handle_event("add", %{"description" => description}, socket) do
    user = socket.assigns.current_user
    org_id = socket.assigns.organisation.id

    {:ok, asset} = Assets.add_asset_with_description(user, org_id, description)

    suggestions =
      Enum.filter(socket.assigns.asset_suggestions, fn s -> s.description != description end)
      |> Enum.to_list()

    {:noreply, socket |> stream_insert(:assets, asset) |> assign(:asset_suggestions, suggestions)}
  end

  @impl true
  def handle_event("suggest", %{"org_id" => org_id}, socket) do
    user = socket.assigns.current_user

    task =
      Task.Supervisor.async_nolink(ThreatShield.TaskSupervisor, fn ->
        ask_ai(user, org_id)
      end)

    socket =
      socket
      |> assign(asking_ai: task.ref)

    {:noreply, socket}
  end

  defp ask_ai(user, org_id) do
    organisation = Assets.get_organisation!(user, org_id)

    new_assets =
      AI.suggest_assets_for_organisation(organisation)

    {:ai_results, new_assets}
  end
end
