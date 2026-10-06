defmodule ThreatShieldWeb.MembersLive.InviteForm do
  use ThreatShieldWeb, :live_component

  import ThreatShieldWeb.FormHelpers

  alias ThreatShield.Members

  @impl true
  def render(assigns) do
    ~H"""
    <div class="md:w-[800px]">
      <.header>
        <%= @title %>
      </.header>
      <.h3>
        <span class="text-gray-700 inline-block">
          <Icons.organisation_icon class="w-5 h-5" />
        </span>
        <%= @organisation.name %>
      </.h3>

      <.simple_form
        for={@form}
        id="invite-form"
        phx-target={@myself}
        phx-change="validate"
        phx-submit="save"
      >
        <.input field={@form[:email]} type="text" label="Email" />
        <:actions>
          <div class="w-full text-end">
            <.button_primary phx-disable-with="Saving...">
              <.icon name="hero-envelope" class="h-5 w-5 me-2" />
              <%= dgettext("organisation", "Send invite") %>
            </.button_primary>
          </div>
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

    result = Members.create_invite(user, organisation, invite_params)

    socket
    |> handle_save_result(result, __MODULE__, "Invite created successfully")
    |> noreply()
  end
end
