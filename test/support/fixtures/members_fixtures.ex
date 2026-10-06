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

  @doc """
  Adds the user to the organisation with the given role.
  """
  def membership_fixture(organisation, user, role) do
    %ThreatShield.Accounts.Membership{organisation: organisation, user: user, role: role}
    |> ThreatShield.Repo.insert!()
  end
end
