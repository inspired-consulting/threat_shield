defmodule ThreatShield.Organisations.Organisation do
  use Ecto.Schema
  import Ecto.Changeset

  schema "organisations" do
    field :name, :string
    field :location, :string
    field :attributes, :map

    many_to_many :users, ThreatShield.Accounts.User, join_through: "memberships"
    has_many :systems, ThreatShield.Systems.System
    has_many :threats, ThreatShield.Threats.Threat
    has_many :assets, ThreatShield.Assets.Asset

    timestamps()
  end

  @doc false
  def changeset(organisation, attrs) do
    organisation
    |> cast(attrs, [
      :name,
      :location,
      :attributes
    ])
    |> validate_required([:name])
  end

  def attribute_keys() do
    ["Industry", "Legal Form", "Type of Business", "Size", "Financial Information"]
  end

  def list_system_options(%__MODULE__{systems: systems}) do
    [{"None", nil} | Enum.map(systems, fn s -> {s.name, s.id} end)]
  end

  import Ecto.Query

  def get(id) do
    from(e in __MODULE__, as: :organisation, where: e.id == ^id)
  end

  def for_user(query, user_id) do
    query
    |> join(:inner, [organisation: o], assoc(o, :users), as: :user)
    |> where([user: u], u.id == ^user_id)
  end
end
