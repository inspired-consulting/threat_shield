defmodule ThreatShieldWeb.ThreatSuggestionsController do
  use ThreatShieldWeb, :controller

  alias ThreatShield.AI

  def suggestions(conn, _params) do
    # Todo: get suggestions
    AI.suggest_initial_threats()
    |> IO.inspect()

    render(conn, :suggestions)
  end
end
