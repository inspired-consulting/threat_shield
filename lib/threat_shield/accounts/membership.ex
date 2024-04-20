defmodule ThreatShield.Accounts.Membership do
  use Ecto.Schema
  import Ecto.Changeset

  alias ThreatShield.Members.Rights

  schema "memberships" do
    field :role, Ecto.Enum, values: [:owner, :editor, :viewer]

    belongs_to :user, ThreatShield.Accounts.User
    belongs_to :organisation, ThreatShield.Accounts.Organisation
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

  def for_user(user_id) do
    from(e in __MODULE__, as: :membership)
    |> for_user(user_id)
  end

  def for_user(query, user_id) do
    query
    |> join(:inner, [membership: m], assoc(m, :organisation), as: :organisation)
    |> join(:inner, [organisation: o], assoc(o, :memberships), as: :ac_org_memberships)
    |> where([ac_org_memberships: o], o.user_id == ^user_id)
  end

  def for_user(query, user_id, right) do
    query
    |> join(:inner, [membership: m], assoc(m, :organisation), as: :organisation)
    |> join(:inner, [organisation: o], assoc(o, :memberships), as: :ac_org_memberships)
    |> where([ac_org_memberships: m], m.user_id == ^user_id)
    |> where([ac_org_memberships: m], m.role in ^Rights.get_authorised_roles(right))
  end

  def preload_org_memberships(query) do
    query
    |> join(:inner, [organisation: o], assoc(o, :memberships), as: :org_memberships)
    |> preload([organisation: o, org_memberships: m], organisation: {o, memberships: m})
  end

  def select(query) do
    select(query, [membership: m], m)
  end
end
