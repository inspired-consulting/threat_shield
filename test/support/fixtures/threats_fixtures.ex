defmodule ThreatShield.ThreatsFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `ThreatShield.Threats` context.
  """

  @doc """
  Generate a threat.
  """
  def threat_fixture(attrs \\ %{}) do
    {:ok, threat} =
      attrs
      |> Enum.into(%{
        description: "some description",
        is_candidate: true
      })
      |> ThreatShield.Threats.create_threat()

    threat
  end
end
