defmodule ThreatShield.Repo do
  use Ecto.Repo,
    otp_app: :threat_shield,
    adapter: Ecto.Adapters.Postgres
end
