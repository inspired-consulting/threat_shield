defmodule ThreatShield.MembersTest do
  use ThreatShield.DataCase

  alias ThreatShield.Members

  describe "invites" do
    alias ThreatShield.Members.Invites

    import ThreatShield.MembersFixtures

    @invalid_attrs %{token: nil, email: nil}

    test "list_invites/0 returns all invites" do
      invites = invites_fixture()
      assert Members.list_invites() == [invites]
    end

    test "get_invites!/1 returns the invites with given id" do
      invites = invites_fixture()
      assert Members.get_invites!(invites.id) == invites
    end

    test "create_invites/1 with valid data creates a invites" do
      valid_attrs = %{token: "some token", email: "some email"}

      assert {:ok, %Invites{} = invites} = Members.create_invites(valid_attrs)
      assert invites.token == "some token"
      assert invites.email == "some email"
    end

    test "create_invites/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Members.create_invites(@invalid_attrs)
    end

    test "update_invites/2 with valid data updates the invites" do
      invites = invites_fixture()
      update_attrs = %{token: "some updated token", email: "some updated email"}

      assert {:ok, %Invites{} = invites} = Members.update_invites(invites, update_attrs)
      assert invites.token == "some updated token"
      assert invites.email == "some updated email"
    end

    test "update_invites/2 with invalid data returns error changeset" do
      invites = invites_fixture()
      assert {:error, %Ecto.Changeset{}} = Members.update_invites(invites, @invalid_attrs)
      assert invites == Members.get_invites!(invites.id)
    end

    test "delete_invites/1 deletes the invites" do
      invites = invites_fixture()
      assert {:ok, %Invites{}} = Members.delete_invites(invites)
      assert_raise Ecto.NoResultsError, fn -> Members.get_invites!(invites.id) end
    end

    test "change_invites/1 returns a invites changeset" do
      invites = invites_fixture()
      assert %Ecto.Changeset{} = Members.change_invites(invites)
    end
  end
end
