defmodule ThreatShield.Repo do
  use Ecto.Repo,
    otp_app: :threat_shield,
    adapter: Ecto.Adapters.Postgres

  @doc """
  Inserts the changeset inside a transaction. On a validation error, the
  transaction is rolled back with the changeset, so that `transaction/1` returns
  `{:error, changeset}`.
  """
  def insert_or_rollback(changeset) do
    case insert(changeset) do
      {:ok, struct} -> struct
      {:error, changeset} -> rollback(changeset)
    end
  end

  @doc """
  Updates the changeset inside a transaction. See `insert_or_rollback/1`.
  """
  def update_or_rollback(changeset) do
    case update(changeset) do
      {:ok, struct} -> struct
      {:error, changeset} -> rollback(changeset)
    end
  end
end
