defmodule ThreatShieldWeb.AssetLive.AssetsList do
  use ThreatShieldWeb, :live_component

  alias ThreatShield.Assets

  alias ThreatShield.Organisations.Organisation
  alias ThreatShield.Systems.System

  require Logger

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
              :if={ThreatShield.Members.Rights.may(:create_asset, @membership)}
              phx-click="open-modal"
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
                :if={ThreatShield.Members.Rights.may(:create_asset, @membership)}
                disabled={not is_nil(@asking_ai_for_assets)}
                phx-click="suggest_assets"
                phx-value-org_id={@organisation.id}
                phx-value-sys_id={if is_nil(assigns[:system]), do: nil, else: @system.id}
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
          id={"assets_for_org_#{@organisation.id}"}
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
          current_user={@current_user}
          organisation={@organisation}
          system_options={systems_of_organisaton(@organisation)}
          asset={prepare_asset(assigns)}
          patch={@origin}
        />
      </.modal>
    </div>
    """
  end

  # events

  @impl true
  def handle_event("open-modal", _params, socket) do
    socket
    |> assign(:show_modal, true)
    |> noreply()
  end

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

  # internal

  defp systems_of_organisaton(%Organisation{} = organisation) do
    Organisation.list_system_options(organisation)
  end

  defp prepare_asset(%{system: %System{} = system}) do
    Assets.prepare_asset(system.id)
  end

  defp prepare_asset(_other), do: Assets.prepare_asset()
end
