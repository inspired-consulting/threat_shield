defmodule ThreatShieldWeb.EntityMenuLiveTest do
  @moduledoc """
  Tests the delete and edit entries on the detail pages: they are shown to members
  with the right only, and the delete entry deletes the entity.
  """
  use ThreatShieldWeb.ConnCase

  import Phoenix.LiveViewTest

  alias ThreatShield.AccountsFixtures
  alias ThreatShield.AssetsFixtures
  alias ThreatShield.MembersFixtures
  alias ThreatShield.MitigationsFixtures
  alias ThreatShield.OrganisationsFixtures
  alias ThreatShield.RisksFixtures
  alias ThreatShield.ThreatsFixtures

  alias ThreatShield.Repo
  alias ThreatShield.Systems
  alias ThreatShield.Mitigations.Mitigation
  alias ThreatShield.Risks.Risk
  alias ThreatShield.Threats.Threat

  setup :register_and_log_in_user

  setup %{user: user} do
    organisation = OrganisationsFixtures.organisation_fixture(user)

    {:ok, system} =
      Systems.create_system(user, organisation, %{
        name: "Web shop",
        description: "Sells products",
        attributes: %{}
      })

    asset = AssetsFixtures.asset_fixture(user, organisation)
    threat = ThreatsFixtures.threat_fixture(user, organisation)
    risk = RisksFixtures.risk_fixture(user, threat.id)
    mitigation = MitigationsFixtures.mitigation_fixture(user, risk)

    org_path = ~p"/organisations/#{organisation.id}"
    threat_path = org_path <> "/threats/#{threat.id}"
    risk_path = threat_path <> "/risks/#{risk.id}"

    paths = %{
      organisation: org_path,
      system: org_path <> "/systems/#{system.id}",
      asset: org_path <> "/assets/#{asset.id}",
      threat: threat_path,
      risk: risk_path,
      mitigation: risk_path <> "/mitigations/#{mitigation.id}"
    }

    %{
      organisation: organisation,
      threat: threat,
      risk: risk,
      mitigation: mitigation,
      paths: paths
    }
  end

  defp has_delete?(view), do: has_element?(view, "li.context-menu-item a", "Delete")
  defp has_edit?(view), do: has_element?(view, "a", "Edit")

  test "an owner sees the delete and edit entries on every detail page",
       %{conn: conn, paths: paths} do
    for {entity, path} <- paths do
      {:ok, view, _html} = live(conn, path)

      assert has_delete?(view), "no delete entry on the #{entity} page"
      assert has_edit?(view), "no edit entry on the #{entity} page"
    end
  end

  test "a viewer sees no delete and no edit entry",
       %{conn: conn, organisation: organisation, paths: paths} do
    viewer = AccountsFixtures.user_fixture()
    MembersFixtures.membership_fixture(organisation, viewer, :viewer)
    conn = log_in_user(conn, viewer)

    for {entity, path} <- paths do
      {:ok, view, _html} = live(conn, path)

      refute has_delete?(view), "delete entry on the #{entity} page"
      refute has_edit?(view), "edit entry on the #{entity} page"
    end
  end

  test "the delete entry deletes the entity",
       %{conn: conn, threat: threat, risk: risk, mitigation: mitigation, paths: paths} do
    for {path, schema, id} <- [
          {paths.mitigation, Mitigation, mitigation.id},
          {paths.risk, Risk, risk.id},
          {paths.threat, Threat, threat.id}
        ] do
      {:ok, view, _html} = live(conn, path)

      view |> element("li.context-menu-item a", "Delete") |> render_click()

      assert_redirect(view)
      refute Repo.get(schema, id)
    end
  end
end
