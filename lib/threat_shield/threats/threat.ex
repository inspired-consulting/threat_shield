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

    timestamps()
  end

  @doc false
  def changeset(threat, attrs) do
    threat
    |> cast(attrs, [:description, :is_candidate])
    |> validate_required([:description, :is_candidate, :organisation])
  end

  import Ecto.Query

  def get(id) do
    from(e in __MODULE__, as: :threat, where: e.id == ^id)
  end

  def for_user(query, user_id) do
    join(query, :inner, [threat: t], assoc(t, :organisation), as: :organisation)
    |> Organisation.for_user(user_id)
  end
end
