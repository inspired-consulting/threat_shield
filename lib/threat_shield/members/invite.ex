defmodule ThreatShield.Members.Invite do
  use Ecto.Schema
  import Ecto.Changeset

  schema "invites" do
    field :token, :string
    field :email, :string

    belongs_to :organisation, ThreatShield.Organisations.Organisation

    timestamps()
  end

  @doc false
  def changeset(invite, attrs) do
    invite
    |> cast(attrs, [:email])
    |> validate_required([:email])
    |> validate_format(:email, ~r/^[^\s]+@[^\s]+$/, message: "must have the @ sign and no spaces")
    |> validate_length(:email, max: 160)
  end

  import Ecto.Query

  def get(id) do
    from(e in __MODULE__, as: :invite, where: e.id == ^id)
  end

  def for_user(query, user_id) do
    query
    |> join(:inner, [invite: i], assoc(i, :organisation), as: :organisation)
    |> join(:inner, [organisation: o], assoc(o, :users), as: :users)
    |> where([users: u], u.id == ^user_id)
  end

  def select(query) do
    select(query, [invite: i], i)
  end
end
