defmodule ThreatShieldWeb.SystemLive.FormComponent do
  use ThreatShieldWeb, :live_component

  alias ThreatShield.Systems
  alias ThreatShield.DynamicAttribute

  import ThreatShield.Systems.System, only: [attributes: 0]

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <.header>
        <%= @title %>
      </.header>

      <p class="help-text">
        <%= dgettext("systems", "System: long description") %>
      </p>

      <.simple_form
        for={@form}
        id="system-form"
        phx-target={@myself}
        phx-change="validate"
        phx-submit="save"
      >
        <.input field={@form[:name]} type="text" label="Name" />
        <.input field={@form[:description]} type="text" label="Description" />
        <%= for attribute <- @attributes do %>
          <.input
            name={attribute.name}
            value={Map.get(@attribute_map, attribute.name, "")}
            type="text"
            label={attribute.name}
          />
          <em>e.g. <%= DynamicAttribute.get_suggestions(attribute) |> Enum.join(", ") %></em>
        <% end %>
        <:actions>
          <.button_primary phx-disable-with="Saving...">Save System</.button_primary>
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
    attributes()
    |> Enum.map(fn d -> {d.name, Map.get(params, d.name, "")} end)
    |> Map.new()
  end

  defp save_system(socket, :edit_system, system_params) do
    user = socket.assigns.current_user

    case Systems.update_system(user, socket.assigns.system, system_params) do
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
