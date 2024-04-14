defmodule ThreatShield.Systems.System do
  use Ecto.Schema
  import Ecto.Changeset

  alias ThreatShield.Accounts.Organisation
  alias ThreatShield.DynamicAttribute

  @attributes [
    %DynamicAttribute{
      name: "Database",
      description: "Examples of databases are Postgres, MySQL, Neo4j."
    },
    %DynamicAttribute{
      name: "Application Framework",
      description: "Examples of application frameworks are Django, Ruby on Rails, Flutter."
    },
    %DynamicAttribute{
      name: "Authentication Framework",
      description: "Examples of authentication frameworks are Passport.js, Okta, Keycloak."
    }
  ]

  schema "systems" do
    field :attributes, :map
    field :name, :string
    field :description, :string
    belongs_to :organisation, ThreatShield.Accounts.Organisation

    has_many :threats, ThreatShield.Threats.Threat
    has_many :assets, ThreatShield.Assets.Asset

    timestamps()
  end

  @doc false
  def changeset(system, attrs) do
    system
    |> cast(attrs, [:name, :description, :attributes])
    |> validate_required([:name, :description])
    |> validate_length(:name, max: 60)
  end

  def attributes() do
    @attributes
  end

  def describe(%__MODULE__{name: name, description: description, attributes: attributes}) do
    name_string = """
    The name of the system is "#{name}". It can be described as follows: "#{description}".
    """

    attribute_values =
      "The system has the following properties:\n" <>
        (attributes
         |> Enum.filter(fn {_, val} -> val != "" end)
         |> Enum.map_join("\n", fn {key, val} -> ~s{"#{key}: ", "#{val}"} end))

    attribute_description =
      "The system properties have the following user-facing descriptions:\n" <>
        (@attributes
         |> Enum.map_join("\n", fn d -> ~s{"#{d.name}: ", "#{d.description}"} end))

    [name_string, attribute_values, attribute_description]
    |> Enum.join(" ")
  end

  import Ecto.Query

  def get(id) do
    from(e in __MODULE__, as: :system, where: e.id == ^id)
  end

  def for_user(query, user_id) do
    query
    |> join(:inner, [system: s], assoc(s, :organisation), as: :organisation)
    |> Organisation.for_user(user_id)
  end

  def for_user(query, user_id, right) do
    query
    |> join(:inner, [system: s], assoc(s, :organisation), as: :organisation)
    |> Organisation.for_user(user_id, right)
  end

  def preload_organisation(query) do
    query
    |> preload([organisation: o], organisation: o)
  end

  def with_org_systems(query) do
    query
    |> join(:left, [organisation: o], assoc(o, :systems), as: :org_systems)
    |> preload([organisation: o, org_systems: s], organisation: {o, :systems})
  end

  def preload_membership(query) do
    query
    |> preload([organisation: o, memberships: m], organisation: {o, :memberships})
  end

  def with_assets(query) do
    query
    |> join(:left, [system: s], assoc(s, :assets), as: :assets)
    |> preload([assets: a], assets: a)
  end

  def with_threats(query) do
    query
    |> join(:left, [system: s], assoc(s, :threats), as: :threats)
    |> preload([threats: t], threats: t)
  end

  def select(query) do
    select(query, [system: s], s)
  end
end
