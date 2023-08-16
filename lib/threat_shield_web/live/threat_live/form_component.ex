defmodule ThreatShieldWeb.ThreatLive.FormComponent do
  use ThreatShieldWeb, :live_component

  alias ThreatShield.Threats

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <.header>
        <%= @title %>
        <:subtitle>Use this form to manage threat records in your database.</:subtitle>
      </.header>

      <.simple_form
        for={@form}
        id="threat-form"
        phx-target={@myself}
        phx-change="validate"
        phx-submit="save"
      >
        <.input field={@form[:description]} type="text" label="Description" />
        <.input field={@form[:is_candidate]} type="checkbox" label="Is candidate" />
        <:actions>
          <.button phx-disable-with="Saving...">Save Threat</.button>
        </:actions>
      </.simple_form>
    </div>
    """
  end

  @impl true
  def update(%{threat: threat} = assigns, socket) do
    changeset = Threats.change_threat(threat)

    {:ok,
     socket
     |> assign(assigns)
     |> assign_form(changeset)}
  end

  @impl true
  def handle_event("validate", %{"threat" => threat_params}, socket) do
    changeset =
      socket.assigns.threat
      |> Threats.change_threat(threat_params)
      |> Map.put(:action, :validate)

    {:noreply, assign_form(socket, changeset)}
  end

  def handle_event("save", %{"threat" => threat_params}, socket) do
    save_threat(socket, socket.assigns.action, threat_params)
  end

  defp save_threat(socket, :edit, threat_params) do
    user = socket.assigns.current_user

    case Threats.update_threat(user, socket.assigns.threat, threat_params) do
      {:ok, threat} ->
        notify_parent({:saved, threat})

        {:noreply,
         socket
         |> put_flash(:info, "Threat updated successfully")
         |> push_patch(to: socket.assigns.patch)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign_form(socket, changeset)}
    end
  end

  defp save_threat(socket, :new, threat_params) do
    %{current_user: user, organisation: organisation} = socket.assigns

    case Threats.create_threat(user, organisation, threat_params) do
      {:ok, threat} ->
        notify_parent({:saved, threat})

        {:noreply,
         socket
         |> put_flash(:info, "Threat created successfully")
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
