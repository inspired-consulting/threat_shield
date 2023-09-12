defmodule ThreatShieldWeb.SystemLive.FormComponent do
  use ThreatShieldWeb, :live_component

  alias ThreatShield.Systems

  import ThreatShield.Systems.System, only: [attribute_keys: 0]

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <.header>
        <%= @title %>
        <:subtitle>Please fill out this form as detailed as possible:</:subtitle>
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
        <%= for attribute_key <- attribute_keys() do %>
          <.input
            name={attribute_key}
            value={Map.get(@attribute_map, attribute_key, "")}
            type="text"
            label={attribute_key}
          />
        <% end %>
        <:actions>
          <.button phx-disable-with="Saving...">Save System</.button>
        </:actions>
      </.simple_form>
    </div>
    """
  end

  @impl true
  def update(%{system: system} = assigns, socket) do
    changeset =
      Systems.change_system(system)

    attribute_map =
      case system.attributes do
        nil -> Map.new()
        map -> map
      end

    {:ok,
     socket
     |> assign(assigns)
     |> assign_form(changeset)
     |> assign(:attribute_map, attribute_map)}
  end

  @impl true
  def handle_event("validate", %{"system" => system_params}, socket) do
    changeset =
      socket.assigns.system
      |> Systems.change_system(system_params)
      |> Map.put(:action, :validate)

    {:noreply, assign_form(socket, changeset)}
  end

  def handle_event("save", %{"system" => system_params} = params, socket) do
    attributes = extract_attributes_from_params(params)

    save_system(socket, socket.assigns.action, Map.put(system_params, "attributes", attributes))
  end

  defp extract_attributes_from_params(params) do
    attribute_keys()
    |> Enum.map(fn key -> {key, Map.get(params, key, "")} end)
    |> Map.new()
  end

  defp save_system(socket, :edit_system, system_params) do
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

  defp save_system(socket, :new_system, system_params) do
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
