defmodule ThreatShield.Accounts.Organsation do
  use Ecto.Schema
  import Ecto.Changeset

  schema "organisations" do
    field :name, :string

    many_to_many :users, ThreatShield.Accounts.User, join_through: "memberships"

    timestamps()
  end

  @doc false
  def changeset(organsation, attrs) do
    organsation
    |> cast(attrs, [:name])
    |> validate_required([:name])
  end
end
