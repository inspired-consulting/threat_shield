defmodule ThreatShield.MitigationsFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `ThreatShield.Mitigations` context.
  """

  @doc """
  Generate a mitigation.
  """
  def mitigation_fixture(attrs \\ %{}) do
    {:ok, mitigation} =
      attrs
      |> Enum.into(%{
        name: "some name",
        description: "some description",
        is_implemented: true
      })
      |> ThreatShield.Mitigations.create_mitigation()

    mitigation
  end
end
