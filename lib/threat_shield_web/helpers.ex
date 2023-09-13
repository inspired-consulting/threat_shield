defmodule ThreatShieldWeb.Helpers do
  import Phoenix.Component
  alias ThreatShieldWeb.Endpoint

  @moduledoc """
  Helpers are functions that can be used in your contexts.
  """

  def get_git_release_tag() do
    {output, status} = System.cmd("git", ["describe", "--tags"])

    case status do
      0 ->
        [first, _, _] = String.split(output, "-")
        first

      _ ->
        ""
    end
  end

  def add_breadcrumbs(socket, url) do
    breadcrumbs =
      url
      |> String.replace_prefix(Endpoint.url(), "")
      |> String.split("/")
      |> Enum.map(fn key -> Map.get(ThreatShield.Breadcrumbs.relevant_url_parts(), key) end)
      |> Enum.filter(&(!is_nil(&1)))

    assign(socket, :breadcrumbs, [:home | breadcrumbs])
  end
end
