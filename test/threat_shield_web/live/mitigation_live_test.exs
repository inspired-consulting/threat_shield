defmodule ThreatShieldWeb.MitigationLiveTest do
  use ThreatShieldWeb.ConnCase

  import Phoenix.LiveViewTest
  import ThreatShield.MitigationsFixtures

  @create_attrs %{name: "some name", description: "some description", is_implemented: true}
  @update_attrs %{name: "some updated name", description: "some updated description", is_implemented: false}
  @invalid_attrs %{name: nil, description: nil, is_implemented: false}

  defp create_mitigation(_) do
    mitigation = mitigation_fixture()
    %{mitigation: mitigation}
  end

  describe "Index" do
    setup [:create_mitigation]

    test "lists all mitigations", %{conn: conn, mitigation: mitigation} do
      {:ok, _index_live, html} = live(conn, ~p"/mitigations")

      assert html =~ "Listing Mitigations"
      assert html =~ mitigation.name
    end

    test "saves new mitigation", %{conn: conn} do
      {:ok, index_live, _html} = live(conn, ~p"/mitigations")

      assert index_live |> element("a", "New Mitigation") |> render_click() =~
               "New Mitigation"

      assert_patch(index_live, ~p"/mitigations/new")

      assert index_live
             |> form("#mitigation-form", mitigation: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert index_live
             |> form("#mitigation-form", mitigation: @create_attrs)
             |> render_submit()

      assert_patch(index_live, ~p"/mitigations")

      html = render(index_live)
      assert html =~ "Mitigation created successfully"
      assert html =~ "some name"
    end

    test "updates mitigation in listing", %{conn: conn, mitigation: mitigation} do
      {:ok, index_live, _html} = live(conn, ~p"/mitigations")

      assert index_live |> element("#mitigations-#{mitigation.id} a", "Edit") |> render_click() =~
               "Edit Mitigation"

      assert_patch(index_live, ~p"/mitigations/#{mitigation}/edit")

      assert index_live
             |> form("#mitigation-form", mitigation: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert index_live
             |> form("#mitigation-form", mitigation: @update_attrs)
             |> render_submit()

      assert_patch(index_live, ~p"/mitigations")

      html = render(index_live)
      assert html =~ "Mitigation updated successfully"
      assert html =~ "some updated name"
    end

    test "deletes mitigation in listing", %{conn: conn, mitigation: mitigation} do
      {:ok, index_live, _html} = live(conn, ~p"/mitigations")

      assert index_live |> element("#mitigations-#{mitigation.id} a", "Delete") |> render_click()
      refute has_element?(index_live, "#mitigations-#{mitigation.id}")
    end
  end

  describe "Show" do
    setup [:create_mitigation]

    test "displays mitigation", %{conn: conn, mitigation: mitigation} do
      {:ok, _show_live, html} = live(conn, ~p"/mitigations/#{mitigation}")

      assert html =~ "Show Mitigation"
      assert html =~ mitigation.name
    end

    test "updates mitigation within modal", %{conn: conn, mitigation: mitigation} do
      {:ok, show_live, _html} = live(conn, ~p"/mitigations/#{mitigation}")

      assert show_live |> element("a", "Edit") |> render_click() =~
               "Edit Mitigation"

      assert_patch(show_live, ~p"/mitigations/#{mitigation}/show/edit")

      assert show_live
             |> form("#mitigation-form", mitigation: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert show_live
             |> form("#mitigation-form", mitigation: @update_attrs)
             |> render_submit()

      assert_patch(show_live, ~p"/mitigations/#{mitigation}")

      html = render(show_live)
      assert html =~ "Mitigation updated successfully"
      assert html =~ "some updated name"
    end
  end
end
