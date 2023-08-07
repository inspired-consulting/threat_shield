defmodule ThreatShieldWeb.OrganisationLive.FormComponent do
  use ThreatShieldWeb, :live_component

  alias ThreatShield.Organsations

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <.header>
        <%= @title %>
        <:subtitle>Use this form to manage organisation records in your database.</:subtitle>
      </.header>

      <.simple_form
        for={@form}
        id="organisation-form"
        phx-target={@myself}
        phx-change="validate"
        phx-submit="save"
      >
        <.input field={@form[:name]} type="text" label="Name" />
        <:actions>
          <.button phx-disable-with="Saving...">Save Organisation</.button>
        </:actions>
      </.simple_form>
    </div>
    """
  end

  @impl true
  def update(%{organisation: organisation} = assigns, socket) do
    changeset = Organsations.change_organisation(organisation)

    {:ok,
     socket
     |> assign(assigns)
     |> assign_form(changeset)}
  end

  @impl true
  def handle_event("validate", %{"organisation" => organisation_params}, socket) do
    changeset =
      socket.assigns.organisation
      |> Organsations.change_organisation(organisation_params)
      |> Map.put(:action, :validate)

    {:noreply, assign_form(socket, changeset)}
  end

  def handle_event("save", %{"organisation" => organisation_params}, socket) do
    save_organisation(socket, socket.assigns.action, organisation_params)
  end

  defp save_organisation(socket, :edit, organisation_params) do
    %{current_user: current_user} = socket.assigns

    case Organsations.update_organisation(
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

    case Organsations.create_organisation(organisation_params, current_user) do
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
