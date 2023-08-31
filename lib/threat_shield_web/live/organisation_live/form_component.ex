defmodule ThreatShieldWeb.OrganisationLive.FormComponent do
  use ThreatShieldWeb, :live_component
  import Phoenix.LiveView

  alias ThreatShield.Organisations

  import ThreatShield.Organisations.Organisation, only: [attribute_keys: 0]

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
        <%= for attribute_key <- @attribute_keys do %>
          <.input
            name={attribute_key}
            value={Map.get(@attribute_map, attribute_key, "")}
            type="text"
            label={attribute_key}
          />
        <% end %>
        <:actions>
          <.button phx-disable-with="Saving...">Save Organisation</.button>
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
    attribute_keys()
    |> Enum.map(fn key -> {key, Map.get(params, key, "")} end)
    |> Map.new()
  end

  defp save_organisation(socket, :edit, organisation_params) do
    %{current_user: current_user} = socket.assigns

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
