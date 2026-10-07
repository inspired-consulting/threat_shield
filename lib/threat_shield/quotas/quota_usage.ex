defmodule ThreatShield.Quotas.QuotaUsage do
  @moduledoc """
  Quota usage schema. Tracks how much of a quota has been used by an organisation or user.
  """
  use Ecto.Schema

  alias ThreatShield.Accounts.{User, Organisation}

  schema "quota_usages" do
    field :quota_type, :string
    field :amount, :float, default: 0.0
    field :message, :string
    field :timestamp, :utc_datetime_usec

    belongs_to :organisation, Organisation
    belongs_to :user, User
  end
end
