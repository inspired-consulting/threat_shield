defmodule ThreatShieldWeb.AssetLiveTest do
  use ThreatShieldWeb.ConnCase
  import Phoenix.LiveViewTest

  alias ThreatShield.AssetsFixtures
  alias ThreatShield.AccountsFixtures
  alias ThreatShield.OrganisationsFixtures
  alias ThreatShieldWe

  @create_attrs %{description: "some description"}

  defp create_asset(_) do
    user = AccountsFixtures.user_fixture()
    organisation = OrganisationsFixtures.organisation_fixture(user)
    asset = AssetsFixtures.asset_fixture(user, organisation, @create_attrs)
    %{user: user, organisation: organisation, asset: asset}
  end

  describe "Index" do
    setup [:create_asset]

    test "lists all assets", %{conn: conn, user: user, asset: asset} do
      conn_with_session = assign(conn, :current_user, user)

      case live(conn_with_session, ~p"/organisations/:org_id/assets") do
        {:ok, _index_live, html} ->
          assert html =~ "Listing Assets"
          assert html =~ asset.description

        {:error, _} ->
          IO.inspect("User is not logged in")
      end
    end
  end
end
