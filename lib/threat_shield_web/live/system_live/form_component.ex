defmodule ThreatShieldWeb.SystemLive.FormComponent do
  use ThreatShieldWeb, :live_component

  alias ThreatShield.Systems

  @attribute_keys ["Database", "Application Framework", "Authentication Framework"]

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
        <%= for attribute_key <- @attribute_keys do %>
          <.input
            name={attribute_key}
            value={Map.get(@attribute_map, attribute_key, "")}
            type="text"
            label={attribute_key}
          />
          <%!-- <%= for {attribute, idx} <- Enum.with_index(@attributes) do %>
          <%= text_input(:attributes, "attribute_#{idx}", value: attribute, class: "form-input") %>
        <% end %> --%>
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
      Systems.change_system(system) |> IO.inspect(label: "#{__ENV__.file}:#{__ENV__.line}")

    attribute_map =
      case system.attributes do
        nil -> Map.new()
        map -> map
      end

    {:ok,
     socket
     |> assign(assigns)
     |> assign_form(changeset)
     |> assign(:attribute_map, attribute_map)
     |> IO.inspect(label: "#{__ENV__.file}:#{__ENV__.line}")}
  end

  @impl true
  def handle_event("validate", %{"system" => system_params} = params, socket) do
    params |> IO.inspect(label: "#{__ENV__.file}:#{__ENV__.line}")

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
    @attribute_keys
    |> Enum.map(fn key -> {key, Map.get(params, key, "")} end)
    |> Map.new()
  end

  defp save_system(socket, :edit, system_params) do
    user = socket.assigns.current_user
    organisation = socket.assigns.organisation

    socket |> IO.inspect(label: "#{__ENV__.file}:#{__ENV__.line}")
    system_params |> IO.inspect(label: "#{__ENV__.file}:#{__ENV__.line}")

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
