defmodule ThreatShieldWeb.ThreatLiveTest do
  use ThreatShieldWeb.ConnCase

  import Phoenix.LiveViewTest
  import ThreatShield.ThreatsFixtures

  @create_attrs %{description: "some description", is_candidate: true}
  @update_attrs %{description: "some updated description", is_candidate: false}
  @invalid_attrs %{description: nil, is_candidate: false}

  defp create_threat(_) do
    threat = threat_fixture()
    %{threat: threat}
  end

  describe "Index" do
    setup [:create_threat]

    test "lists all threats", %{conn: conn, threat: threat} do
      {:ok, _index_live, html} = live(conn, ~p"/threats")

      assert html =~ "Listing Threats"
      assert html =~ threat.description
    end

    test "saves new threat", %{conn: conn} do
      {:ok, index_live, _html} = live(conn, ~p"/threats")

      assert index_live |> element("a", "New Threat") |> render_click() =~
               "New Threat"

      assert_patch(index_live, ~p"/threats/new")

      assert index_live
             |> form("#threat-form", threat: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert index_live
             |> form("#threat-form", threat: @create_attrs)
             |> render_submit()

      assert_patch(index_live, ~p"/threats")

      html = render(index_live)
      assert html =~ "Threat created successfully"
      assert html =~ "some description"
    end

    test "updates threat in listing", %{conn: conn, threat: threat} do
      {:ok, index_live, _html} = live(conn, ~p"/threats")

      assert index_live |> element("#threats-#{threat.id} a", "Edit") |> render_click() =~
               "Edit Threat"

      assert_patch(index_live, ~p"/threats/#{threat}/edit")

      assert index_live
             |> form("#threat-form", threat: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert index_live
             |> form("#threat-form", threat: @update_attrs)
             |> render_submit()

      assert_patch(index_live, ~p"/threats")

      html = render(index_live)
      assert html =~ "Threat updated successfully"
      assert html =~ "some updated description"
    end

    test "deletes threat in listing", %{conn: conn, threat: threat} do
      {:ok, index_live, _html} = live(conn, ~p"/threats")

      assert index_live |> element("#threats-#{threat.id} a", "Delete") |> render_click()
      refute has_element?(index_live, "#threats-#{threat.id}")
    end
  end

  describe "Show" do
    setup [:create_threat]

    test "displays threat", %{conn: conn, threat: threat} do
      {:ok, _show_live, html} = live(conn, ~p"/threats/#{threat}")

      assert html =~ "Show Threat"
      assert html =~ threat.description
    end

    test "updates threat within modal", %{conn: conn, threat: threat} do
      {:ok, show_live, _html} = live(conn, ~p"/threats/#{threat}")

      assert show_live |> element("a", "Edit") |> render_click() =~
               "Edit Threat"

      assert_patch(show_live, ~p"/threats/#{threat}/show/edit")

      assert show_live
             |> form("#threat-form", threat: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert show_live
             |> form("#threat-form", threat: @update_attrs)
             |> render_submit()

      assert_patch(show_live, ~p"/threats/#{threat}")

      html = render(show_live)
      assert html =~ "Threat updated successfully"
      assert html =~ "some updated description"
    end
  end
end
