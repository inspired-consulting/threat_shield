defmodule ThreatShieldWeb.SystemLiveTest do
  use ThreatShieldWeb.ConnCase

  alias ThreatShield.AccountsFixtures
  alias ThreatShield.OrganisationsFixtures
  alias ThreatShield.SystemsFixtures

  @create_attrs %{attributes: %{}, name: "some name", description: "some description"}

  defp create_system(_) do
    user = AccountsFixtures.user_fixture()
    organisation = OrganisationsFixtures.organisation_fixture(user)
    system = SystemsFixtures.system_fixture(user, organisation, @create_attrs)
    %{user: user, organisation: organisation, system: system}
  end

  describe "Index" do
    setup [:create_system]
  end
end
