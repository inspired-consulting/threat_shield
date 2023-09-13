defmodule ThreatShieldWeb.InvitesLiveTest do
  use ThreatShieldWeb.ConnCase

  import Phoenix.LiveViewTest
  import ThreatShield.MembersFixtures

  @create_attrs %{token: "some token", email: "some email"}
  @update_attrs %{token: "some updated token", email: "some updated email"}
  @invalid_attrs %{token: nil, email: nil}

  defp create_invites(_) do
    invites = invites_fixture()
    %{invites: invites}
  end

  describe "Index" do
    setup [:create_invites]

    test "lists all invites", %{conn: conn, invites: invites} do
      {:ok, _index_live, html} = live(conn, ~p"/invites")

      assert html =~ "Listing Invites"
      assert html =~ invites.token
    end

    test "saves new invites", %{conn: conn} do
      {:ok, index_live, _html} = live(conn, ~p"/invites")

      assert index_live |> element("a", "New Invites") |> render_click() =~
               "New Invites"

      assert_patch(index_live, ~p"/invites/new")

      assert index_live
             |> form("#invites-form", invites: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert index_live
             |> form("#invites-form", invites: @create_attrs)
             |> render_submit()

      assert_patch(index_live, ~p"/invites")

      html = render(index_live)
      assert html =~ "Invites created successfully"
      assert html =~ "some token"
    end

    test "updates invites in listing", %{conn: conn, invites: invites} do
      {:ok, index_live, _html} = live(conn, ~p"/invites")

      assert index_live |> element("#invites-#{invites.id} a", "Edit") |> render_click() =~
               "Edit Invites"

      assert_patch(index_live, ~p"/invites/#{invites}/edit")

      assert index_live
             |> form("#invites-form", invites: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert index_live
             |> form("#invites-form", invites: @update_attrs)
             |> render_submit()

      assert_patch(index_live, ~p"/invites")

      html = render(index_live)
      assert html =~ "Invites updated successfully"
      assert html =~ "some updated token"
    end

    test "deletes invites in listing", %{conn: conn, invites: invites} do
      {:ok, index_live, _html} = live(conn, ~p"/invites")

      assert index_live |> element("#invites-#{invites.id} a", "Delete") |> render_click()
      refute has_element?(index_live, "#invites-#{invites.id}")
    end
  end

  describe "Show" do
    setup [:create_invites]

    test "displays invites", %{conn: conn, invites: invites} do
      {:ok, _show_live, html} = live(conn, ~p"/invites/#{invites}")

      assert html =~ "Show Invites"
      assert html =~ invites.token
    end

    test "updates invites within modal", %{conn: conn, invites: invites} do
      {:ok, show_live, _html} = live(conn, ~p"/invites/#{invites}")

      assert show_live |> element("a", "Edit") |> render_click() =~
               "Edit Invites"

      assert_patch(show_live, ~p"/invites/#{invites}/show/edit")

      assert show_live
             |> form("#invites-form", invites: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert show_live
             |> form("#invites-form", invites: @update_attrs)
             |> render_submit()

      assert_patch(show_live, ~p"/invites/#{invites}")

      html = render(show_live)
      assert html =~ "Invites updated successfully"
      assert html =~ "some updated token"
    end
  end
end
