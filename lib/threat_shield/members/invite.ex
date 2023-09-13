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
end
