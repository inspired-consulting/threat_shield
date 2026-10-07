defmodule ThreatShieldWeb.EntityFormLiveTest do
  @moduledoc """
  Tests creating and editing entities through the form components.
  """
  use ThreatShieldWeb.ConnCase

  import Phoenix.LiveViewTest

  alias ThreatShield.OrganisationsFixtures
  alias ThreatShield.RisksFixtures
  alias ThreatShield.ThreatsFixtures

  alias ThreatShield.Repo
  alias ThreatShield.Systems
  alias ThreatShield.Accounts.Organisation
  alias ThreatShield.Assets.Asset
  alias ThreatShield.Mitigations.Mitigation
  alias ThreatShield.Risks.Risk
  alias ThreatShield.Systems.System
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

    threat = ThreatsFixtures.threat_fixture(user, organisation, %{name: "Data theft"})
    risk = RisksFixtures.risk_fixture(user, threat.id, %{name: "Fine"})

    %{
      organisation: organisation,
      system: system,
      threat: threat,
      risk: risk,
      org_path: ~p"/organisations/#{organisation.id}"
    }
  end

  defp switch_tab(view, tab), do: render_hook(view, "switch_tab", %{"tab" => tab})

  test "creates an organisation", %{conn: conn} do
    {:ok, view, _html} = live(conn, ~p"/organisations/new")

    view |> form("#organisation-form", organisation: %{name: "New org"}) |> render_submit()

    assert_patch(view, ~p"/organisations")
    assert render(view) =~ "New org"
    assert Repo.get_by!(Organisation, name: "New org")
  end

  test "creates a system from the systems list",
       %{conn: conn, organisation: organisation, org_path: org_path} do
    {:ok, view, _html} = live(conn, org_path)

    view |> element(~s([phx-click="open-create-system-modal"])) |> render_click()

    view
    |> form("#system-form", system: %{name: "Back office", description: "Internal"})
    |> render_submit()

    assert_patch(view, org_path)

    html = render(view)
    assert html =~ "Back office"
    assert html =~ "Web shop"

    assert %System{description: "Internal"} = system = Repo.get_by!(System, name: "Back office")
    assert system.organisation_id == organisation.id
  end

  test "creates an asset from the assets list",
       %{conn: conn, organisation: organisation, org_path: org_path} do
    {:ok, view, _html} = live(conn, org_path)
    switch_tab(view, "assets")

    view |> element(~s([phx-click="open-create-dialog"])) |> render_click()

    view
    |> form("#asset-form", asset: %{name: "Customer data", description: "Personal data"})
    |> render_submit()

    assert_patch(view, org_path)
    assert render(view) =~ "Customer data"

    assert %Asset{} = asset = Repo.get_by!(Asset, name: "Customer data")
    assert asset.organisation_id == organisation.id
  end

  test "creates a threat from the threats list",
       %{conn: conn, organisation: organisation, org_path: org_path} do
    {:ok, view, _html} = live(conn, org_path)
    switch_tab(view, "threats")

    view |> element(~s([phx-click="open-create-dialog"])) |> render_click()

    view
    |> form("#threat-form", threat: %{name: "Ransomware", description: "Encrypts data"})
    |> render_submit()

    assert_patch(view, org_path)
    assert render(view) =~ "Ransomware"

    assert %Threat{} = threat = Repo.get_by!(Threat, name: "Ransomware")
    assert threat.organisation_id == organisation.id
  end

  test "edits a threat", %{conn: conn, threat: threat, org_path: org_path} do
    {:ok, view, _html} = live(conn, org_path <> "/threats/#{threat.id}/edit")

    view |> form("#threat-form", threat: %{name: "Data leak"}) |> render_submit()

    assert_patch(view, org_path <> "/threats/#{threat.id}")
    assert render(view) =~ "Data leak"
    assert Repo.get!(Threat, threat.id).name == "Data leak"
  end

  test "creates a risk for a threat", %{conn: conn, threat: threat, org_path: org_path} do
    {:ok, view, _html} = live(conn, org_path <> "/threats/#{threat.id}/risks/new")

    view
    |> form("#risk-form", risk: %{name: "Loss of customers", description: "Customers leave"})
    |> render_submit()

    assert_patch(view, org_path <> "/threats/#{threat.id}")
    assert render(view) =~ "Loss of customers"

    assert %Risk{} = risk = Repo.get_by!(Risk, name: "Loss of customers")
    assert risk.threat_id == threat.id
  end

  test "shows validation errors for a duplicate system name and a long threat name",
       %{conn: conn, org_path: org_path} do
    {:ok, view, _html} = live(conn, org_path)
    view |> element(~s([phx-click="open-create-system-modal"])) |> render_click()

    html =
      view
      |> form("#system-form", system: %{name: "Web shop", description: "Another one"})
      |> render_submit()

    assert html =~ "is already used by another system of this organisation"
    assert Repo.aggregate(System, :count) == 1

    {:ok, view, _html} = live(conn, org_path)
    switch_tab(view, "threats")
    view |> element(~s([phx-click="open-create-dialog"])) |> render_click()

    html =
      view
      |> form("#threat-form", threat: %{name: String.duplicate("x", 61), description: "d"})
      |> render_submit()

    assert html =~ "should be at most 60 character(s)"
    refute Repo.get_by(Threat, description: "d")
  end

  test "creates a mitigation for a risk and shows validation errors",
       %{conn: conn, threat: threat, risk: risk, org_path: org_path} do
    risk_path = org_path <> "/threats/#{threat.id}/risks/#{risk.id}"
    {:ok, view, _html} = live(conn, risk_path <> "/mitigations/new")

    html =
      view
      |> form("#mitigation-form",
        mitigation: %{name: String.duplicate("x", 61), description: "Encrypt"}
      )
      |> render_submit()

    assert html =~ "should be at most 60 character(s)"
    refute Repo.get_by(Mitigation, description: "Encrypt")

    view
    |> form("#mitigation-form", mitigation: %{name: "Encryption", description: "Encrypt"})
    |> render_submit()

    assert_patch(view, risk_path)
    assert render(view) =~ "Encryption"

    assert %Mitigation{} = mitigation = Repo.get_by!(Mitigation, name: "Encryption")
    assert mitigation.risk_id == risk.id
  end
end
