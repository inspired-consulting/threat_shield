defmodule ThreatShield.Accounts.Organisation do
  use Ecto.Schema
  import Ecto.Changeset

  alias ThreatShield.Systems.System
  alias ThreatShield.Accounts.User
  alias ThreatShield.DynamicAttribute

  import ThreatShield.Members.Rights, only: [get_authorised_roles: 1]

  @attributes [
    %DynamicAttribute{
      name: "Industry",
      description: "Examples of industry are financial services, health, IT."
    },
    %DynamicAttribute{
      name: "Legal Form",
      description: "Examples of legal form are LLC, Nonprofit, B Corps."
    },
    %DynamicAttribute{
      name: "Size",
      description: "Examples are small, medium and large.",
      sample_values: ["small", "medium", "large", "global"]
    },
    %DynamicAttribute{
      name: "Work from home regime",
      description: "Examples are fully remote, in-office and hybrid."
    }
  ]

  schema "organisations" do
    field :name, :string
    field :location, :string
    field :attributes, :map
    field :quotas, :map, default: %{ai_requests_per_month: 100}

    many_to_many :users, ThreatShield.Accounts.User, join_through: "memberships"

    has_many :memberships, ThreatShield.Accounts.Membership
    has_many :systems, ThreatShield.Systems.System
    has_many :threats, ThreatShield.Threats.Threat
    has_many :assets, ThreatShield.Assets.Asset
    has_many :invites, ThreatShield.Members.Invite

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

  def attributes() do
    @attributes
  end

  def get_membership(%__MODULE__{memberships: memberships}, %User{id: user_id}) do
    Enum.find(memberships, fn m -> m.user_id == user_id end)
  end

  def list_system_options(%__MODULE__{systems: systems}) do
    [{"None", nil} | Enum.map(systems, fn s -> {s.name, s.id} end)]
  end

  def list_asset_options(%__MODULE__{assets: assets}) do
    [{"None", nil} | Enum.map(assets, fn a -> {a.name, a.id} end)]
  end

  def describe(%__MODULE__{name: name, attributes: attributes, systems: systems}) do
    name_string = """
    The name of the organisation is "#{name}".
    """

    attribute_values =
      "The organisation has the following properties:\n" <>
        (attributes
         |> Enum.filter(fn {_, val} -> val != "" end)
         |> Enum.map_join("\n", fn {key, val} -> ~s{"#{key}: ", "#{val}"} end))

    attribute_description =
      "The organisation properties have the following user-facing descriptions:\n" <>
        (@attributes
         |> Enum.map_join("\n", fn d -> ~s{"#{d.name}: ", "#{d.description}"} end))

    system_description =
      "It has the following systems:\n" <>
        (systems
         |> Enum.map(fn sys -> System.describe(sys) end)
         |> Enum.join("\n"))

    [name_string, attribute_values, attribute_description, system_description]
    |> Enum.join(" ")
  end

  import Ecto.Query

  def get(id) do
    from(o in __MODULE__, as: :organisation, where: o.id == ^id)
  end

  def for_user(query, user_id) do
    query
    |> join(:inner, [organisation: o], assoc(o, :memberships), as: :memberships)
    |> join(:inner, [memberships: m], assoc(m, :user), as: :user)
    |> where([user: u], u.id == ^user_id)
  end

  def preload_membership(query) do
    query
    |> preload([memberships: m], memberships: m)
  end

  def for_user(query, user_id, right) do
    query
    |> join(:inner, [organisation: o], assoc(o, :memberships), as: :memberships)
    |> join(:inner, [memberships: m], assoc(m, :user), as: :user)
    |> where([user: u], u.id == ^user_id)
    |> where([memberships: m], m.role in ^get_authorised_roles(right))
  end

  def with_threats(query) do
    query
    |> join(:left, [organisation: o], assoc(o, :threats), as: :threats)
    |> join(:left, [threats: t], assoc(t, :system), as: :threat_system)
    |> join(:left, [threats: t], assoc(t, :asset), as: :threat_asset)
    |> preload([threats: t, threat_system: s], threats: {t, system: s})
    |> preload([threats: t, threat_asset: a], threats: {t, asset: a})
  end

  def with_risks(query) do
    query
    |> join(:left, [threats: t], assoc(t, :risks), as: :risks)
    |> preload([threats: t, risks: r], threats: {t, risks: r})
  end

  def with_mitigations(query) do
    query
    |> join(:left, [risks: r], assoc(r, :mitigations), as: :mitigations)
    |> preload([threats: t, mitigations: m, risks: r], threats: {t, risks: {r, mitigations: m}})
  end

  def with_systems(query) do
    query
    |> join(:left, [organisation: o], assoc(o, :systems), as: :systems)
    |> preload([systems: s], systems: s)
  end

  def with_assets(query) do
    query
    |> join(:left, [organisation: o], assoc(o, :assets), as: :assets)
    |> join(:left, [assets: a], assoc(a, :system), as: :asset_systems)
    |> preload([assets: a, asset_systems: s], assets: {a, system: s})
  end

  def with_memberships(query) do
    query
    |> join(:left, [organisation: o], assoc(o, :memberships), as: :all_memberships)
    |> join(:left, [all_memberships: m], assoc(m, :user), as: :all_membership_users)
    |> preload([all_memberships: m, all_membership_users: u], memberships: {m, user: u})
  end

  def with_invites(query) do
    query
    |> join(:left, [organisation: o], assoc(o, :invites), as: :invites)
    |> preload([invites: i], invites: i)
  end

  def select(query) do
    select(query, [organisation: o], o)
  end
end
