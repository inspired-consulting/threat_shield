defmodule ThreatShield.SystemsTest do
  use ThreatShield.DataCase

  alias ThreatShield.Systems
  alias ThreatShield.UserFixtures
  alias ThreatShield.OrganisationsFixtures
  alias ThreatShield.Accounts

  describe "systems" do
    alias ThreatShield.Systems.System


    import ThreatShield.SystemsFixtures

      setup do
    {:ok, user} = Accounts.get_user!(1)
    {:ok, org} = ThreatShield.Threats.create_organisation(user, %{name: "Test Org"})
    {:ok, threat} = ThreatShield.Threats.create_threat(user, org, %{title: "Test Threat", description: "A test threat"})
    {:ok, _risk} = Risks.create_risk(user, threat.id, %{name: "Test Risk"})
    {:ok, user: user, org: org, threat: threat}
  end

    test "create_system/3 with valid data creates a system" do
      {:ok, user} = ThreatShield.Accounts.register_user(%{email: "user@example.com", password: "newsafepassword"})
      {:ok, organisation} = ThreatShield.Organisations.create_organisation(%{name: "Test Org"}, user)

      valid_attrs = %{name: "Test System", description: "Test System Description"}

      assert {:ok, %System{} = system} = Systems.create_system(user, organisation, valid_attrs)
      assert system.name == "Test System"
      assert system.organisation_id == organisation.id
    end

    test "create_system/3 with invalid data returns error changeset" do
      {:ok, user} = ThreatShield.Accounts.register_user(%{email: "user@example.com", password: "newsafepassword"})
      {:ok, organisation} = ThreatShield.Organisations.create_organisation(%{name: "Test Org"}, user)

      assert {:error, %Ecto.Changeset{}} = Systems.create_system(user, organisation, %{})
    end

   test "update_system/4 with valid data updates the system" do
      {:ok, user} = ThreatShield.Accounts.register_user(%{email: "user@example.com", password: "newsafepassword"})
      {:ok, organisation} = ThreatShield.Organisations.create_organisation(%{name: "Test Org"}, user)
      system = ThreatShield.Systems.create_system(organisation, %{name: "Test System"})

      updated_system_attrs = %{name: "Updated System"}
      updated_system = ThreatShield.Systems.update_system(user, organisation, system, updated_system_attrs)

      assert updated_system.valid?
      assert updated_system.name == "Updated System"
    end


    test "update_system/4 with invalid data returns error changeset" do
      {:ok, user} = ThreatShield.Accounts.register_user(%{email: "user@example.com", password: "newsafepassword"})
      {:ok, organisation} = ThreatShield.Organisations.create_organisation(%{name: "Test Org"}, user)
      system = ThreatShield.Systems.create_system(user, organisation, %{})

      assert {:error, %Ecto.Changeset{}} = Systems.update_system(user, organisation, system, %{})
    end

    test "delete_system/3 deletes the system" do
      {:ok, user} = ThreatShield.Accounts.register_user(%{email: "user@example.com", password: "newsafepassword"})
      {:ok, organisation} = ThreatShield.Organisations.create_organisation(%{name: "Test Org"}, user)
      system = ThreatShield.Systems.create_system(user, organisation, %{})

      assert {:ok, %System{}} = Systems.delete_system(user, organisation, system)
      assert_raise Ecto.NoResultsError, fn -> Systems.get_system!(user, system.id) end
    end
  end
  end
