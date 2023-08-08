defmodule ThreatShield.SystemsFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `ThreatShield.Systems` context.
  """

  @doc """
  Generate a system.
  """
  def system_fixture(attrs \\ %{}) do
    {:ok, system} =
      attrs
      |> Enum.into(%{
        attributes: %{},
        name: "some name",
        description: "some description"
      })
      |> ThreatShield.Systems.create_system()

    system
  end
end
