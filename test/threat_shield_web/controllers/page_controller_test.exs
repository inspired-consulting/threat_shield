defmodule ThreatShieldWeb.PageControllerTest do
  use ThreatShieldWeb.ConnCase

  test "GET /", %{conn: conn} do
    conn = get(conn, ~p"/")
  end
end
