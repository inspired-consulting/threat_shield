defmodule ThreatShieldWeb.RiskLive.FormComponent do
  use ThreatShieldWeb, :live_component

  alias ThreatShield.Risks

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <.header>
        <%= @title %>
      </.header>

      <.simple_form
        for={@form}
        id="risk-form"
        phx-target={@myself}
        phx-change="validate"
        phx-submit="save"
      >
        <.input field={@form[:name]} type="text" label="Name" />
        <.input field={@form[:description]} type="text" label="Description" />
        <.input field={@form[:estimated_cost]} type="number" label="Estimated cost" />
        <.input field={@form[:probability]} type="number" label="Probability" step="any" />
        <:actions>
          <.button_primary phx-disable-with="Saving...">Save Risk</.button_primary>
        </:actions>
      </.simple_form>
    </div>
    """
  end

  @impl true
  def update(%{risk: risk} = assigns, socket) do
    changeset = Risks.change_risk(risk)

    {:ok,
     socket
     |> assign(assigns)
     |> assign_form(changeset)}
  end

  @impl true
  def handle_event("validate", %{"risk" => risk_params}, socket) do
    changeset =
      socket.assigns.risk
      |> Risks.change_risk(risk_params)
      |> Map.put(:action, :validate)

    {:noreply, assign_form(socket, changeset)}
  end

  def handle_event("save", %{"risk" => risk_params}, socket) do
    save_risk(socket, socket.assigns.action, risk_params)
  end

  defp save_risk(socket, :edit_risk, risk_params) do
    %{current_user: user, risk: risk} = socket.assigns

    case Risks.update_risk(user, risk, risk_params) do
      {:ok, risk} ->
        notify_parent({:saved, risk})

        {:noreply,
         socket
         |> put_flash(:info, "Risk updated successfully")
         |> push_patch(to: socket.assigns.patch)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign_form(socket, changeset)}
    end
  end

  defp save_risk(socket, :new_risk, risk_params) do
    %{current_user: user, threat: threat} = socket.assigns

    case Risks.create_risk(user, threat.id, risk_params) do
      {:ok, risk} ->
        notify_parent({:saved, risk})

        {:noreply,
         socket
         |> put_flash(:info, "Risk created successfully")
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
