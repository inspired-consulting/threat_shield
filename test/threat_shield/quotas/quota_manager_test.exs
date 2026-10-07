defmodule ThreatShield.Quotas.QuotaManagerTest do
  use ThreatShield.DataCase

  alias ThreatShield.AccountsFixtures
  alias ThreatShield.OrganisationsFixtures

  alias ThreatShield.Repo
  alias ThreatShield.Organisations
  alias ThreatShield.Quotas.{QuotaManager, QuotaUsage}

  @quota "ai_requests_per_month"

  setup do
    user = AccountsFixtures.user_fixture()
    organisation = OrganisationsFixtures.organisation_fixture(user)
    # a second user, so that the user id differs from the organisation id for sure
    other_user = AccountsFixtures.user_fixture()
    organisation = Organisations.get_organisation!(user, organisation.id)

    %{user: other_user, organisation: organisation}
  end

  test "add_usage/5 stores the usage with the user and the current time",
       %{user: user, organisation: organisation} do
    before = DateTime.utc_now()

    assert {:ok, %QuotaUsage{} = usage} =
             QuotaManager.add_usage(organisation, user, @quota, 1.0, "AI request")

    usage = Repo.get!(QuotaUsage, usage.id)
    assert usage.user_id == user.id
    assert usage.organisation_id == organisation.id
    assert DateTime.compare(usage.timestamp, before) in [:gt, :eq]
  end

  test "get_usage/2 counts the usage of the last month only",
       %{user: user, organisation: organisation} do
    {:ok, _} = QuotaManager.add_usage(organisation, user, @quota, 1.0)
    {:ok, _} = QuotaManager.add_usage(organisation, user, @quota, 2.5)

    {:ok, old} = QuotaManager.add_usage(organisation, user, @quota, 10.0)
    two_months_ago = DateTime.add(DateTime.utc_now(), -62, :day)

    Repo.update_all(from(q in QuotaUsage, where: q.id == ^old.id),
      set: [timestamp: two_months_ago]
    )

    assert QuotaManager.get_usage(organisation, @quota) == 3.5
  end

  test "check_quota/3 refuses a request above the quota",
       %{user: user, organisation: organisation} do
    assert {:ok, :quota_available} = QuotaManager.check_quota(organisation, @quota, 1)

    {:ok, _} = QuotaManager.add_usage(organisation, user, @quota, 100.0)

    assert {:error, :quota_exceeded} = QuotaManager.check_quota(organisation, @quota, 1)
  end

  test "deleting the user or the organisation keeps the database consistent",
       %{user: user, organisation: organisation} do
    {:ok, usage} = QuotaManager.add_usage(organisation, user, @quota, 1.0)

    Repo.delete!(user)
    assert %QuotaUsage{user_id: nil} = Repo.get!(QuotaUsage, usage.id)

    Repo.delete!(organisation)
    refute Repo.get(QuotaUsage, usage.id)
  end
end
