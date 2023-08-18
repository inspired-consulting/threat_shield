defmodule ThreatShield.Threats.Threat do
  use Ecto.Schema
  import Ecto.Changeset

  alias ThreatShield.Systems.System
  alias ThreatShield.Organisations.Organisation

  schema "threats" do
    field :description, :string
    field :is_candidate, :boolean, default: false

    belongs_to :system, System
    belongs_to :organisation, Organisation

    has_many :risks, ThreatShield.Risks.Risk

    timestamps()
  end

  @doc false
  def changeset(threat, attrs) do
    threat
    |> cast(attrs, [:description, :is_candidate, :system_id])
    |> validate_required([:description, :is_candidate, :organisation])
  end

  def system_name(%__MODULE__{system: %{name: name}}), do: name
  def system_name(_), do: "None"

  import Ecto.Query

  def get(id) do
    from(e in __MODULE__, as: :threat, where: e.id == ^id)
  end

  def for_user(query, user_id) do
    join(query, :inner, [threat: t], assoc(t, :organisation), as: :organisation)
    |> Organisation.for_user(user_id)
  end

  def where_organisation(query, org_id) do
    where(query, [organisation: o], o.id == ^org_id)
  end

  def with_organisation_and_risks(query) do
    query
    |> join(:left, [threat: t], assoc(t, :risks), as: :risks)
    |> preload([organisation: o, risks: r], organisation: o, risks: r)
  end
end
