defmodule ThreatShieldWeb.MembersLive.RoleForm do
  alias ThreatShield.Accounts.Membership
  use ThreatShieldWeb, :live_component

  alias ThreatShield.Members

  @impl true
  def render(assigns) do
    ~H"""
    <div class="md:w-[800px]">
      <.header>
        <%= dgettext("organisation", "Edit role for") %> <%= @membership.user.email %>
      </.header>

      <.simple_form
        for={@form}
        id={"role-form-for-user-#{@membership.user.id}"}
        phx-target={@myself}
        phx-change="validate"
        phx-submit="save"
      >
        <.input
          field={@form[:role]}
          type="select"
          label="Role"
          options={
            Ecto.Enum.mappings(Membership, :role)
            |> Enum.map(fn {_, v} ->
              {Gettext.dgettext(ThreatShieldWeb.Gettext, "organisation", v), v}
            end)
          }
        />
        <:actions>
          <div class="w-full text-end">
            <.button_primary phx-disable-with="Saving...">
              <%= dgettext("organisation", "Save Membership") %>
            </.button_primary>
          </div>
        </:actions>
      </.simple_form>
    </div>
    """
  end

  @impl true
  def update(%{membership: membership} = assigns, socket) do
    changeset = Members.change_membership(membership)

    {:ok,
     socket
     |> assign(assigns)
     |> assign_form(changeset)}
  end

  @impl true
  def handle_event("validate", %{"membership" => membership_params}, socket) do
    changeset =
      socket.assigns.membership
      |> Members.change_membership(membership_params)
      |> Map.put(:action, :validate)

    {:noreply, assign_form(socket, changeset)}
  end

  def handle_event("save", %{"membership" => membership_params}, socket) do
    membership = socket.assigns.membership
    user = socket.assigns.current_user

    {role, _} =
      Ecto.Enum.mappings(Membership, :role)
      |> Enum.find(fn {_, v} -> v == Map.get(membership_params, "role") end)

    case Members.update_role(user, membership, role) do
      {:ok, membership} ->
        notify_parent({:saved, membership})

        socket
        |> put_flash(:info, "Role updated successfully")
        |> push_patch(to: socket.assigns.patch)
        |> noreply()

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign_form(socket, changeset)}
    end
  end

  defp assign_form(socket, %Ecto.Changeset{} = changeset) do
    assign(socket, :form, to_form(changeset))
  end

  defp notify_parent(msg), do: send(self(), {__MODULE__, msg})
end
