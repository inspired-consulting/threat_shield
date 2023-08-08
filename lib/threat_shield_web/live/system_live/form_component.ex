defmodule ThreatShieldWeb.SystemLive.FormComponent do
  use ThreatShieldWeb, :live_component

  alias ThreatShield.Systems

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <.header>
        <%= @title %>
        <:subtitle>Use this form to manage system records in your database.</:subtitle>
      </.header>

      <.simple_form
        for={@form}
        id="system-form"
        phx-target={@myself}
        phx-change="validate"
        phx-submit="save"
      >
        <.input field={@form[:name]} type="text" label="Name" />
        <.input field={@form[:description]} type="text" label="Description" />
        <.input field={@form[:attributes]} type="text" label="Attributes" />
        <:actions>
          <.button phx-disable-with="Saving...">Save System</.button>
        </:actions>
      </.simple_form>
    </div>
    """
  end

  @impl true
  def update(%{system: system} = assigns, socket) do
    changeset = Systems.change_system(system)

    {:ok,
     socket
     |> assign(assigns)
     |> assign_form(changeset)}
  end

  @impl true
  def handle_event("validate", %{"system" => system_params}, socket) do
    changeset =
      socket.assigns.system
      |> Systems.change_system(system_params)
      |> Map.put(:action, :validate)

    {:noreply, assign_form(socket, changeset)}
  end

  def handle_event("save", %{"system" => system_params}, socket) do
    save_system(socket, socket.assigns.action, system_params)
  end

  defp save_system(socket, :edit, system_params) do
    user = socket.assigns.current_user
    organisation = socket.assigns.organisation

    case Systems.update_system(user, organisation, socket.assigns.system, system_params) do
      {:ok, system} ->
        notify_parent({:saved, system})

        {:noreply,
         socket
         |> put_flash(:info, "System updated successfully")
         |> push_patch(to: socket.assigns.patch)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign_form(socket, changeset)}
    end
  end

  defp save_system(socket, :new, system_params) do
    user = socket.assigns.current_user
    organisation = socket.assigns.organisation

    case Systems.create_system(user, organisation, system_params) do
      {:ok, system} ->
        notify_parent({:saved, system})

        {:noreply,
         socket
         |> put_flash(:info, "System created successfully")
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
