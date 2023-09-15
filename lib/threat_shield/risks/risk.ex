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

  def describe(%__MODULE__{description: description, threat: threat}) do
    description <> " " <> Threat.describe(threat)
  end

  @doc false
  def changeset(risk, attrs) do
    risk
    |> cast(attrs, [:name, :description, :estimated_cost, :probability])
    |> validate_required([:name, :description])
    |> validate_length(:name, max: 60)
  end

  import Ecto.Query

  def get(id) do
    from(e in __MODULE__, as: :risk, where: e.id == ^id)
  end

  def for_user(query, user_id) do
    join(query, :inner, [risk: r], assoc(r, :threat), as: :threat)
    |> Threat.for_user(user_id)
  end

  def preload_threat(query) do
    query
    |> preload([threat: t], threat: t)
    |> join(:left, [threat: t], assoc(t, :system), as: :threat_system)
    |> preload([threat: t, threat_system: s], threat: {t, system: s})
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

  def with_org_systems(query) do
    query
    |> join(:left, [organisation: o], assoc(o, :systems), as: :systems)
    |> preload([threat: t, organisation: o, systems: s],
      threat: {t, organisation: {o, systems: s}}
    )
  end

  def select(query) do
    select(query, [risk: r], r)
  end
end
