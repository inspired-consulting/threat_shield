defmodule ThreatShield.Organsations.Organisation do
  use Ecto.Schema
  import Ecto.Changeset

  schema "organisations" do
    field :name, :string

    timestamps()
  end

  @doc false
  def changeset(organisation, attrs) do
    organisation
    |> cast(attrs, [:name])
    |> validate_required([:name])
  end
end
