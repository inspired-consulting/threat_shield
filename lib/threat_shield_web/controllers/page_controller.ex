defmodule ThreatShieldWeb.PageController do
  use ThreatShieldWeb, :controller

  def home(conn, _params) do
    redirect(conn, to: ~p"/organisations")
  end
end
