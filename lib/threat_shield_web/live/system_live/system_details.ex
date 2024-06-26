defmodule ThreatShieldWeb.SystemLive.SystemDetails do
  require Logger
  alias ThreatShield.Accounts.Organisation
  alias ThreatShield.Organisations
  alias ThreatShield.Accounts.User
  use ThreatShieldWeb, :live_view

  alias ThreatShield.Scope
  alias ThreatShield.Systems
  alias ThreatShield.Systems.System
  import ThreatShieldWeb.Helpers, only: [add_breadcrumbs: 2, link_to: 1]

  @impl true
  def mount(%{"sys_id" => id}, _session, socket) do
    %User{} = user = socket.assigns.current_user
    %System{} = system = Systems.get_system!(user, id)
    %Organisation{} = organisation = Organisations.get_organisation!(user, system.organisation.id)

    socket
    |> assign(:current_tab, :assets)
    |> assign(:system, system)
    |> assign(:organisation, organisation)
    |> assign(:membership, Organisation.get_membership(organisation, user))
    |> assign(:attributes, System.attributes())
    |> assign(:scope, Scope.for_system(user, organisation, system))
    |> assign(:ai_suggestions, %{})
    |> ok()
  end

  @impl true
  def handle_params(params, url, socket) do
    socket
    |> add_breadcrumbs(url)
    |> apply_action(socket.assigns.live_action, params)
    |> noreply()
  end

  defp apply_action(socket, :show, _params) do
    socket
    |> assign(:page_title, "Show System")
  end

  defp apply_action(socket, :edit_system, _params) do
    socket
    |> assign(:page_title, "Edit System")
  end

  # events and notifications

  @impl true
  def handle_info(
        {ThreatShieldWeb.SystemLive.SystemForm, {:saved, system}},
        socket
      ) do
    user = socket.assigns.current_user
    system = Systems.get_system!(user, system.id)

    {:noreply,
     socket
     |> assign(system: system)
     |> assign(organisation: system.organisation)
     |> assign(page_title: "Show System")}
  end

  @impl true
  def handle_info({ThreatShieldWeb.AssetLive.AssetForm, {:saved, asset}}, socket) do
    stale_sys = socket.assigns.system
    updated_sys = %{stale_sys | assets: stale_sys.assets ++ [asset]}

    {:noreply, socket |> assign(system: updated_sys) |> assign(page_title: "Show System")}
  end

  @impl true
  def handle_info({ThreatShieldWeb.ThreatLive.ThreatForm, {:saved, threat}}, socket) do
    stale_sys = socket.assigns.system
    updated_sys = %{stale_sys | threats: stale_sys.threats ++ [threat]}

    {:noreply, socket |> assign(system: updated_sys) |> assign(page_title: "Show System")}
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

  @impl true
  def handle_event("delete", %{"sys_id" => id}, socket) do
    current_user = socket.assigns.current_user

    {1, [_sys | _]} = Systems.delete_sys_by_id!(current_user, id)

    {:noreply,
     push_navigate(socket,
       to: "/organisations/#{socket.assigns.organisation.id}"
     )}
  end

  @impl true
  def handle_event("switch_tab", %{"tab" => tab}, socket) do
    socket
    |> assign(current_tab: String.to_existing_atom(tab))
    |> noreply()
  end
end
