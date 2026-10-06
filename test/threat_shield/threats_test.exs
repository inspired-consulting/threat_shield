defmodule ThreatShield.ThreatsTest do
  use ExUnit.Case
  use ThreatShield.DataCase

  alias ThreatShield.OrganisationsFixtures
  alias ThreatShield.AccountsFixtures
  alias ThreatShield.AssetsFixtures
  alias ThreatShield.MembersFixtures
  alias ThreatShield.Systems
  alias ThreatShield.Threats
  alias ThreatShield.Threats.Threat

  describe "threats" do
    test "create_threat/3 with valid data creates a threat" do
      user = AccountsFixtures.user_fixture()
      organisation = OrganisationsFixtures.organisation_fixture(user)

      valid_attrs = %{
        name: "some name",
        description: "some description",
        organisation: "some organisation"
      }

      assert {:ok, %Threat{}} = Threats.create_threat(user, organisation, valid_attrs)
    end
  end

  describe "add_threat_with_name_and_description/3" do
    alias ThreatShield.Scope

    setup do
      user = AccountsFixtures.user_fixture()
      organisation = OrganisationsFixtures.organisation_fixture(user)

      {:ok, system} =
        Systems.create_system(user, organisation, %{
          name: "some system",
          description: "some description",
          attributes: %{}
        })

      asset = AssetsFixtures.asset_fixture(user, organisation)
      organisation = ThreatShield.Organisations.get_organisation!(user, organisation.id)

      %{user: user, organisation: organisation, system: system, asset: asset}
    end

    test "creates a threat for the organisation, the system, and the asset of the scope",
         %{user: user, organisation: organisation, system: system, asset: asset} do
      assert {:ok, %Threat{system_id: nil, asset_id: nil}} =
               Threats.add_threat_with_name_and_description(
                 Scope.for(user, organisation),
                 "a name",
                 "a description"
               )

      scope = Scope.for(user, organisation, system: system, asset: asset)

      assert {:ok, %Threat{name: "a name", description: "a description"} = threat} =
               Threats.add_threat_with_name_and_description(scope, "a name", "a description")

      assert threat.organisation_id == organisation.id
      assert threat.system_id == system.id
      assert threat.asset_id == asset.id
    end

    test "is not allowed for a viewer", %{organisation: organisation} do
      viewer = AccountsFixtures.user_fixture()
      MembersFixtures.membership_fixture(organisation, viewer, :viewer)

      assert_raise Ecto.NoResultsError, fn ->
        Threats.add_threat_with_name_and_description(
          Scope.for(viewer, organisation),
          "a name",
          "a description"
        )
      end
    end
  end

  describe "references of a threat" do
    @valid_attrs %{name: "some name", description: "some description"}

    setup do
      user = AccountsFixtures.user_fixture()
      organisation = OrganisationsFixtures.organisation_fixture(user)
      {:ok, threat} = Threats.create_threat(user, organisation, @valid_attrs)

      other_user = AccountsFixtures.user_fixture()
      other_organisation = OrganisationsFixtures.organisation_fixture(other_user)

      %{
        user: user,
        organisation: organisation,
        threat: threat,
        other_user: other_user,
        other_organisation: other_organisation
      }
    end

    test "an asset of the same organisation is accepted",
         %{user: user, organisation: organisation, threat: threat} do
      asset = AssetsFixtures.asset_fixture(user, organisation)

      assert {:ok, %Threat{} = updated} =
               Threats.update_threat(user, threat, %{asset_id: asset.id})

      assert updated.asset_id == asset.id
    end

    test "an asset of another organisation is rejected", %{
      user: user,
      organisation: organisation,
      threat: threat,
      other_user: other_user,
      other_organisation: other_organisation
    } do
      foreign_asset = AssetsFixtures.asset_fixture(other_user, other_organisation)

      assert_raise Ecto.NoResultsError, fn ->
        Threats.create_threat(
          user,
          organisation,
          Map.put(@valid_attrs, :asset_id, foreign_asset.id)
        )
      end

      assert_raise Ecto.NoResultsError, fn ->
        Threats.update_threat(user, threat, %{asset_id: foreign_asset.id})
      end

      assert Repo.get!(Threat, threat.id).asset_id == nil
    end

    test "a system of another organisation is rejected, also for a member of both organisations",
         %{
           user: user,
           organisation: organisation,
           threat: threat,
           other_user: other_user,
           other_organisation: other_organisation
         } do
      {:ok, foreign_system} =
        Systems.create_system(other_user, other_organisation, %{
          name: "some system",
          description: "some description",
          attributes: %{}
        })

      MembersFixtures.membership_fixture(other_organisation, user, :viewer)

      assert_raise Ecto.NoResultsError, fn ->
        Threats.create_threat(
          user,
          organisation,
          Map.put(@valid_attrs, :system_id, foreign_system.id)
        )
      end

      assert_raise Ecto.NoResultsError, fn ->
        Threats.update_threat(user, threat, %{system_id: foreign_system.id})
      end

      assert Repo.get!(Threat, threat.id).system_id == nil
    end
  end
end
