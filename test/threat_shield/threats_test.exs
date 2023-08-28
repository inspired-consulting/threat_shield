defmodule ThreatShield.ThreatsTest do
  use ExUnit.Case
  alias ThreatShield.{Threats, Organisations, Repo, Accounts}
  alias ThreatShield.Threats.Threat
  alias ThreatShield.Risks.Risk
  alias ThreatShield.Organisations.Organisation
  alias ThreatShield.ThreatsFixtures

  setup do
    {:ok, user} = Accounts.get_user!(1)
    {:ok, org} = Organisations.create_organisation(user, %{name: "Test Org"})
    {:ok, _threat} = Threats.create_threat(user, org, %{title: "Test Threat", description: "A test threat"})
    {:ok, user: user, org: org}
  end

  test "get_threat!/3 returns the threat with the given id and organization" do
    threat = ThreatsFixtures.threat_fixture(@user, @org, %{title: "Another Threat"})
    retrieved_threat = Threats.get_threat!(@user, @org.id, threat.id)
    assert retrieved_threat.title == "Another Threat"
  end

  test "create_threat/3 creates a new threat" do
    threat_attrs = %{title: "New Threat"}
    threat = ThreatsFixtures.threat_fixture(@user, @org, threat_attrs)

    assert threat.title == "New Threat"
  end
end
