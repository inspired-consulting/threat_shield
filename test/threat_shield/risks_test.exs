defmodule ThreatShield.RisksTest do
  use ThreatShield.DataCase

  alias ThreatShield.Accounts
  alias ThreatShield.Repo
  alias ThreatShield.Risks
  alias ThreatShield.Threats
  alias ThreatShield.Organisations

  describe "risks" do

    import ThreatShield.RisksFixtures
    @invalid_attrs %{name: nil, description: nil}

    test "create_risk/3" do

    end


  end
end
