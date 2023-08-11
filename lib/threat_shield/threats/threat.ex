defmodule ThreatShield.Threats.Threat do
  use Ecto.Schema
  import Ecto.Changeset

  alias ThreatShield.Systems.System
  alias ThreatShield.Organisations.Organisation

  schema "threats" do
    field :description, :string
    field :is_accepted, :boolean, default: false

    belongs_to :system, System
    belongs_to :organisation, Organisation

    timestamps()
  end

  @doc false
  def changeset(threat, attrs) do
    threat
    |> cast(attrs, [:description, :is_accepted])
    |> validate_required([:description, :is_accepted, :organisation])
  end
end
