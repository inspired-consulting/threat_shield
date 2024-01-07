defmodule ThreatShieldWeb.OrganisationLive.OrganisationForm do
  alias ThreatShield.DynamicAttribute
  use ThreatShieldWeb, :live_component
  import Phoenix.LiveView

  alias ThreatShield.Organisations
  import ThreatShield.Organisations.Organisation, only: [attributes: 0]

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <.header>
        <%= @title %>
      </.header>

      <.simple_form
        for={@form}
        id="organisation-form"
        phx-target={@myself}
        phx-change="validate"
        phx-submit="save"
      >
        <.input field={@form[:name]} type="text" label="Name" />
        <.input
          field={@form[:location]}
          type="select"
          label="Choose your location"
          options={@locations_options}
        />
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
          <.button_primary phx-disable-with="Saving...">Save Organisation</.button_primary>
        </:actions>
      </.simple_form>
    </div>
    """
  end

  @impl true
  def update(%{organisation: organisation} = assigns, socket) do
    changeset = Organisations.change_organisation(organisation)

    attribute_map =
      case organisation.attributes do
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
  def handle_event("validate", %{"organisation" => organisation_params}, socket) do
    changeset =
      socket.assigns.organisation
      |> Organisations.change_organisation(organisation_params)
      |> Map.put(:action, :validate)

    {:noreply, assign_form(socket, changeset)}
  end

  def handle_event("save", %{"organisation" => organisation_params} = params, socket) do
    attributes = extract_attributes_from_params(params)

    save_organisation(
      socket,
      socket.assigns.action,
      Map.put(organisation_params, "attributes", attributes)
    )
  end

  defp extract_attributes_from_params(params) do
    attributes()
    |> Enum.map(fn d -> {d.name, Map.get(params, d.name, "")} end)
    |> Map.new()
  end

  defp save_organisation(socket, :edit_organisation, organisation_params) do
    current_user = socket.assigns.current_user

    case Organisations.update_organisation(
           socket.assigns.organisation,
           current_user,
           organisation_params
         ) do
      {:ok, organisation} ->
        notify_parent({:saved, organisation})

        {:noreply,
         socket
         |> put_flash(:info, "Organisation updated successfully")
         |> push_patch(to: socket.assigns.patch)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign_form(socket, changeset)}
    end
  end

  defp save_organisation(socket, :new, organisation_params) do
    %{current_user: current_user} = socket.assigns

    case Organisations.create_organisation(organisation_params, current_user) do
      {:ok, organisation} ->
        notify_parent({:saved, organisation})

        {:noreply,
         socket
         |> put_flash(:info, "Organisation created successfully")
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
