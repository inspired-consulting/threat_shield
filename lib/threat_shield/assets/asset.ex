defmodule ThreatShield.Assets.Asset do
  use Ecto.Schema
  import Ecto.Changeset

  alias ThreatShield.Systems.System
  alias ThreatShield.Organisations.Organisation

  schema "assets" do
    field :name, :string
    field :description, :string
    field :criticality_loss, :float
    field :criticality_theft, :float
    field :criticality_publication, :float
    field :criticality_overall, :float
    belongs_to :system, System
    belongs_to :organisation, Organisation
    timestamps()
  end

  @fields ~w(name description system_id criticality_loss criticality_theft criticality_publication criticality_overall)a

  @doc false
  def changeset(asset, attrs) do
    asset
    |> cast(attrs, @fields)
    |> validate_required([:name, :description, :organisation])
    |> validate_length(:name, max: 60)
  end

  def list_system_options(%Organisation{systems: systems}) do
    [{"None", nil} | Enum.map(systems, fn s -> {s.name, s.id} end)]
  end

  def system_name(%__MODULE__{system: %{name: name}}), do: name
  def system_name(_), do: "None"

  def calc_overall_criticality(%__MODULE__{
        criticality_loss: loss,
        criticality_theft: theft,
        criticality_publication: publication,
        criticality_overall: overall
      }) do
    if not is_nil(loss) and not is_nil(theft) and not is_nil(publication) do
      calc = (loss + theft + publication) / 3
      max(calc, overall)
    else
      overall
    end
  end

  import Ecto.Query

  def get(id) do
    from(e in __MODULE__, as: :asset, where: e.id == ^id)
  end

  def for_user(query, user_id) do
    join(query, :inner, [asset: t], assoc(t, :organisation), as: :organisation)
    |> Organisation.for_user(user_id)
  end

  def for_user(query, user_id, right) do
    join(query, :inner, [asset: t], assoc(t, :organisation), as: :organisation)
    |> Organisation.for_user(user_id, right)
  end

  def preload_organisation(query) do
    query
    |> preload([organisation: o], organisation: o)
  end

  def preload_membership(query) do
    query
    |> preload([organisation: o, memberships: m], organisation: {o, :memberships})
  end

  def with_org_systems(query) do
    query
    |> join(:left, [organisation: o], assoc(o, :systems), as: :org_systems)
    |> preload([organisation: o, org_systems: s], organisation: {o, systems: s})
  end

  def with_system(query) do
    query
    |> join(:left, [asset: a], assoc(a, :system), as: :system)
    |> preload([system: s], system: s)
  end

  def select(query) do
    query
    |> select([asset: a], a)
  end
end
