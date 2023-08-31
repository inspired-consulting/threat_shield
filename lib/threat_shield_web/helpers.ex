defmodule ThreatShieldWeb.Helpers do
  @moduledoc """
  Helpers are functions that can be used in your contexts.
  """

  # get the latest git release tag:
  def get_git_release_tag() do
    {output, status} = System.cmd("git", ["describe", "--tags"])

    case status do
      0 ->
        # The command was successful, so the output contains the tag
        String.trim(output)

      _ ->
        # The command failed, so return "unknown"
        "unknown"
    end
  end
end
