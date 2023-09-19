defmodule ThreatShieldWeb.MembersLive.FormComponent do
  use ThreatShieldWeb, :live_component

  alias ThreatShield.Members

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <.header>
        <%= @title %>
      </.header>

      <.simple_form
        for={@form}
        id="invite-form"
        phx-target={@myself}
        phx-change="validate"
        phx-submit="save"
      >

        <.input field={@form[:email]} type="text" label="Email" />
        <:actions>
          <.button phx-disable-with="Saving..."><%= dgettext("organisation", "Send invite") %></.button>
        </:actions>
      </.simple_form>
    </div>
    """
  end

  @impl true
  def update(%{invite: invite} = assigns, socket) do
    changeset = Members.change_invite(invite)

    {:ok,
     socket
     |> assign(assigns)
     |> assign_form(changeset)}
  end

  @impl true
  def handle_event("validate", %{"invite" => invite_params}, socket) do
    changeset =
      socket.assigns.invite
      |> Members.change_invite(invite_params)
      |> Map.put(:action, :validate)

    {:noreply, assign_form(socket, changeset)}
  end

  def handle_event("save", %{"invite" => invite_params}, socket) do
    save_invite(socket, socket.assigns.action, invite_params)
  end

  defp save_invite(socket, :new_invite, invite_params) do
    organisation = socket.assigns.organisation
    user = socket.assigns.current_user

    case Members.create_invite(user, organisation, invite_params) do
      {:ok, invite} ->
        notify_parent({:saved, invite})

        {:noreply,
         socket
         |> put_flash(:info, "Invite created successfully")
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
