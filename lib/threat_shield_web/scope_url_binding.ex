defmodule ThreatShieldWeb.ScopeUrlBinding do
  @moduledoc """
  Can read the Scope from an URL and create a URL from a Scope.
  """

  alias ThreatShield.Scope

  alias ThreatShield.Assets.Asset

  use Phoenix.VerifiedRoutes,
    endpoint: ThreatShieldWeb.Endpoint,
    router: ThreatShieldWeb.Router,
    statics: ThreatShieldWeb.static_paths()

  def threat_scope_from_params(user, threat, params) when is_map(params) do
    system = if Map.has_key?(params, "sys_id"), do: threat.system, else: nil
    asset = if Map.has_key?(params, "asset_id"), do: threat.asset, else: nil

    Scope.for(user, threat.organisation,
      threat: threat,
      system: system,
      asset: asset
    )
  end

  def asset_scope_from_params(user, %Asset{} = asset, params) when is_map(params) do
    system = if Map.has_key?(params, "sys_id"), do: asset.system, else: nil

    Scope.for(user, asset.organisation,
      system: system,
      asset: asset
    )
  end

  def threat_scope_to_url(%Scope{threat: threat} = scope) do
    if is_nil(scope.system) do
      ~p"/organisations/#{threat.organisation.id}/threats/#{threat.id}"
    else
      ~p"/organisations/#{threat.organisation.id}/systems/#{scope.system.id}/threats/#{threat.id}"
    end
  end

  def asset_scope_to_url(%Scope{asset: asset} = scope) do
    if is_nil(scope.system) do
      ~p"/organisations/#{asset.organisation.id}/assets/#{asset.id}"
    else
      ~p"/organisations/#{asset.organisation.id}/systems/#{scope.system.id}/assets/#{asset.id}"
    end
  end

  def risk_scope_to_url(%Scope{organisation: org, threat: threat} = scope, risk) do
    if is_nil(scope.system) do
      ~p"/organisations/#{org.id}/threats/#{threat.id}/risks/#{risk.id}"
    else
      ~p"/organisations/#{org.id}/systems/#{scope.system.id}/threats/#{threat.id}/risks/#{risk.id}"
    end
  end
end
