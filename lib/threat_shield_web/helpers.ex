defmodule ThreatShieldWeb.Helpers do
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
end
