defmodule ThreatShield.Quotas.QuotaUsage do
  @moduledoc """
  Quota usage schema. Tracks how much of a quota has been used by an organisation or user.
  """
  use Ecto.Schema
  import Ecto.Changeset

  alias ThreatShield.Accounts.{User, Organisation}

  schema "quota_usages" do
    field :quota_type, :string
    field :amount, :float, default: 0.0
    field :message, :string
    field :timestamp, :utc_datetime_usec, default: Timex.now()

    belongs_to :organisation, Organisation
    belongs_to :user, User
  end

  @doc false
  def changeset(quota_usage, attrs) do
    quota_usage
    |> cast(attrs, [:quota_type, :used, :message, :organisation_id, :user_id])
    |> validate_required([:quota_type, :used])
  end
end
