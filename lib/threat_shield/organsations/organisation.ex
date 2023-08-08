defmodule ThreatShield.Organsations.Organisation do
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
end
