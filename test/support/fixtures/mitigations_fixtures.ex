defmodule ThreatShield.MitigationsFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `ThreatShield.Mitigations` context.
  """

  @doc """
  Generate a mitigation.
  """
  def mitigation_fixture(user, risk, attrs \\ %{}) do
    attrs =
      attrs
      |> Enum.into(%{
        name: "some name",
        description: "some description",
        is_implemented: true
      })

    {:ok, mitigation} = ThreatShield.Mitigations.create_mitigation(user, risk, attrs)

    mitigation
  end
end
