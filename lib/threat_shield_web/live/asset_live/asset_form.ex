defmodule ThreatShieldWeb.AssetLive.AssetForm do
  use ThreatShieldWeb, :live_component

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
        <.input field={@form[:name]} type="text" label="Name" />
        <.input field={@form[:description]} type="text" label="Description" />
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

    {:ok,
     socket
     |> assign(assigns)
     |> assign_form(changeset)}
  end

  @impl true
  def handle_event("validate", %{"asset" => asset_params}, socket) do
    changeset =
      socket.assigns.asset
      |> update_with_fixed_system(socket)
      |> Assets.change_asset(asset_params)
      |> Map.put(:action, :validate)

    {:noreply, assign_form(socket, changeset)}
  end

  def handle_event("save", %{"asset" => asset_params}, socket) do
    save_asset(socket, socket.assigns.action, asset_params)
  end

  defp save_asset(socket, :edit, asset_params) do
    user = socket.assigns.current_user

    case Assets.update_asset(
           user,
           socket.assigns.asset,
           asset_params |> update_with_fixed_system(socket)
         ) do
      {:ok, asset} ->
        notify_parent({:saved, asset})

        socket
        |> put_flash(:info, "Asset updated successfully")
        |> push_patch(to: socket.assigns.patch)
        |> noreply()

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign_form(socket, changeset)}
    end
  end

  defp save_asset(socket, :new_asset, asset_params) do
    user = socket.assigns.current_user
    organisation = socket.assigns.organisation

    case Assets.create_asset(user, organisation, asset_params |> update_with_fixed_system(socket)) do
      {:ok, asset} ->
        notify_parent({:saved, asset})
        notify_asset_list(id: socket.assigns.parent_id, added_asset: asset)

        socket
        |> put_flash(:info, "Asset created successfully")
        |> push_patch(to: socket.assigns.patch)
        |> noreply()

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign_form(socket, changeset)}
    end
  end

  defp update_with_fixed_system(asset_params, socket) do
    case socket.assigns[:fixed_system] do
      nil -> asset_params
      sys -> asset_params |> Map.put("system_id", sys.id)
    end
  end

  defp assign_form(socket, %Ecto.Changeset{} = changeset) do
    assign(socket, :form, to_form(changeset))
  end

  defp notify_parent(msg), do: send(self(), {__MODULE__, msg})

  defp notify_asset_list(msg),
    do: send_update(self(), ThreatShieldWeb.AssetLive.AssetsList, msg)
end
