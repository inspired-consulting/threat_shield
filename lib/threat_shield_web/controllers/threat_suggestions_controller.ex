defmodule ThreatShieldWeb.ThreatSuggestionsController do
  use ThreatShieldWeb, :controller

  alias ThreatShield.AI
  alias ThreatShield.Systems

  def suggestions(
        conn,
        %{"org_id" => org_id, "sys_id" => sys_id}
      ) do
    current_user = conn.assigns.current_user

    system = Systems.get_system_for_user_and_org(current_user, org_id, sys_id)
    organisation = system.organisation

    {:ok, %{"threats" => threats}} =
      AI.suggest_initial_threats(organisation, system)

    conn =
      conn
      |> assign(:threats, threats)

    render(conn, :suggestions)
  end
end
