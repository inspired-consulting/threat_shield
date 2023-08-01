defmodule TreatShield.Repo do
  use Ecto.Repo,
    otp_app: :treat_shield,
    adapter: Ecto.Adapters.Postgres
end
