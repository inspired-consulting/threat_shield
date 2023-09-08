defmodule ThreatShield.Mitigations.Mitigation do
  alias ThreatShield.Risks.Risk
  use Ecto.Schema
  import Ecto.Changeset

  schema "mitigations" do
    field :name, :string
    field :description, :string
    field :is_implemented, :boolean, default: false

    belongs_to :risk, Risk

    timestamps()
  end

  @doc false
  def changeset(mitigation, attrs) do
    mitigation
    |> cast(attrs, [:name, :description, :is_implemented])
    |> validate_required([:name, :description, :is_implemented])
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

  def select(query) do
    select(query, [mitigation: m], m)
  end
end
