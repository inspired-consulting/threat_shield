defmodule ThreatShield.Organisations.Membership do
  use Ecto.Schema
  import Ecto.Changeset

  schema "memberships" do
    field :role, Ecto.Enum, values: [:owner, :editor, :viewer]

    belongs_to :user, ThreatShield.Accounts.User
    belongs_to :organisation, ThreatShield.Organisations.Organisation
  end

  @doc false
  def changeset(membership, attrs) do
    membership
    |> cast(attrs, [:role])
    |> validate_required([:role])
  end

  import Ecto.Query

  def get(id) do
    from(e in __MODULE__, as: :membership, where: e.id == ^id)
  end

  def for_user(query, user_id) do
    query
    |> join(:inner, [membership: m], assoc(m, :organisation), as: :organisation)
    |> join(:inner, [organisation: o], assoc(o, :memberships), as: :org_memberships)
    |> where([org_memberships: o], o.user_id == ^user_id)
  end

  def select(query) do
    select(query, [membership: m], m)
  end
end
