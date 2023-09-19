defmodule ThreatShieldWeb.MitigationLive.FormComponent do
  use ThreatShieldWeb, :live_component

  alias ThreatShield.Mitigations

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <.header>
        <%= @title %>
        <:subtitle>Use this form to manage mitigation records in your database.</:subtitle>
      </.header>

      <.simple_form
        for={@form}
        id="mitigation-form"
        phx-target={@myself}
        phx-change="validate"
        phx-submit="save"
      >
        <.input field={@form[:name]} type="text" label="Name" />
        <.input field={@form[:description]} type="text" label="Description" />
        <.input field={@form[:is_implemented]} type="checkbox" label="Is implemented" />
        <:actions>
          <.button phx-disable-with="Saving...">Save Mitigation</.button>
        </:actions>
      </.simple_form>
    </div>
    """
  end

  @impl true
  def update(%{mitigation: mitigation} = assigns, socket) do
    changeset = Mitigations.change_mitigation(mitigation)

    {:ok,
     socket
     |> assign(assigns)
     |> assign_form(changeset)}
  end

  @impl true
  def handle_event("validate", %{"mitigation" => mitigation_params}, socket) do
    changeset =
      socket.assigns.mitigation
      |> Mitigations.change_mitigation(mitigation_params)
      |> Map.put(:action, :validate)

    {:noreply, assign_form(socket, changeset)}
  end

  def handle_event("save", %{"mitigation" => mitigation_params}, socket) do
    save_mitigation(socket, socket.assigns.action, mitigation_params)
  end

  defp save_mitigation(socket, :edit_mitigation, mitigation_params) do
    user = socket.assigns.current_user

    case Mitigations.update_mitigation(user, socket.assigns.mitigation, mitigation_params) do
      {:ok, mitigation} ->
        notify_parent({:saved, mitigation})

        {:noreply,
         socket
         |> put_flash(:info, "Mitigation updated successfully")
         |> push_patch(to: socket.assigns.patch)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign_form(socket, changeset)}
    end
  end

  defp save_mitigation(socket, :new_mitigation, mitigation_params) do
    %{user: user, risk: risk} = socket.assigns

    case Mitigations.create_mitigation(user, risk, mitigation_params) do
      {:ok, mitigation} ->
        notify_parent({:saved, mitigation})

        {:noreply,
         socket
         |> put_flash(:info, "Mitigation created successfully")
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
