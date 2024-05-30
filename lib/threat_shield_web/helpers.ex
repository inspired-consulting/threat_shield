defmodule ThreatShieldWeb.Helpers do
  use Phoenix.VerifiedRoutes,
    endpoint: ThreatShieldWeb.Endpoint,
    router: ThreatShieldWeb.Router

  alias ThreatShield.Accounts.Organisation

  import Phoenix.Component
  alias ThreatShieldWeb.Endpoint

  alias ThreatShield.Accounts.Organisation
  alias ThreatShield.Risks.Risk

  @moduledoc """
  Helpers are functions that can be used in your contexts.
  """

  def add_breadcrumbs(socket, url) do
    relevant_url_parts =
      %{
        "organisations" => :organisations,
        "assets" => :assets,
        "systems" => :systems,
        "threats" => :threats,
        "risks" => :risks,
        "mitigations" => :mitigations,
        "members" => :members
      }

    breadcrumbs =
      url
      |> String.replace_prefix(Endpoint.url(), "")
      |> String.split("/")
      |> Enum.map(fn key -> Map.get(relevant_url_parts, key) end)
      |> Enum.filter(&(!is_nil(&1)))

    assign(socket, :breadcrumbs, [:home | breadcrumbs])
  end

  def generate_token() do
    :crypto.strong_rand_bytes(128)
    |> Base.url_encode64(padding: false)
  end

  def get_path_prefix(assigns) do
    case assigns[:system] do
      nil -> "/organisations/#{assigns.organisation.id}"
      system -> "/organisations/#{assigns.organisation.id}/systems/#{system.id}"
    end
  end

  # Time

  def convert_date(date_str) do
    {:ok, result} = Timex.format(date_str, "{0D}.{0M}.{YYYY}")
    result
  end

  def format_datetime(datetime) do
    {:ok, formatted} = Timex.format(datetime, "{YYYY}-{0M}-{0D} - {h24}:{m}:{s}")
    formatted
  end

  # Numbers

  def format_number(nil) do
    "-"
  end

  def format_number(number) do
    number
  end

  def format_monetary_amount(number, currency \\ "EUR")
  def format_monetary_amount(nil, _currency), do: "-"

  def format_monetary_amount(number, currency) do
    "#{format_number(number)} #{currency}"
  end

  def format_percentage(number) when is_number(number) do
    "#{format_number(number)} %"
  end

  def format_percentage(nil), do: "-"
  def format_percentage(number), do: number

  # URLs

  def link_to(%Risk{id: risk_id, threat_id: threat_id}, %Organisation{id: org_id}) do
    ~p"/organisations/#{org_id}/threats/#{threat_id}/risks/#{risk_id}"
  end
end
