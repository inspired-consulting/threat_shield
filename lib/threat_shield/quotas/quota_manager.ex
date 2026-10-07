defmodule ThreatShield.Quotas.QuotaManager do
  @moduledoc """
  Responsible for managing quotas for organisations and users.
  """

  import Ecto.Query, warn: false

  alias ThreatShield.Quotas.QuotaUsage
  alias ThreatShield.Repo

  alias ThreatShield.Accounts.{User, Organisation}

  def get_usage(%Organisation{} = org, quota_type) do
    start = start_time(quota_type)

    query =
      from q in QuotaUsage,
        where:
          q.organisation_id == ^org.id and q.quota_type == ^quota_type and q.timestamp >= ^start

    Repo.aggregate(query, :sum, :amount) || 0.0
  end

  def check_quota(%Organisation{} = org, quota_type, amount \\ 1.0) do
    already_used = get_usage(org, quota_type)
    quota = org.quotas[quota_type] || 0.0

    if already_used + amount > quota do
      {:error, :quota_exceeded}
    else
      {:ok, :quota_available}
    end
  end

  def add_usage(%Organisation{} = org, %User{} = user, quota_type, amount, message \\ nil) do
    %QuotaUsage{
      organisation: org,
      user: user,
      quota_type: quota_type,
      amount: amount,
      message: message,
      timestamp: DateTime.utc_now()
    }
    |> Repo.insert()
  end

  defp start_time(quota_type) when is_atom(quota_type) do
    case quota_type do
      :ai_requests_per_month -> Timex.shift(Timex.now(), months: -1)
      _ -> Timex.beginning_of_day(Timex.now())
    end
  end

  defp start_time(quota_type) when is_binary(quota_type) do
    start_time(String.to_existing_atom(quota_type))
  end
end
