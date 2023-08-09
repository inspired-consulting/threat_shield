defmodule ThreatShield.Systems.System do
  use Ecto.Schema
  import Ecto.Changeset

  schema "systems" do
    field :attributes, :map
    field :name, :string
    field :description, :string
    belongs_to :organisation, ThreatShield.Organisations.Organisation
    has_many :threats, ThreatShield.Threats.Threat

    timestamps()
  end

  @doc false
  def changeset(system, attrs) do
    system
    |> cast(attrs, [:name, :description, :attributes])
    |> validate_required([:name, :description])
  end
end
