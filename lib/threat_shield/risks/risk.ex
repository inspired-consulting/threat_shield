defmodule ThreatShield.Risks.Risk do
  use Ecto.Schema
  import Ecto.Changeset

  alias ThreatShield.Threats.Threat

  schema "risks" do
    field :name, :string
    field :description, :string
    field :estimated_cost, :integer
    field :probability, :float
    field :is_candidate, :boolean, default: false

    belongs_to :threat, Threat

    timestamps()
  end

  @doc false
  def changeset(risk, attrs) do
    risk
    |> cast(attrs, [:name, :description, :estimated_cost, :probability])
    |> validate_required([:name, :description])
  end
end
