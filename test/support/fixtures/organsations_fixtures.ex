defmodule ThreatShield.OrganisationsFixtures do
  @moduledoc """
  This module defines test helpers for creating organisations.
  """

  @doc """
  Generate an organisation.
  """
  def organisation_fixture(user, attrs \\ %{}) do
    {:ok, organisation} =
      attrs
      |> Enum.into(%{
        name: "some name"
      })
      |> ThreatShield.Organisations.create_organisation(user)

    organisation
  end
end
