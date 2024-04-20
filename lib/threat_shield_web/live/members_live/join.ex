defmodule ThreatShieldWeb.MembersLive.Join do
  use ThreatShieldWeb, :live_view

  alias ThreatShield.Members
  alias ThreatShield.Accounts.User

  @impl true
  def mount(
        %{"token" => token},
        _session,
        %{assigns: %{current_user: %User{} = current_user}} = socket
      ) do
    {:ok, _} = ExRated.check_rate(current_user.email <> "_join_org", 10_000, 10)

    socket
    |> assign(invite: Members.get_invite_by_token(token))
    |> ok()
  end

  def mount(
        %{"token" => token},
        _session,
        socket
      ) do
    # User not logged in, must sign up first
    socket
    |> put_flash(:info, dgettext("accounts", "Please sign up to join this organisation."))
    |> push_navigate(to: ~p"/users/register?token=#{token}")
    |> ok()
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :join, _params) do
    socket
    |> assign(:page_title, "Join organisation")
  end

  @impl true
  def handle_event("join", %{"token" => token}, socket) do
    user = socket.assigns.current_user

    {:ok, _} = ExRated.check_rate(socket.assigns.current_user.email <> "_join_org", 10_000, 10)

    case Members.join_with_token(user, token) do
      {:ok, membership} ->
        push_navigate(socket,
          to: ~p"/organisations/" <> Integer.to_string(membership.organisation_id)
        )
        |> noreply()

      {:error, :already_member} ->
        socket
        |> put_flash(:info, dgettext("accounts", "You are already a member of this organisation"))
        |> push_navigate(to: ~p"/organisations")
        |> noreply()

      {:error, :invalid_token} ->
        socket
        |> put_flash(:error, dgettext("accounts", "This token is not valid (anymore)."))
        |> push_navigate(to: "/", clear_flash: true)
        |> noreply()
    end
  end
end
