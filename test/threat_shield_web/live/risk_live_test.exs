defmodule ThreatShieldWeb.RiskLiveTest do
  use ThreatShieldWeb.ConnCase

  import Phoenix.LiveViewTest
  import ThreatShield.RisksFixtures

  alias ThreatShield.Accounts

  @create_attrs %{name: "some name", description: "some description", estimated_cost: 42, probability: 120.5}
  @update_attrs %{name: "some updated name", description: "some updated description", estimated_cost: 43, probability: 456.7}
  @invalid_attrs %{name: nil, description: nil, estimated_cost: nil, probability: nil}

  defp create_risk(user) do
    {:ok, user} = ThreatShield.Accounts.get_user!(1)
    risk_fixture(user, @create_attrs)
  end

  describe "Index" do
    setup [:create_risk]

    test "lists all risks", %{conn: conn, risk: risk} do
      {:ok, _index_live, html} = live(conn, ~p"/organisations/:org_id/threats/:threat_id/risks")

      assert html =~ "Listing Risks"
      assert html =~ risk.name
    end
  end
end
