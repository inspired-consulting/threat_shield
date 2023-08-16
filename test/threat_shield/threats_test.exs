defmodule ThreatShield.ThreatsTest do
  use ThreatShield.DataCase

  alias ThreatShield.Threats

  describe "threats" do
    alias ThreatShield.Threats.Threat

    import ThreatShield.ThreatsFixtures

    @invalid_attrs %{description: nil, is_candidate: nil}

    test "list_threats/0 returns all threats" do
      threat = threat_fixture()
      assert Threats.list_threats() == [threat]
    end

    test "get_threat!/1 returns the threat with given id" do
      threat = threat_fixture()
      assert Threats.get_threat!(threat.id) == threat
    end

    test "create_threat/1 with valid data creates a threat" do
      valid_attrs = %{description: "some description", is_candidate: true}

      assert {:ok, %Threat{} = threat} = Threats.create_threat(valid_attrs)
      assert threat.description == "some description"
      assert threat.is_candidate == true
    end

    test "create_threat/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Threats.create_threat(@invalid_attrs)
    end

    test "update_threat/2 with valid data updates the threat" do
      threat = threat_fixture()
      update_attrs = %{description: "some updated description", is_candidate: false}

      assert {:ok, %Threat{} = threat} = Threats.update_threat(threat, update_attrs)
      assert threat.description == "some updated description"
      assert threat.is_candidate == false
    end

    test "update_threat/2 with invalid data returns error changeset" do
      threat = threat_fixture()
      assert {:error, %Ecto.Changeset{}} = Threats.update_threat(threat, @invalid_attrs)
      assert threat == Threats.get_threat!(threat.id)
    end

    test "delete_threat/1 deletes the threat" do
      threat = threat_fixture()
      assert {:ok, %Threat{}} = Threats.delete_threat(threat)
      assert_raise Ecto.NoResultsError, fn -> Threats.get_threat!(threat.id) end
    end

    test "change_threat/1 returns a threat changeset" do
      threat = threat_fixture()
      assert %Ecto.Changeset{} = Threats.change_threat(threat)
    end
  end
end
