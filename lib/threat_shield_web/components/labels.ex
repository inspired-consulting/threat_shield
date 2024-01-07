defmodule ThreatShieldWeb.Labels do
  use Phoenix.Component

  use ThreatShieldWeb, :verified_routes
  import ThreatShieldWeb.Gettext

  alias ThreatShield.Assets.Asset
  alias ThreatShield.Threats.Threat
  alias ThreatShield.Systems.System

  def system_label(%Threat{} = threat) do
    system_label(threat.system)
  end

  def system_label(%Asset{} = asset) do
    system_label(asset.system)
  end

  def system_label(%System{} = system), do: system.name

  def system_label(_), do: dgettext("common", "Organisation wide")

  def risk_status_label(status) when is_binary(status),
    do: risk_status_label(String.to_existing_atom(status))

  def risk_status_label(status) when is_atom(status) do
    available_risk_states()
    |> find_by_key(status)
  end

  def risk_status_label(status), do: status

  def mitigation_status_label(status) when is_binary(status),
    do: mitigation_status_label(String.to_existing_atom(status))

  def mitigation_status_label(status) when is_atom(status) do
    available_mitigation_states()
    |> find_by_key(status)
  end

  def mitigation_status_label(status), do: status

  def available_risk_states() do
    [
      identified: dgettext("risks", "State:identified"),
      assessed: dgettext("risks", "State:assessed"),
      mitigation_planned: dgettext("risks", "State:mitigation_planned"),
      mitigation_in_progress: dgettext("risks", "State:mitigation_in_progress"),
      mitigated: dgettext("risks", "State:mitigated"),
      closed: dgettext("risks", "State:closed"),
      reopened: dgettext("risks", "State:reopened")
    ]
  end

  def available_mitigation_states() do
    [
      open: dgettext("mitigations", "State:open"),
      in_progress: dgettext("mitigations", "State:in_progress"),
      implemented: dgettext("mitigations", "State:implemented"),
      verified: dgettext("mitigations", "State:verified"),
      failed: dgettext("mitigations", "State:failed"),
      deferred: dgettext("mitigations", "State:deferred"),
      obsolete: dgettext("mitigations", "State:obsolete")
    ]
  end

  defp find_by_key(list, key) do
    Enum.find(list, fn {k, _} -> k == key end)
    |> case do
      {_key, label} -> label
      _ -> key
    end
  end
end
