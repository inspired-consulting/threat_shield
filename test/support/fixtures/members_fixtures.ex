defmodule ThreatShield.MembersFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `ThreatShield.Members` context.
  """

  @doc """
  Generate a invites.
  """
  def invites_fixture(user, attrs \\ %{}) do
    attrs =
      attrs
      |> Enum.into(%{
        token: "some token",
        email: "some email"
      })

    {:ok, invites} = ThreatShield.Members.create_invite(user, attrs)

    invites
  end
end
