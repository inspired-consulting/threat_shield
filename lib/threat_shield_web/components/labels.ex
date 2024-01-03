defmodule ThreatShieldWeb.Labels do
  use Phoenix.Component

  use ThreatShieldWeb, :verified_routes
  import ThreatShieldWeb.Gettext

  def risk_status_label(status) when is_binary(status),
    do: risk_status_label(String.to_existing_atom(status))

  def risk_status_label(status) when is_atom(status) do
    available_risk_states()
    |> Enum.find(fn {key, _label} -> key == status end)
    |> case do
      {_key, label} -> label
      _ -> status
    end
  end

  def risk_status_label(status), do: status

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
end
