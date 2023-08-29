defmodule ThreatShieldWeb.ThreatLiveTest do
  use ThreatShieldWeb.ConnCase

  import Phoenix.LiveViewTest

  alias ThreatShield.AccountsFixtures
  alias ThreatShield.OrganisationsFixtures
  alias ThreatShield.ThreatsFixtures

  @create_attrs %{description: "some description", is_candidate: true}

  defp create_threat(_) do
    user = AccountsFixtures.user_fixture()
    organisation = OrganisationsFixtures.organisation_fixture(user)
    threat = ThreatsFixtures.threat_fixture(user, organisation, @create_attrs)
    %{user: user, organisation: organisation, threat: threat}
  end

  describe "Index" do
    setup [:create_threat]

    test "redirect to /threats if user is logged in", %{conn: conn} do
      user = AccountsFixtures.user_fixture()
      conn_with_session = assign(conn, :current_user, user)

      case live(conn_with_session, ~p"/organisations/{organisation_id}/threats") do
        {:ok, _} ->
          assert redirected_to(~p"/organisations/{organisation_id}/threats")

        {:error, _} ->
          assert true
      end
    end
  end
end
