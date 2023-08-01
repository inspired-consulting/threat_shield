defmodule ThreatShieldWeb.ErrorJSONTest do
  use ThreatShieldWeb.ConnCase, async: true

  test "renders 404" do
    assert ThreatShieldWeb.ErrorJSON.render("404.json", %{}) == %{errors: %{detail: "Not Found"}}
  end

  test "renders 500" do
    assert ThreatShieldWeb.ErrorJSON.render("500.json", %{}) ==
             %{errors: %{detail: "Internal Server Error"}}
  end
end
