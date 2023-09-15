defmodule ThreatShield.AssetsFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `ThreatShield.Assets` context.
  """

  @doc """
  Generate a asset.
  """
  def asset_fixture(user, organisation, attrs \\ %{}) do
    default_attrs = %{
      name: "some name",
      description: "some description",
      organisation: "some organisation"
    }

    merged_attrs = Map.merge(default_attrs, attrs)

    {:ok, asset} = ThreatShield.Assets.create_asset(user, organisation, merged_attrs)
    asset
  end
end
