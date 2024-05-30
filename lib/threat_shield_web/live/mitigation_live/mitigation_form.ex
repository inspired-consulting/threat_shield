defmodule ThreatShieldWeb.MitigationLive.MitigationForm do
  use ThreatShieldWeb, :live_component

  alias ThreatShield.Mitigations
  alias ThreatShieldWeb.Labels

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <.header>
        <%= @title %>
        <:subtitle>
          <%= dgettext(
            "mitigations",
            "Mitigations: short description"
          ) %>
        </:subtitle>
      </.header>

      <.simple_form
        for={@form}
        id="mitigation-form"
        phx-target={@myself}
        phx-change="validate"
        phx-submit="save"
      >
        <.input field={@form[:name]} type="text" label={dgettext("mitigations", "Name")} />
        <.input
          field={@form[:description]}
          type="text"
          label={dgettext("mitigations", "Description")}
        />
        <.input field={@form[:issue_link]} type="text" label={dgettext("mitigations", "Issue link")} />
        <.input
          field={@form[:status]}
          type="select"
          label={dgettext("mitigations", "Status")}
          options={status_options()}
        />
        <.input
          field={@form[:implementation_notes]}
          type="text"
          label={dgettext("mitigations", "Implementation notes")}
        />
        <.input
          field={@form[:implementation_date]}
          type="date"
          label={dgettext("mitigations", "Implementation date")}
        />

        <hr />
        <.input
          field={@form[:verification_method]}
          type="text"
          label={dgettext("mitigations", "Verification method")}
        />
        <.input
          field={@form[:verification_result]}
          type="text"
          label={dgettext("mitigations", "Verification result")}
        />
        <.input
          field={@form[:verification_date]}
          type="date"
          label={dgettext("mitigations", "Verification date")}
        />

        <:actions>
          <.button_primary phx-disable-with="Saving...">Save Mitigation</.button_primary>
        </:actions>
      </.simple_form>
    </div>
    """
  end

  @impl true
  def update(%{mitigation: mitigation} = assigns, socket) do
    changeset = Mitigations.change_mitigation(mitigation)

    socket
    |> assign(assigns)
    |> assign_form(changeset)
    |> ok()
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

  def status_options() do
    Labels.available_mitigation_states()
    |> Enum.map(fn {key, label} -> {label, key} end)
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
