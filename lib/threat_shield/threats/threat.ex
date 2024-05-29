defmodule ThreatShield.Threats.Threat do
  use Ecto.Schema
  import Ecto.Changeset

  alias ThreatShield.Accounts.Organisation
  alias ThreatShield.Systems.System
  alias ThreatShield.Assets.Asset

  @moduledoc """
  A threat is a potential danger to an organisation, a system or an asset.
  """

  schema "threats" do
    field :description, :string
    field :name, :string

    belongs_to :organisation, Organisation
    belongs_to :system, System
    belongs_to :asset, Asset

    has_many :risks, ThreatShield.Risks.Risk

    timestamps()
  end

  def describe(%__MODULE__{description: description, system: system}) do
    system_description =
      case system do
        nil -> ""
        system -> " It belongs to the following system: " <> System.describe(system)
      end

    description <> system_description
  end

  @doc false
  def changeset(threat, attrs) do
    threat
    |> cast(attrs, [:name, :description, :system_id, :asset_id])
    |> validate_required([:organisation, :name, :description])
    |> validate_length(:name, max: 60)
  end

  def system_name(%__MODULE__{system: %{name: name}}), do: name
  def system_name(_), do: "None"

  import Ecto.Query

  def from() do
    from(e in __MODULE__, as: :threat)
  end

  def get(id) do
    from(e in __MODULE__, as: :threat, where: e.id == ^id)
  end

  def for_user(query, user_id) do
    join(query, :inner, [threat: t], assoc(t, :organisation), as: :organisation)
    |> Organisation.for_user(user_id)
  end

  def for_user(query, user_id, right) do
    join(query, :inner, [threat: t], assoc(t, :organisation), as: :organisation)
    |> Organisation.for_user(user_id, right)
  end

  def join_organisation(query) do
    if has_named_binding?(query, :organisation) do
      query
    else
      join(query, :inner, [threat: t], assoc(t, :organisation), as: :organisation)
    end
  end

  def where_organisation(query, org_id) do
    join_organisation(query)
    |> where([organisation: o], o.id == ^org_id)
  end

  def with_organisation(query) do
    query
    |> preload([organisation: o], organisation: o)
  end

  def preload_membership(query) do
    query
    |> preload([organisation: o, memberships: m], organisation: {o, :memberships})
  end

  def with_organisation_and_risks(query) do
    query
    |> join(:left, [threat: t], assoc(t, :risks), as: :risks)
    |> preload([organisation: o, risks: r], organisation: o, risks: r)
  end

  def with_system(query) do
    query
    |> join(:left, [threat: t], assoc(t, :system), as: :system)
    |> preload([system: s], system: s)
  end

  def with_asset(query) do
    query
    |> join(:left, [threat: t], assoc(t, :asset), as: :asset)
    |> preload([asset: a], asset: a)
  end

  def with_org_systems(query) do
    query
    |> join(:left, [organisation: o], assoc(o, :systems), as: :systems)
    |> preload([organisation: o, systems: s], organisation: {o, systems: s})
  end

  def with_org_assets(query) do
    query
    |> join(:left, [organisation: o], assoc(o, :assets), as: :assets)
    |> preload([organisation: o, assets: a], organisation: {o, assets: a})
  end

  def select(query) do
    select(query, [threat: t], t)
  end
end
