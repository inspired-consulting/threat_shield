defmodule ThreatShield.Analytics.RiskAnalytics do
  alias ThreatShield.Risks.Risk

  @moduledoc """
  This module provides analytics functions for risks.
  """

  def sum_up_risk_costs(risks) do
    risks
    |> Enum.filter(&(Risk.estimated_risk_cost(&1) != nil))
    |> Enum.reduce(0, fn risk, acc ->
      acc + Risk.estimated_risk_cost(risk)
    end)
  end

  def sum_up_risk_costs(risks, status) when is_atom(status) do
    risks
    |> Enum.filter(fn risk -> risk.status == status end)
    |> sum_up_risk_costs()
  end

  def sum_up_risk_costs(risks, states) when is_list(states) do
    risks
    |> Enum.filter(fn risk -> Enum.member?(states, risk.status) end)
    |> sum_up_risk_costs()
  end

  def top_10_severity(risks) do
    risks
    |> Enum.sort_by(& &1.severity)
    |> Enum.reverse()
    |> Enum.take(10)
  end

  def top_10_risk_costs(risks) do
    risks
    |> Enum.filter(&(Risk.estimated_risk_cost(&1) != nil))
    |> Enum.sort_by(fn risk -> Risk.estimated_risk_cost(risk) end)
    |> Enum.reverse()
    |> Enum.take(10)
  end

  def max_cost(risks) do
    risks
    |> Enum.filter(&(Risk.estimated_risk_cost(&1) != nil))
    |> Enum.map(&Risk.estimated_risk_cost/1)
    |> max_value()
  end

  def max_frequency(risks) do
    risks
    |> Enum.filter(&(Risk.frequency_per_year(&1) != nil))
    |> Enum.map(&Risk.frequency_per_year/1)
    |> max_value()
  end

  # internal

  defp max_value(values) do
    Enum.max(values, &>=/2, fn -> 0 end)
  end
end
