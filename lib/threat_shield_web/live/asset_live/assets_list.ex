defmodule ThreatShieldWeb.AssetLive.AssetsList do
  alias ElixirSense.Plugins.Phoenix.Scope
  use ThreatShieldWeb, :live_component

  alias ThreatShield.AI
  alias ThreatShield.Scope
  alias ThreatShield.AI.AiSuggestion
  alias ThreatShield.Assets

  alias ThreatShield.Organisations.Organisation
  alias ThreatShield.Systems.System

  require Logger

  attr :ai_suggestions, :map, default: %{}
  attr :scope, :any

  @impl true
  def render(assigns) do
    ~H"""
    <div class="assets" id="assets">
      <div class="mt-4 px-8 py-6 bg-white rounded-lg shadow">
        <.stacked_list_header>
          <:name><%= dgettext("assets", "Assets") %></:name>

          <:subtitle>
            <%= dgettext(
              "assets",
              "Asset: short description"
            ) %>
          </:subtitle>

          <:buttons>
            <.link
              :if={ThreatShield.Members.Rights.may(:create_asset, @scope.membership)}
              phx-click="open-create-dialog"
              phx-target={@myself}
            >
              <.button_primary>
                <.icon name="hero-cursor-arrow-ripple" class="mr-1 mb-1" /><%= dgettext(
                  "assets",
                  "New Asset"
                ) %>
              </.button_primary>
            </.link>
            <.link>
              <.button_magic
                :if={ThreatShield.Members.Rights.may(:create_asset, @scope.membership)}
                phx-click="suggest_assets"
                phx-target={@myself}
              >
                <.icon name="hero-sparkles" class="mr-1 mb-1" /><%= dgettext(
                  "assets",
                  "Suggest Assets"
                ) %>
              </.button_magic>
            </.link>
          </:buttons>
        </.stacked_list_header>
        <.stacked_list
          :if={not Enum.empty?(@assets)}
          id={"assets_for_org_#{@scope.organisation.id}"}
          rows={@assets}
          row_click={fn asset -> JS.navigate(@origin <> "/assets/#{asset.id}") end}
        >
          <:col :let={asset}>
            <%= asset.name %>
          </:col>
          <:col :let={asset}><%= asset.description %></:col>
          <:col :let={asset}>
            <.criticality_badge
              value={asset.criticality_overall}
              title={dgettext("assets", "Criticality overall")}
            />
          </:col>
          <:col :let={asset}>
            <.criticality_badge
              value={asset.criticality_loss}
              title={dgettext("assets", "Criticality of loss")}
              size_classes="w-8 h-8 leading-7"
            />
          </:col>
          <:col :let={asset}>
            <.criticality_badge
              value={asset.criticality_theft}
              title={dgettext("assets", "Criticality of theft")}
              size_classes="w-8 h-8 leading-7"
            />
          </:col>
          <:col :let={asset}>
            <.criticality_badge
              value={asset.criticality_publication}
              title={dgettext("assets", "Criticality of publication")}
              size_classes="w-8 h-8 leading-7"
            />
          </:col>
        </.stacked_list>

        <p :if={Enum.empty?(@assets)} class="mt-4">
          There are no assets. Please add them manually.
        </p>
      </div>

      <.modal
        :if={assigns[:show_modal] == true}
        id="create-asset-modal"
        show
        on_cancel={JS.navigate(@origin)}
      >
        <.live_component
          module={ThreatShieldWeb.AssetLive.AssetForm}
          id={:new}
          parent_id={@id}
          title={dgettext("assets", "New Asset")}
          action={:new_asset}
          current_user={@scope.user}
          organisation={@scope.organisation}
          system_options={systems_of_organisaton(@scope.organisation)}
          asset={prepare_asset(assigns)}
          patch={@origin}
        />
      </.modal>
      <ThreatShieldWeb.AssetLive.AssetSuggestions.suggestions_dialog
        listener={@myself}
        scope={@scope}
        suggestions={@ai_suggestions[:assets]}
      />
    </div>
    """
  end

  # events

  @impl true
  def update(%{added_asset: _threat}, socket) do
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
  @spec handle_event(<<_::80, _::_*32>>, any(), atom() | map()) :: {:noreply, any()}
  def handle_event("open-create-dialog", _params, socket) do
    socket
    |> assign(:show_modal, true)
    |> noreply()
  end

  @doc """
  Will start a background task to suggest assets for the current scope.
  When the task is finished, it will send a :new_ai_suggestion message to the current page.
  The page is expected to add the suggestions to the :ai_suggesstions assigns.
  """
  @impl true
  def handle_event("suggest_assets", _params, socket) do
    scope = socket.assigns.scope

    Task.Supervisor.async_nolink(ThreatShield.TaskSupervisor, fn ->
      new_assets =
        AI.suggest_assets(scope)

      {:new_ai_suggestion, %AiSuggestion{result: new_assets, type: :assets, requestor: self()}}
    end)

    {:noreply, socket}
  end

  @impl true
  def handle_event("add_asset", %{"name" => name, "description" => description}, socket) do
    scope = %Scope{} = socket.assigns.scope

    ai_suggestions = socket.assigns.ai_suggestions

    {:ok, asset} =
      Assets.add_asset_with_name_and_description(scope, name, description)

    remaining_suggestions =
      Enum.filter(ai_suggestions[:assets], fn s -> s.description != description end)
      |> Enum.to_list()

    socket
    |> assign(:ai_suggestions, Map.put(ai_suggestions, :assets, remaining_suggestions))
    |> assign(:assets, socket.assigns.assets ++ [asset])
    |> noreply()
  end

  @impl true
  def handle_event("ignore_asset", %{"description" => description}, socket) do
    ai_suggestions = socket.assigns.ai_suggestions

    remaining_suggestions =
      Enum.filter(ai_suggestions[:assets], fn s -> s.description != description end)
      |> Enum.to_list()

    socket
    |> assign(:ai_suggestions, Map.put(ai_suggestions, :assets, remaining_suggestions))
    |> noreply()
  end

  # internal

  defp systems_of_organisaton(%Organisation{} = organisation) do
    Organisation.list_system_options(organisation)
  end

  defp prepare_asset(%{system: %System{} = system}) do
    Assets.prepare_asset(system.id)
  end

  defp prepare_asset(_other), do: Assets.prepare_asset()
end
