defmodule ThreatShield.Risks.Risk do
  use Ecto.Schema
  import Ecto.Changeset

  alias ThreatShield.Threats.Threat
  alias ThreatShield.Mitigations.Mitigation

  schema "risks" do
    field :name, :string
    field :description, :string
    field :estimated_cost, :integer
    field :probability, :float

    belongs_to :threat, Threat

    has_many :mitigations, Mitigation

    timestamps()
  end

  @doc false
  def changeset(risk, attrs) do
    risk
    |> cast(attrs, [:name, :description, :estimated_cost, :probability])
    |> validate_required([:name, :description])
  end

  import Ecto.Query

  def get(id) do
    from(e in __MODULE__, as: :risk, where: e.id == ^id)
  end

  def for_user(query, user_id) do
    join(query, :inner, [risk: r], assoc(r, :threat), as: :threat)
    |> Threat.for_user(user_id)
  end

  def with_mitigations(query) do
    query
    |> join(:left, [risk: r], assoc(r, :mitigations), as: :mitigations)
    |> preload([mitigations: m], mitigations: m)
  end

  def with_organisation(query) do
    query
    |> preload([threat: t, organisation: o], threat: {t, organisation: o})
  end

  def select(query) do
    select(query, [risk: r], r)
  end
end
