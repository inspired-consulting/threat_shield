defmodule ThreatShield.Organisations.Organisation do
  use Ecto.Schema
  import Ecto.Changeset

  schema "organisations" do
    field :name, :string
    field :industry, :string
    field :legal_form, :string
    field :location, :string
    field :type_of_business, :string
    field :size, :integer
    field :financial_information, :string

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
      :industry,
      :legal_form,
      :location,
      :type_of_business,
      :size,
      :financial_information
    ])
    |> validate_required([:name])
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
