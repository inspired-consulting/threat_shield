defmodule ThreatShieldWeb.SystemLive.SystemsList do
  alias ThreatShield.Organisations.Organisation
  use ThreatShieldWeb, :live_component

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
          <:name><%= dgettext("systems", "Systems") %></:name>

          <:subtitle>
            <%= dgettext("systems", "System: short description") %>
          </:subtitle>

          <:buttons>
            <.link
              :if={ThreatShield.Members.Rights.may(:create_system, @membership)}
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
          :if={not Enum.empty?(@organisation.systems)}
          id={"systems_for_org_#{@organisation.id}"}
          rows={@organisation.systems}
          row_click={
            fn system -> JS.navigate(~p"/organisations/#{@organisation.id}/systems/#{system.id}") end
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

        <p :if={Enum.empty?(@organisation.systems)} class="mt-4">
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
          title={dgettext("assets", "New System")}
          action={:new_system}
          organisation={@organisation}
          current_user={@current_user}
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
  def update(%{added_system: _asset}, socket) do
    socket
    |> assign(:show_modal, false)
    |> ok()
  end

  @impl true
  def update(assigns, socket) do
    socket
    |> assign(assigns)
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
