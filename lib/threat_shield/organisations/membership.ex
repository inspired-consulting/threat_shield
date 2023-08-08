defmodule ThreatShield.Organisations.Membership do
  use Ecto.Schema

  schema "memberships" do
    belongs_to :user, ThreatShield.Accounts.User
    belongs_to :organisation, ThreatShield.Organisations.Organisation
  end
end
