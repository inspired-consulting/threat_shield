defmodule ThreatShieldWeb.AssetLive.AssetForm do
  use ThreatShieldWeb, :live_component

  import ThreatShieldWeb.FormHelpers

  alias ThreatShield.Scope
  alias ThreatShield.Assets

  import ThreatShieldWeb.TsComponents

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <.header>
        <%= @title %>
      </.header>
      <p>
        <%= dgettext(
          "assets",
          "Asset: long description"
        ) %>
      </p>

      <.simple_form
        for={@form}
        id="asset-form"
        phx-target={@myself}
        phx-change="validate"
        phx-submit="save"
      >
        <.input field={@form[:name]} type="text" label="Name" required />
        <.input field={@form[:description]} type="textarea" label="Description" required />
        <.input
          :if={assigns[:system_options]}
          field={@form[:system_id]}
          type="select"
          label="System"
          options={@system_options}
        />
        <hr />
        <div class="lg:grid grid-flow-col justify-stretch space-x-4">
          <.criticality_picker
            field={@form[:criticality_loss]}
            label={dgettext("assets", "Criticality of loss")}
          />
          <.criticality_picker
            field={@form[:criticality_theft]}
            label={dgettext("assets", "Criticality of theft")}
          />
          <.criticality_picker
            field={@form[:criticality_publication]}
            label={dgettext("assets", "Criticality of publication")}
          />
        </div>
        <div class="py-5">
          <.criticality_picker
            field={@form[:criticality_overall]}
            label={dgettext("assets", "Criticality overall")}
          />
        </div>
        <:actions>
          <.button_primary phx-disable-with="Saving...">Save Asset</.button_primary>
        </:actions>
      </.simple_form>
    </div>
    """
  end

  @impl true
  def update(%{asset: asset} = assigns, socket) do
    changeset = Assets.change_asset(asset)

    socket
    |> assign(assigns)
    |> assign_form(changeset)
    |> ok()
  end

  @impl true
  def handle_event("validate", %{"asset" => asset_params}, socket) do
    changeset =
      socket.assigns.asset
      |> Assets.change_asset(asset_params)
      |> Map.put(:action, :validate)

    {:noreply, assign_form(socket, changeset)}
  end

  def handle_event("save", %{"asset" => asset_params}, socket) do
    save_asset(socket, socket.assigns.action, asset_params)
  end

  defp save_asset(socket, :edit, asset_params) do
    scope = %Scope{} = socket.assigns.scope

    result = Assets.update_asset(scope.user, socket.assigns.asset, asset_params)

    socket
    |> handle_save_result(result, __MODULE__, "Asset updated successfully")
    |> noreply()
  end

  defp save_asset(socket, :new_asset, asset_params) do
    scope = %Scope{} = socket.assigns.scope

    result = Assets.create_asset(scope.user, scope.organisation, asset_params)
    socket = handle_save_result(socket, result, __MODULE__, "Asset created successfully")

    with {:ok, asset} <- result do
      notify_asset_list(id: socket.assigns.parent_id, added_asset: asset)
    end

    noreply(socket)
  end

  defp notify_asset_list(msg),
    do: send_update(self(), ThreatShieldWeb.AssetLive.AssetsList, msg)
end
