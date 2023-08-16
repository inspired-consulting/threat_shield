defmodule ThreatShield.AssetsFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `ThreatShield.Assets` context.
  """

  @doc """
  Generate a asset.
  """
  def asset_fixture(attrs \\ %{}) do
    {:ok, asset} =
      attrs
      |> Enum.into(%{
        is_candidate: 42,
        description: "some description"
      })
      |> ThreatShield.Assets.create_asset()

    asset
  end
end
