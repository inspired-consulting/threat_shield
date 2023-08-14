defmodule ThreatShieldWeb.AssetLive.FormComponent do
  use ThreatShieldWeb, :live_component

  alias ThreatShield.Assets

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <.header>
        <%= @title %>
        <:subtitle>Use this form to manage asset records in your database.</:subtitle>
      </.header>

      <.simple_form
        for={@form}
        id="asset-form"
        phx-target={@myself}
        phx-change="validate"
        phx-submit="save"
      >
        <.input field={@form[:description]} type="text" label="Description" />
        <.input field={@form[:status]} type="number" label="Status" />
        <:actions>
          <.button phx-disable-with="Saving...">Save Asset</.button>
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
      |> Assets.change_asset(asset_params)
      |> Map.put(:action, :validate)

    {:noreply, assign_form(socket, changeset)}
  end

  def handle_event("save", %{"asset" => asset_params}, socket) do
    save_asset(socket, socket.assigns.action, asset_params)
  end

  defp save_asset(socket, :edit, asset_params) do
    case Assets.update_asset(socket.assigns.asset, asset_params) do
      {:ok, asset} ->
        notify_parent({:saved, asset})

        {:noreply,
         socket
         |> put_flash(:info, "Asset updated successfully")
         |> push_patch(to: socket.assigns.patch)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign_form(socket, changeset)}
    end
  end

  defp save_asset(socket, :new, asset_params) do
    case Assets.create_asset(asset_params) do
      {:ok, asset} ->
        notify_parent({:saved, asset})

        {:noreply,
         socket
         |> put_flash(:info, "Asset created successfully")
         |> push_patch(to: socket.assigns.patch)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign_form(socket, changeset)}
    end
  end

  defp assign_form(socket, %Ecto.Changeset{} = changeset) do
    assign(socket, :form, to_form(changeset))
  end

  defp notify_parent(msg), do: send(self(), {__MODULE__, msg})
end
