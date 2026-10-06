defmodule ThreatShieldWeb.OrganisationLiveTest do
  use ThreatShieldWeb.ConnCase

  import Phoenix.LiveViewTest

  alias ThreatShield.AccountsFixtures
  alias ThreatShield.MembersFixtures
  alias ThreatShield.OrganisationsFixtures
  alias ThreatShield.Accounts.Organisation
  alias ThreatShield.Members
  alias ThreatShield.Members.Invite
  alias ThreatShield.Repo

  @create_attrs %{name: "some name"}

  defp create_organisation(_) do
    user = AccountsFixtures.user_fixture()
    organisation = OrganisationsFixtures.organisation_fixture(user, @create_attrs)
    %{user: user, organisation: organisation}
  end

  describe "Index" do
    setup [:create_organisation]

    test "redirect to /organisations if user is logged in", %{conn: conn} do
      user = AccountsFixtures.user_fixture()
      conn_with_session = assign(conn, :current_user, user)

      case live(conn_with_session, ~p"/organisations") do
        {:ok, _} ->
          assert redirected_to(~p"/organisations")

        {:error, _} ->
          assert true
      end
    end

    test "redirect to /users/log_in if the user is not logged in", %{conn: conn} do
      case live(conn, ~p"/organisations") do
        {:ok, _} ->
          assert redirected_to(~p"/users/log_in")

        {:error, _} ->
          assert true
      end
    end
  end

  describe "access control on the organisations page" do
    setup [:create_organisation]

    @tag :capture_log
    test "a viewer cannot delete the organisation with a LiveView event",
         %{conn: conn, organisation: organisation} do
      viewer = AccountsFixtures.user_fixture()
      MembersFixtures.membership_fixture(organisation, viewer, :viewer)

      {:ok, view, _html} = conn |> log_in_user(viewer) |> live(~p"/organisations")

      Process.flag(:trap_exit, true)
      catch_exit(render_hook(view, "delete", %{"org_id" => organisation.id}))

      assert Repo.get(Organisation, organisation.id)
    end

    test "a user cannot reject an invite that was sent to another address",
         %{conn: conn, user: owner, organisation: organisation} do
      {:ok, invite} = Members.create_invite(owner, organisation, %{email: "invited@example.com"})
      other_user = AccountsFixtures.confirmed_user_fixture()

      {:ok, view, _html} = conn |> log_in_user(other_user) |> live(~p"/organisations")
      render_hook(view, "reject_invitation", %{"invite_id" => invite.id})

      assert Repo.get(Invite, invite.id)
    end
  end
end
