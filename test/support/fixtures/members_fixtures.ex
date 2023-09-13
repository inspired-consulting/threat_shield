defmodule ThreatShield.MembersFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `ThreatShield.Members` context.
  """

  @doc """
  Generate a invites.
  """
  def invites_fixture(attrs \\ %{}) do
    {:ok, invites} =
      attrs
      |> Enum.into(%{
        token: "some token",
        email: "some email"
      })
      |> ThreatShield.Members.create_invites()

    invites
  end
end
