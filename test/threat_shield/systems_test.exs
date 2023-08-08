defmodule ThreatShield.SystemsTest do
  use ThreatShield.DataCase

  alias ThreatShield.Systems

  describe "systems" do
    alias ThreatShield.Systems.System

    import ThreatShield.SystemsFixtures

    @invalid_attrs %{attributes: nil, name: nil, description: nil}

    test "list_systems/0 returns all systems" do
      system = system_fixture()
      assert Systems.list_systems() == [system]
    end

    test "get_system!/1 returns the system with given id" do
      system = system_fixture()
      assert Systems.get_system!(system.id) == system
    end

    test "create_system/1 with valid data creates a system" do
      valid_attrs = %{attributes: %{}, name: "some name", description: "some description"}

      assert {:ok, %System{} = system} = Systems.create_system(valid_attrs)
      assert system.attributes == %{}
      assert system.name == "some name"
      assert system.description == "some description"
    end

    test "create_system/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Systems.create_system(@invalid_attrs)
    end

    test "update_system/2 with valid data updates the system" do
      system = system_fixture()
      update_attrs = %{attributes: %{}, name: "some updated name", description: "some updated description"}

      assert {:ok, %System{} = system} = Systems.update_system(system, update_attrs)
      assert system.attributes == %{}
      assert system.name == "some updated name"
      assert system.description == "some updated description"
    end

    test "update_system/2 with invalid data returns error changeset" do
      system = system_fixture()
      assert {:error, %Ecto.Changeset{}} = Systems.update_system(system, @invalid_attrs)
      assert system == Systems.get_system!(system.id)
    end

    test "delete_system/1 deletes the system" do
      system = system_fixture()
      assert {:ok, %System{}} = Systems.delete_system(system)
      assert_raise Ecto.NoResultsError, fn -> Systems.get_system!(system.id) end
    end

    test "change_system/1 returns a system changeset" do
      system = system_fixture()
      assert %Ecto.Changeset{} = Systems.change_system(system)
    end
  end
end
