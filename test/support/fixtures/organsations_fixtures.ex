defmodule ThreatShield.OrganisationsFixtures do
  @moduledoc """
  This module defines test helpers for creating organisations.
  """

  @doc """
  Generate an organisation.
  """
  alias ThreatShield.Organisations

  def organisation_fixture(user, attrs \\ %{}) do
    {:ok, organisation} =
      attrs
      |> Enum.into(%{
        name: "some name",
        description: "some description"
      })
      |> Organisations.create_organisation(user)

    organisation
  end
end
