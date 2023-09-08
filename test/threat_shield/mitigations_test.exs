defmodule ThreatShield.MitigationsTest do
  use ThreatShield.DataCase

  alias ThreatShield.Mitigations

  describe "mitigations" do
    alias ThreatShield.Mitigations.Mitigation

    import ThreatShield.MitigationsFixtures

    @invalid_attrs %{name: nil, description: nil, is_implemented: nil}

    test "list_mitigations/0 returns all mitigations" do
      mitigation = mitigation_fixture()
      assert Mitigations.list_mitigations() == [mitigation]
    end

    test "get_mitigation!/1 returns the mitigation with given id" do
      mitigation = mitigation_fixture()
      assert Mitigations.get_mitigation!(mitigation.id) == mitigation
    end

    test "create_mitigation/1 with valid data creates a mitigation" do
      valid_attrs = %{name: "some name", description: "some description", is_implemented: true}

      assert {:ok, %Mitigation{} = mitigation} = Mitigations.create_mitigation(valid_attrs)
      assert mitigation.name == "some name"
      assert mitigation.description == "some description"
      assert mitigation.is_implemented == true
    end

    test "create_mitigation/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Mitigations.create_mitigation(@invalid_attrs)
    end

    test "update_mitigation/2 with valid data updates the mitigation" do
      mitigation = mitigation_fixture()
      update_attrs = %{name: "some updated name", description: "some updated description", is_implemented: false}

      assert {:ok, %Mitigation{} = mitigation} = Mitigations.update_mitigation(mitigation, update_attrs)
      assert mitigation.name == "some updated name"
      assert mitigation.description == "some updated description"
      assert mitigation.is_implemented == false
    end

    test "update_mitigation/2 with invalid data returns error changeset" do
      mitigation = mitigation_fixture()
      assert {:error, %Ecto.Changeset{}} = Mitigations.update_mitigation(mitigation, @invalid_attrs)
      assert mitigation == Mitigations.get_mitigation!(mitigation.id)
    end

    test "delete_mitigation/1 deletes the mitigation" do
      mitigation = mitigation_fixture()
      assert {:ok, %Mitigation{}} = Mitigations.delete_mitigation(mitigation)
      assert_raise Ecto.NoResultsError, fn -> Mitigations.get_mitigation!(mitigation.id) end
    end

    test "change_mitigation/1 returns a mitigation changeset" do
      mitigation = mitigation_fixture()
      assert %Ecto.Changeset{} = Mitigations.change_mitigation(mitigation)
    end
  end
end
