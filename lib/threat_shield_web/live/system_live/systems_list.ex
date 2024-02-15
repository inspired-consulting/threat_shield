defmodule ThreatShieldWeb.SystemLive.SystemsList do
  alias ThreatShield.Organisations.Organisation
  use ThreatShieldWeb, :live_component

  alias ThreatShield.Scope
  alias ThreatShield.Systems.System
  alias ThreatShield.Organisations.Organisation

  require Logger

  @moduledoc """
  This component renders a list of systems for a given organisation.
  It also provides a button to create a new system in a modal dialog.
  """

  @impl true
  def render(assigns) do
    ~H"""
    <div class="systems" id="systems">
      <div class="px-8 py-6 bg-white rounded-lg shadow">
        <.stacked_list_header>
          <:name>
            <span class="text-gray-700 inline-block">
              <Icons.system_icon class="w-5 h-5" />
            </span>
            <%= dgettext("systems", "Systems") %>
          </:name>

          <:subtitle>
            <%= dgettext("systems", "System: short description") %>
          </:subtitle>

          <:buttons>
            <.link
              :if={ThreatShield.Members.Rights.may(:create_system, @scope.membership)}
              phx-click="open-create-system-modal"
              phx-target={@myself}
            >
              <.button_primary>
                <.icon name="hero-pencil" class="mr-1 mb-1" /><%= dgettext("systems", "New System") %>
              </.button_primary>
            </.link>
          </:buttons>
        </.stacked_list_header>
        <.stacked_list
          :if={not Enum.empty?(@systems)}
          id={"systems_for_#{@scope.id}"}
          rows={@systems}
          row_click={
            fn system ->
              JS.navigate(~p"/organisations/#{@scope.organisation.id}/systems/#{system.id}")
            end
          }
        >
          <:col :let={system}>
            <%= system.name %>
            <p class="text-gray-500 text-xs font-normal">
              <%= @threat_count %><span> Threats</span>
              <span>•</span>
              <%= @asset_count %><span> Assets</span>
            </p>
          </:col>
          <:col :let={system}><%= system.description %></:col>
        </.stacked_list>

        <p :if={Enum.empty?(@scope.organisation.systems)} class="mt-4">
          There are no systems associated with this organisation. Please add them manually.
        </p>
      </div>
      <.modal
        :if={assigns[:show_modal] == true}
        id="create-system-modal"
        show
        on_cancel={JS.navigate(@origin)}
      >
        <.live_component
          module={ThreatShieldWeb.SystemLive.SystemForm}
          id={:new}
          parent_id={@id}
          title={dgettext("systems", "New System")}
          action={:new_system}
          organisation={@scope.organisation}
          current_user={@scope.user}
          attributes={System.attributes()}
          system={prepare_system(assigns)}
          patch={@origin}
        />
      </.modal>
    </div>
    """
  end

  # lifecycle and events

  @impl true
  def update(%{added_system: system} = assigns, socket) do
    old_systems = assigns[:systems] || []

    socket
    |> assign(:show_modal, false)
    |> assign(:systems, old_systems ++ [system])
    |> ok()
  end

  @impl true
  def update(assigns, socket) do
    scope = %Scope{} = assigns.scope

    socket
    |> assign(assigns)
    |> assign(:systems, scope.organisation.systems)
    |> ok()
  end

  @impl true
  def handle_event("open-create-system-modal", _params, socket) do
    socket
    |> assign(:show_modal, true)
    |> noreply()
  end

  # internal

  defp prepare_system(%{organisation: %Organisation{} = org}) do
    %System{organisation: org, organisation_id: org.id}
  end

  defp prepare_system(_other), do: %System{}
end
