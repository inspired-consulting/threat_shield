defmodule ThreatShield.Risks.Risk do
  use Ecto.Schema
  import Ecto.Changeset

  alias ThreatShield.Threats.Threat
  alias ThreatShield.Mitigations.Mitigation

  @moduledoc """
  A risk is a combination of a threat and an asset. It is the result of a risk assessment.
  0.0 - Insignificant: This label suggests that the risk has such a negligible impact that it can be considered as having no real effect or importance.
  1.0 - Very Low: Minimal impact and likelihood; may be easily mitigated or ignored.
  2.0 - Low: Slight impact; should be manageable with standard risk mitigation strategies.
  3.0 - Moderate: Noticeable impact; requires active management and monitoring.
  4.0 - High: Significant impact; high priority for mitigation and may require substantial resources.
  5.0 - Catastrophic/Extremely High: Critical impact; immediate and comprehensive action required, possibly involving major resource allocation or changes.
  """

  schema "risks" do
    field :name, :string
    field :description, :string
    field :estimated_cost, :integer
    field :probability, :float
    field :severity, :float

    field :status, Ecto.Enum,
      values: [
        :identified,
        :assessed,
        :mitigation_planned,
        :mitigation_in_progress,
        :mitigated,
        :monitored,
        :closed,
        :reopened
      ],
      default: :identified

    belongs_to :threat, Threat

    has_many :mitigations, Mitigation

    timestamps()
  end

  @fields ~w(name description estimated_cost probability severity status)a
  @valid_states ~w(identified assessed mitigation_planned mitigation_in_progress mitigated monitored closed reopened)a

  def describe(%__MODULE__{description: description, threat: threat}) do
    description <> " " <> Threat.describe(threat)
  end

  def valid_states(), do: @valid_states

  @doc false
  def changeset(risk, attrs) do
    risk
    |> cast(attrs, @fields)
    |> validate_required([:name, :description])
    |> validate_length(:name, max: 60)
  end

  def estimated_risk_cost(%{estimated_cost: estimated_cost, probability: probability}),
    do: estimated_risk_cost(estimated_cost, probability)

  def estimated_risk_cost(estimated_cost, probability)
      when is_number(estimated_cost) and is_number(probability) do
    round(estimated_cost * probability / 100)
  end

  def estimated_risk_cost(_estimated_cost, _probability), do: nil

  import Ecto.Query

  def get(id) do
    from(e in __MODULE__, as: :risk, where: e.id == ^id)
  end

  def for_user(query, user_id) do
    join(query, :inner, [risk: r], assoc(r, :threat), as: :threat)
    |> Threat.for_user(user_id)
  end

  def for_user(query, user_id, right) do
    join(query, :inner, [risk: r], assoc(r, :threat), as: :threat)
    |> Threat.for_user(user_id, right)
  end

  def preload_threat(query) do
    query
    |> preload([threat: t], threat: t)
    |> join(:left, [threat: t], assoc(t, :system), as: :threat_system)
    |> preload([threat: t, threat_system: s], threat: {t, system: s})
  end

  def preload_membership(query) do
    query
    |> preload([threat: t, organisation: o, memberships: m],
      threat: {t, organisation: {o, :memberships}}
    )
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
