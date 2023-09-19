defmodule ThreatShield.Members.Invite do
  alias ThreatShield.Organisations.Organisation
  use Ecto.Schema
  import Ecto.Changeset

  import ThreatShield.Const.RetentionTimes, only: [invite_lifetime_in_seconds: 0]

  schema "invites" do
    field :token, :string
    field :email, :string

    belongs_to :organisation, ThreatShield.Organisations.Organisation

    timestamps()
  end

  def cutoff_time() do
    NaiveDateTime.utc_now()
    |> NaiveDateTime.add(-invite_lifetime_in_seconds())
  end

  @doc false
  def changeset(invite, attrs) do
    invite
    |> cast(attrs, [:email])
    |> validate_required([:email])
    |> validate_format(:email, ~r/^[^\s]+@[^\s]+$/, message: "must have the @ sign and no spaces")
    |> validate_length(:email, max: 160)
  end

  def generate_url(%__MODULE__{token: token}) do
    ThreatShieldWeb.Endpoint.url() <> "/join/" <> token
  end

  def expiration_point(%__MODULE__{inserted_at: inserted_at}) do
    NaiveDateTime.add(inserted_at, invite_lifetime_in_seconds())
  end

  import Ecto.Query

  def get(id) do
    from(e in __MODULE__, as: :invite, where: e.id == ^id)
  end

  def from() do
    from(e in __MODULE__, as: :invite)
  end

  def for_token(query, token) do
    query
    |> where([invite: i], i.token == ^token)
  end

  def where_expired(query) do
    query
    |> where([invite: i], i.inserted_at < ^cutoff_time())
  end

  def with_time_limit(query) do
    query
    |> where([invite: i], i.inserted_at >= ^cutoff_time())
  end

  def with_organisation(query) do
    query
    |> join(:left, [invite: i], assoc(i, :organisation), as: :organisation)
    |> preload([organisation: o], organisation: o)
  end

  def for_user(query, user_id) do
    query
    |> join(:inner, [invite: i], assoc(i, :organisation), as: :organisation)
    |> Organisation.for_user(user_id)
  end

  def for_user(query, user_id, right) do
    query
    |> join(:inner, [invite: i], assoc(i, :organisation), as: :organisation)
    |> Organisation.for_user(user_id, right)
  end

  def select(query) do
    select(query, [invite: i], i)
  end
end
