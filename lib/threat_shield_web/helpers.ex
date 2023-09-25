defmodule ThreatShieldWeb.Helpers do
  import Phoenix.Component
  alias ThreatShieldWeb.Endpoint

  @moduledoc """
  Helpers are functions that can be used in your contexts.
  """

  def add_breadcrumbs(socket, url) do
    breadcrumbs =
      url
      |> String.replace_prefix(Endpoint.url(), "")
      |> String.split("/")
      |> Enum.map(fn key -> Map.get(ThreatShield.Breadcrumbs.relevant_url_parts(), key) end)
      |> Enum.filter(&(!is_nil(&1)))

    assign(socket, :breadcrumbs, [:home | breadcrumbs])
  end

  def generate_token() do
    :crypto.strong_rand_bytes(128)
    |> Base.url_encode64(padding: false)
  end

  def get_path_prefix(assigns) do
    if assigns.called_via_system do
      case assigns[:system] do
        nil -> "/organisations/#{assigns.organisation.id}"
        system -> "/organisations/#{assigns.organisation.id}/systems/#{system.id}"
      end
    else
      "/organisations/#{assigns.organisation.id}"
    end
  end
end
