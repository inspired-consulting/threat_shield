defmodule ThreatShield.Mitigations.Mitigation do
  alias ThreatShield.Risks.Risk
  use Ecto.Schema
  import Ecto.Changeset

  schema "mitigations" do
    field :name, :string
    field :description, :string
    field :issue_link, :string

    field :status, Ecto.Enum,
      values: [:open, :in_progress, :implemented, :verified, :failed, :deferred, :obsolete],
      default: :open

    field :is_implemented, :boolean, default: false
    field :implementation_notes, :string
    field :implementation_date, :date

    field :verification_date, :date
    field :verification_method, :string
    field :verification_result, :string

    belongs_to :risk, Risk

    timestamps()
  end

  @fields ~w(name description issue_link status is_implemented implementation_notes implementation_date verification_date verification_method verification_result risk_id)a

  @doc false
  def changeset(mitigation, attrs) do
    mitigation
    |> cast(attrs, @fields)
    |> validate_required([:name, :description, :is_implemented])
    |> validate_length(:name, max: 60)
  end

  import Ecto.Query

  def get(id) do
    from(e in __MODULE__, as: :mitigation, where: e.id == ^id)
  end

  def for_user(query, user_id) do
    query
    |> join(:inner, [mitigation: m], assoc(m, :risk), as: :risk)
    |> Risk.for_user(user_id)
  end

  def for_user(query, user_id, right) do
    query
    |> join(:inner, [mitigation: m], assoc(m, :risk), as: :risk)
    |> Risk.for_user(user_id, right)
  end

  def preload_risk(query) do
    query
    |> preload([risk: r], risk: r)
  end

  def preload_full_threat(query) do
    query
    |> join(:left, [threat: t], assoc(t, :system), as: :threat_system)
    |> join(:left, [threat: t], assoc(t, :organisation), as: :threat_organisation)
    |> preload([risk: r, threat: t, threat_system: s], risk: {r, threat: {t, system: s}})
    |> preload([risk: r, threat: t, threat_organisation: o],
      risk: {r, threat: {t, organisation: o}}
    )
  end

  def preload_membership(query) do
    query
    |> preload([risk: r, threat: t, threat_organisation: o, memberships: m],
      risk: {r, threat: {t, organisation: {o, :memberships}}}
    )
  end

  def select(query) do
    select(query, [mitigation: m], m)
  end
end
