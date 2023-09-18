defmodule ThreatShieldWeb.OrganisationLiveTest do
  use ThreatShieldWeb.ConnCase

  import Phoenix.LiveViewTest

  alias ThreatShield.AccountsFixtures
  alias ThreatShield.OrganisationsFixtures

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
end
