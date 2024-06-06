defmodule ThreatShieldWeb.ThreatLive.ThreatsList do
  use ThreatShieldWeb, :live_component

  alias ThreatShield.AI
  alias ThreatShield.Scope
  alias ThreatShield.AI.AiSuggestion

  alias ThreatShield.Threats
  alias ThreatShield.Threats.Threat
  alias ThreatShield.Assets.Asset
  alias ThreatShield.Accounts.Organisation
  alias ThreatShield.Systems.System

  import ThreatShieldWeb.Labels
  import ThreatShieldWeb.Helpers

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
          <:name>
            <span class="text-gray-800 inline-block">
              <Icons.threat_icon class="w-6 h-6" />
            </span>
            <%= dgettext("threats", "Threats") %>
          </:name>

          <:subtitle>
            <%= dgettext("threats", "Threat: short description") %>
          </:subtitle>

          <:buttons>
            <.link
              :if={ThreatShield.Members.Rights.may(:create_threat, @scope.membership)}
              phx-click="open-create-dialog"
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
                  "threats",
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
          row_click={fn threat -> JS.navigate(link_to(threat)) end}
        >
          <:col :let={threat}>
            <%= threat.name %>
          </:col>
          <:col :let={threat}>
            <%= system_label(threat) %>
          </:col>
          <:col :let={threat}>
            <%= asset_label(threat) %>
          </:col>
          <:col :let={threat}><%= threat.description %></:col>
        </.stacked_list>

        <p :if={Enum.empty?(@threats)} class="mt-4">
          There are no threats. Please add them manually or let the AI assistant make some suggestions.
        </p>
      </div>

      <.modal
        :if={assigns[:show_create_dialog] == true}
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
          scope={@scope}
          system_options={systems_of_organisaton(@scope.organisation)}
          asset_options={assets_of_organisaton(@scope.organisation)}
          threat={prepare_threat(@scope)}
          origin={@origin}
        />
      </.modal>
      <.modal
        :if={assigns[:show_suggest_dialog] == true}
        id="suggest-threats-modal"
        show
        on_cancel={JS.navigate(@origin)}
      >
        <.suggestions_dialog
          title={dgettext("threats", "Suggested Threats")}
          listener={@myself}
          scope={@scope}
          suggestions={@ai_suggestions[:threats]}
        />
      </.modal>
    </div>
    """
  end

  # events

  @impl true
  def update(%{added_threat: threat}, socket) do
    old_threats = socket.assigns[:threats] || []

    # reload to resolve associations
    threat = Threats.get_threat!(socket.assigns.scope.user, threat.id)

    socket
    |> assign(:show_create_dialog, false)
    |> assign(:threats, old_threats ++ [threat])
    |> ok()
  end

  @impl true
  def update(assigns, socket) do
    socket
    |> assign(assigns)
    |> load_and_filter_threats(assigns)
    |> ok()
  end

  @impl true
  def handle_event("open-create-dialog", _params, socket) do
    socket
    |> assign(:show_create_dialog, true)
    |> noreply()
  end

  @doc """
  Will start a background task to suggest threats for the current scope
  When the task is finished, it will send a :new_ai_suggestion message to the current page.
  The page is expected to add the suggestions to the :ai_suggesstions assigns.
  """
  @impl true
  def handle_event("suggest_threats", _params, socket) do
    scope = socket.assigns.scope

    AI.run_task(scope, fn ->
      new_threats =
        AI.suggest_threats(scope)

      {:new_ai_suggestion, %AiSuggestion{result: new_threats, type: :threats, requestor: self()}}
    end)
    |> case do
      {:ok, _} ->
        socket
        |> assign(:show_suggest_dialog, true)
        |> noreply()

      {:error, :quota_exceeded} ->
        socket
        |> put_flash(:error, dgettext("common", "Your quota for AI suggestions is exceeded."))
        |> push_navigate(to: socket.assigns.origin)
        |> noreply()
    end
  end

  @impl true
  def handle_event("apply_selection", %{"selected_suggestions" => selected_names}, socket) do
    scope = %Scope{} = socket.assigns.scope

    ai_suggestions = socket.assigns.ai_suggestions

    new_threats =
      ai_suggestions[:threats]
      |> Enum.filter(fn s -> Enum.member?(selected_names, s.name) end)
      |> Enum.map(fn s -> create_threat(scope, s) end)

    socket
    |> assign(:show_suggest_dialog, false)
    |> assign(:threats, socket.assigns.threats ++ new_threats)
    |> noreply()
  end

  @impl true
  def handle_event("apply_selection", _params, socket) do
    socket
    |> put_flash(:error, dgettext("common", "No suggestions selected."))
    |> assign(:show_suggest_dialog, false)
    |> noreply()
  end

  # internal

  defp load_and_filter_threats(socket, %{threats: threats}) when is_list(threats) do
    Logger.debug("Threats already provided by caller")
    socket
  end

  defp load_and_filter_threats(socket, _assigns) do
    # Todo: Implement loading and filtering of threats
    socket
  end

  defp systems_of_organisaton(%Organisation{} = organisation) do
    Organisation.list_system_options(organisation)
  end

  defp assets_of_organisaton(%Organisation{} = organisation) do
    Organisation.list_asset_options(organisation)
  end

  defp prepare_threat(%{asset: %Asset{} = asset, system: %System{} = system}) do
    %Threat{asset: asset, asset_id: asset.id, system: system, system_id: system.id}
  end

  defp prepare_threat(%{asset: %Asset{} = asset}) do
    %Threat{asset: asset, asset_id: asset.id}
  end

  defp prepare_threat(%{system: %System{} = system}) do
    %Threat{system: system, system_id: system.id}
  end

  defp prepare_threat(_other), do: %Threat{}

  defp create_threat(scope, %{name: name, description: desc}) do
    {:ok, threat} = Threats.add_threat_with_name_and_description(scope, name, desc)
    threat
  end
end
