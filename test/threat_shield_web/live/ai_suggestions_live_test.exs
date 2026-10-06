defmodule ThreatShieldWeb.AiSuggestionsLiveTest do
  @moduledoc """
  Tests the AI suggestion flow of the list components: request suggestions,
  select one in the dialog, and create the entity.

  The OpenAI client is replaced by `ThreatShield.OpenAIStub`.
  """
  use ThreatShieldWeb.ConnCase

  import Phoenix.LiveViewTest

  alias ThreatShield.AssetsFixtures
  alias ThreatShield.OrganisationsFixtures
  alias ThreatShield.RisksFixtures
  alias ThreatShield.ThreatsFixtures

  alias ThreatShield.Repo
  alias ThreatShield.Systems
  alias ThreatShield.Assets.Asset
  alias ThreatShield.Mitigations.Mitigation
  alias ThreatShield.Risks.Risk
  alias ThreatShield.Threats.Threat

  @moduletag :capture_log

  setup :register_and_log_in_user

  setup %{user: user} do
    organisation = OrganisationsFixtures.organisation_fixture(user)

    {:ok, system} =
      Systems.create_system(user, organisation, %{
        name: "Web shop",
        description: "Sells products",
        attributes: %{}
      })

    asset = AssetsFixtures.asset_fixture(user, organisation, %{system_id: system.id})

    threat =
      ThreatsFixtures.threat_fixture(user, organisation, %{
        system_id: system.id,
        asset_id: asset.id
      })

    risk = RisksFixtures.risk_fixture(user, threat.id)

    %{organisation: organisation, system: system, asset: asset, threat: threat, risk: risk}
  end

  # Requests suggestions, waits for the dialog, and applies the first suggestion.
  defp suggest_and_apply(view, entities) do
    view |> element(~s([phx-click="suggest_#{entities}"])) |> render_click()

    assert wait_for(view, "Suggestion 1") =~ "Description 2"

    view
    |> element("#suggest-#{entities}-modal form")
    |> render_submit(%{"selected_suggestions" => ["Suggestion 1"]})
  end

  defp wait_for(view, text, attempts \\ 100) do
    html = render(view)

    cond do
      html =~ text -> html
      attempts == 0 -> flunk("\"#{text}\" did not appear")
      true -> Process.sleep(20) && wait_for(view, text, attempts - 1)
    end
  end

  defp switch_tab(view, tab), do: render_hook(view, "switch_tab", %{"tab" => tab})

  test "threats for an organisation", %{conn: conn, organisation: organisation} do
    {:ok, view, _html} = live(conn, ~p"/organisations/#{organisation.id}")
    switch_tab(view, "threats")

    html = suggest_and_apply(view, "threats")

    assert html =~ "Suggestion 1"
    refute html =~ "Suggestion 2"

    assert %Threat{description: "Description 1", system_id: nil, asset_id: nil} =
             threat = Repo.get_by!(Threat, name: "Suggestion 1")

    assert threat.organisation_id == organisation.id
    refute Repo.get_by(Threat, name: "Suggestion 2")
  end

  test "threats for a system", %{conn: conn, organisation: organisation, system: system} do
    {:ok, view, _html} = live(conn, ~p"/organisations/#{organisation.id}/systems/#{system.id}")
    switch_tab(view, "threats")

    assert suggest_and_apply(view, "threats") =~ "Suggestion 1"

    threat = Repo.get_by!(Threat, name: "Suggestion 1")
    assert threat.organisation_id == organisation.id
    assert threat.system_id == system.id
    assert threat.asset_id == nil
  end

  test "threats for an asset", %{conn: conn, organisation: organisation, asset: asset} do
    {:ok, view, _html} = live(conn, ~p"/organisations/#{organisation.id}/assets/#{asset.id}")

    assert suggest_and_apply(view, "threats") =~ "Suggestion 1"

    threat = Repo.get_by!(Threat, name: "Suggestion 1")
    assert threat.organisation_id == organisation.id
    assert threat.asset_id == asset.id
    assert threat.system_id == nil
  end

  test "assets for an organisation and for a system",
       %{conn: conn, organisation: organisation, system: system} do
    {:ok, view, _html} = live(conn, ~p"/organisations/#{organisation.id}")
    switch_tab(view, "assets")

    assert suggest_and_apply(view, "assets") =~ "Suggestion 1"

    assert %Asset{description: "Description 1", system_id: nil} =
             asset = Repo.get_by!(Asset, name: "Suggestion 1")

    assert asset.organisation_id == organisation.id
    Repo.delete!(asset)

    {:ok, view, _html} = live(conn, ~p"/organisations/#{organisation.id}/systems/#{system.id}")
    switch_tab(view, "assets")

    assert suggest_and_apply(view, "assets") =~ "Suggestion 1"

    asset = Repo.get_by!(Asset, name: "Suggestion 1")
    assert asset.organisation_id == organisation.id
    assert asset.system_id == system.id
  end

  test "risks for a threat", %{conn: conn, organisation: organisation, threat: threat} do
    {:ok, view, _html} = live(conn, ~p"/organisations/#{organisation.id}/threats/#{threat.id}")

    assert suggest_and_apply(view, "risks") =~ "Suggestion 1"

    assert %Risk{description: "Description 1"} = risk = Repo.get_by!(Risk, name: "Suggestion 1")
    assert risk.threat_id == threat.id
  end

  test "mitigations for a risk",
       %{conn: conn, organisation: organisation, threat: threat, risk: risk} do
    {:ok, view, _html} =
      live(conn, ~p"/organisations/#{organisation.id}/threats/#{threat.id}/risks/#{risk.id}")

    assert suggest_and_apply(view, "mitigations") =~ "Suggestion 1"

    assert %Mitigation{description: "Description 1", is_implemented: false} =
             mitigation = Repo.get_by!(Mitigation, name: "Suggestion 1")

    assert mitigation.risk_id == risk.id
  end
end
