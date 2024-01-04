defmodule ThreatShieldWeb.ThreatLive.ThreatsList do
  use ThreatShieldWeb, :live_component

  alias ThreatShield.AI
  alias ThreatShield.AI.AiSuggestion

  alias ThreatShield.Organisations.Organisation
  alias ThreatShield.Systems.System
  alias ThreatShield.Threats.Threat

  import ThreatShieldWeb.Labels, only: [system_label: 1]

  require Logger

  @moduledoc """
  This component renders a list of threats for a given system or for the organization.
  It also provides a button to create a new threat in a modal dialog.
  This component is designed to be used in different contexts,
  e.g. to list and add threats for organisations, systems, and assets.
  """

  @impl true
  def render(%{id: _component_id} = assigns) do
    ~H"""
    <div class="threats">
      <div class="mt-4 px-8 py-6 bg-white rounded-lg shadow">
        <.stacked_list_header>
          <:name><%= dgettext("threats", "Threats") %></:name>

          <:subtitle>
            <%= dgettext("threats", "Threat: short description") %>
          </:subtitle>

          <:buttons>
            <.link
              :if={ThreatShield.Members.Rights.may(:create_threat, @scope.membership)}
              phx-click="open-modal"
              phx-target={@myself}
            >
              <.button_primary>
                <.icon name="hero-cursor-arrow-ripple" class="mr-1 mb-1" /><%= dgettext(
                  "threats",
                  "New Threat"
                ) %>
              </.button_primary>
            </.link>
            <.link>
              <.button_magic
                :if={ThreatShield.Members.Rights.may(:create_threat, @scope.membership)}
                phx-click="suggest_threats"
                phx-target={@myself}
              >
                <.icon name="hero-sparkles" class="mr-1 mb-1" /><%= dgettext(
                  "assets",
                  "Suggest Threats"
                ) %>
              </.button_magic>
            </.link>
          </:buttons>
        </.stacked_list_header>
        <.stacked_list
          :if={not Enum.empty?(@threats)}
          id={"threats_for_#{@scope.id}"}
          rows={@threats}
          row_click={fn threat -> JS.navigate(@origin <> "/threats/#{threat.id}") end}
        >
          <:col :let={threat}>
            <%= threat.name %>
          </:col>
          <:col :let={threat}>
            <%= system_label(threat) %>
          </:col>
          <:col :let={threat}><%= threat.description %></:col>
        </.stacked_list>

        <p :if={Enum.empty?(@threats)} class="mt-4">
          There are no threats. Please add them manually or let the AI assistant make some suggestions.
        </p>
      </div>

      <.modal
        :if={assigns[:show_modal] == true}
        id="create-threat-modal"
        show
        on_cancel={JS.navigate(@origin)}
      >
        <.live_component
          module={ThreatShieldWeb.ThreatLive.ThreatForm}
          id={:new}
          parent_id={@id}
          action={:new_threat}
          title={dgettext("threats", "New Threat")}
          current_user={@scope.user}
          organisation={@scope.organisation}
          system_options={systems_of_organisaton(@scope.organisation)}
          threat={prepare_threat(assigns)}
          patch={@origin}
        />
      </.modal>
      <ThreatShieldWeb.Suggestions.suggestions
        suggestions={fetch_suggestions(@ai_suggestions)}
        entity_name="threat"
      />
    </div>
    """
  end

  # lifecycle

  @impl true
  def update(%{added_threat: _asset}, socket) do
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

  # events

  @impl true
  def handle_event("open-modal", _params, socket) do
    socket
    |> assign(:show_modal, true)
    |> noreply()
  end

  @impl true
  def handle_event("suggest_threats", _params, socket) do
    scope = socket.assigns.scope

    Task.Supervisor.async_nolink(ThreatShield.TaskSupervisor, fn ->
      new_threats =
        AI.suggest_threats(scope)

      {:ai_suggestion, %AiSuggestion{result: new_threats, type: :threats, requestor: self()}}
    end)

    {:noreply, socket}
  end

  # internal

  defp systems_of_organisaton(%Organisation{} = organisation) do
    Organisation.list_system_options(organisation)
  end

  defp prepare_threat(%{system: %System{} = system}) do
    %Threat{system: system, system_id: system.id}
  end

  defp prepare_threat(_other), do: %Threat{}

  defp fetch_suggestions(suggestions) do
    if is_nil(suggestions) do
      []
    else
      suggestions[:threats] || []
    end
  end
end
