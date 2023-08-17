defmodule ThreatShield.Systems.System do
  use Ecto.Schema
  import Ecto.Changeset

  alias ThreatShield.Organisations.Organisation

  schema "systems" do
    field :attributes, :string
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

  import Ecto.Query

  def get(id) do
    from(e in __MODULE__, as: :system, where: e.id == ^id)
  end

  def for_user(query, user_id) do
    join(query, :inner, [system: s], assoc(s, :organisation), as: :organisation)
    |> Organisation.for_user(user_id)
  end
end
