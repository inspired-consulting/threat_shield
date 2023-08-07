defmodule ThreatShield.OrgansationsFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `ThreatShield.Organsations` context.
  """

  @doc """
  Generate a organisation.
  """
  def organisation_fixture(attrs \\ %{}) do
    {:ok, organisation} =
      attrs
      |> Enum.into(%{
        name: "some name"
      })
      |> ThreatShield.Organsations.create_organisation()

    organisation
  end
end
