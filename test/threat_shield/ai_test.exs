defmodule ThreatShield.AITest do
  use ThreatShield.DataCase

  alias ThreatShield.AccountsFixtures
  alias ThreatShield.AssetsFixtures
  alias ThreatShield.MitigationsFixtures
  alias ThreatShield.OrganisationsFixtures
  alias ThreatShield.RisksFixtures
  alias ThreatShield.ThreatsFixtures

  alias ThreatShield.AI
  alias ThreatShield.Scope
  alias ThreatShield.{Assets, Organisations, Risks, Systems, Threats}
  alias ThreatShield.Assets.Asset
  alias ThreatShield.Mitigations.Mitigation
  alias ThreatShield.Risks.Risk
  alias ThreatShield.Threats.Threat

  setup do
    Application.put_env(:threat_shield, :open_ai_stub_listener, self())
    on_exit(fn -> Application.delete_env(:threat_shield, :open_ai_stub_listener) end)

    user = AccountsFixtures.user_fixture()
    organisation = OrganisationsFixtures.organisation_fixture(user, %{name: "ACME"})

    {:ok, system} =
      Systems.create_system(user, organisation, %{
        name: "Web shop",
        description: "Sells products",
        attributes: %{"Database" => "Postgres"}
      })

    asset =
      AssetsFixtures.asset_fixture(user, organisation, %{
        name: "Customer data",
        system_id: system.id
      })

    threat =
      ThreatsFixtures.threat_fixture(user, organisation, %{
        name: "Data theft",
        system_id: system.id,
        asset_id: asset.id
      })

    risk = RisksFixtures.risk_fixture(user, threat.id, %{name: "Fine by the authority"})
    MitigationsFixtures.mitigation_fixture(user, risk, %{name: "Encrypt the database"})

    %{
      user: user,
      organisation: organisation,
      system: system,
      asset: asset,
      threat: threat,
      risk: risk
    }
  end

  defp prompts() do
    assert_received {:open_ai_request,
                     [
                       %{role: "system", content: system_prompt},
                       %{role: "user", content: user_prompt}
                     ]}

    {system_prompt, user_prompt}
  end

  test "suggest_assets/1 for an organisation", %{user: user, organisation: organisation} do
    organisation = Organisations.get_organisation!(user, organisation.id)

    assert [%Asset{name: "Suggestion 1", description: "Description 1"}, %Asset{}] =
             AI.suggest_assets(Scope.for(user, organisation))

    {system_prompt, user_prompt} = prompts()

    assert system_prompt =~ ~s(You are a threat modelling assistant at "ACME".)
    assert system_prompt =~ ~s(The name of the system is "Web shop".)
    assert user_prompt =~ ~s({"assets": [{"name": _, "description": _}, _ ]})
    assert user_prompt =~ "I already know about the following assets:\n\nCustomer data"

    assert user_prompt =~
             "Please suggest five additional assets that are different from the existing ones.\n"
  end

  test "suggest_assets/1 for a system", %{user: user, organisation: organisation, system: system} do
    organisation = Organisations.get_organisation!(user, organisation.id)
    system = Systems.get_system!(user, system.id)

    assert [%Asset{}, %Asset{}] = AI.suggest_assets(Scope.for(user, organisation, system: system))

    {_system_prompt, user_prompt} = prompts()

    assert user_prompt =~ "Assets are valuable resources or data for a particular system"
    assert user_prompt =~ "Customer data"
    assert user_prompt =~ ~s(The assets should be specific to the system "Web shop".)
  end

  test "suggest_threats/1 for an organisation, a system, and an asset",
       %{user: user, organisation: organisation, system: system, asset: asset} do
    organisation = Organisations.get_organisation!(user, organisation.id)
    system = Systems.get_system!(user, system.id)
    asset = Assets.get_asset!(user, asset.id)

    assert [%Threat{name: "Suggestion 1"}, %Threat{}] =
             AI.suggest_threats(Scope.for(user, organisation))

    {_system_prompt, user_prompt} = prompts()
    assert user_prompt =~ ~s({"threats": [)
    assert user_prompt =~ "I already know about the following threats:\n\nData theft"
    refute user_prompt =~ "should be specific"

    assert [%Threat{}, %Threat{}] =
             AI.suggest_threats(Scope.for(user, organisation, system: system))

    {_system_prompt, user_prompt} = prompts()
    assert user_prompt =~ "The threats should be specific to the system 'Web shop'"

    assert [%Threat{}, %Threat{}] =
             AI.suggest_threats(Scope.for(user, organisation, asset: asset))

    {_system_prompt, user_prompt} = prompts()
    assert user_prompt =~ "The threats should be specific to the asset 'Customer data'"

    assert [%Threat{}, %Threat{}] =
             AI.suggest_threats(Scope.for(user, organisation, system: system, asset: asset))

    {_system_prompt, user_prompt} = prompts()
    assert user_prompt =~ "'Web shop'  and the asset 'Customer data'"
  end

  test "suggest_risks_for_threat/2", %{user: user, organisation: organisation, threat: threat} do
    organisation = Organisations.get_organisation!(user, organisation.id)
    threat = Threats.get_threat!(user, threat.id)

    assert [%Risk{name: "Suggestion 1"}, %Risk{}] =
             AI.suggest_risks_for_threat(Scope.for(user, organisation), threat)

    {system_prompt, user_prompt} = prompts()

    assert system_prompt =~ ~s(at "ACME")
    assert user_prompt =~ ~s({"risks": [)
    assert user_prompt =~ "I already know about the following risks:\n\nFine by the authority"
    assert user_prompt =~ ~s(The risks should relate exclusively to the threat "Data theft".)
  end

  test "suggest_mitigations_for_risk/2", %{user: user, organisation: organisation, risk: risk} do
    organisation = Organisations.get_organisation!(user, organisation.id)
    risk = Risks.get_risk!(user, risk.id)

    assert [%Mitigation{name: "Suggestion 1"}, %Mitigation{}] =
             AI.suggest_mitigations_for_risk(Scope.for(user, organisation), risk)

    {_system_prompt, user_prompt} = prompts()

    assert user_prompt =~ ~s({"mitigations": [)

    assert user_prompt =~
             "I already know about the following mitigations:\n\nEncrypt the database"

    assert user_prompt =~
             ~s(exclusively to the risk "Fine by the authority" and the threat "Data theft".)

    assert user_prompt =~ ~s(The only relvant system in this context is "Web shop".)
  end
end
