defmodule ThreatShieldWeb.SystemLiveTest do
  use ThreatShieldWeb.ConnCase

  import Phoenix.LiveViewTest
  import ThreatShield.SystemsFixtures

  @create_attrs %{attributes: %{}, name: "some name", description: "some description"}
  @update_attrs %{attributes: %{}, name: "some updated name", description: "some updated description"}
  @invalid_attrs %{attributes: nil, name: nil, description: nil}

  defp create_system(_) do
    {:ok, user} = ThreatShield.Accounts.register_user(%{email: "user@example.com", password: "newsafepassword"})
    {:ok, organisation} = ThreatShield.Organisations.create_organisation(%{name: "Test Org"}, user)
    system = ThreatShield.Systems.create_system(user, organisation, %{name: "Test System"})
    %{system: system}
  end

  describe "Index" do
    setup [:create_system]

    test "lists all systems", %{conn: conn, system: system} do
      {:ok, _index_live, html} = live(conn, ~p"/organisations/:org_id/systems")

      assert html =~ "Listing Systems"
      assert html =~ system.name
    end

    test "saves new system", %{conn: conn} do
      {:ok, index_live, _html} = live(conn, ~p"/organisations/:org_id/systems")

      assert index_live |> element("a", "New System") |> render_click() =~
               "New System"

      assert_patch(index_live, ~p"/organisations/:org_id/systems/new")

      assert index_live
             |> form("#system-form", system: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert index_live
             |> form("#system-form", system: @create_attrs)
             |> render_submit()

      assert_patch(index_live, ~p"/organisations/:org_id/systems")

      html = render(index_live)
      assert html =~ "System created successfully"
      assert html =~ "some name"
    end

    test "updates system in listing", %{conn: conn, system: system} do
      {:ok, index_live, _html} = live(conn, ~p"/organisations/:org_id/systems")

      assert index_live |> element("#systems-#{system.id} a", "Edit") |> render_click() =~
               "Edit System"

      assert_patch(index_live, ~p"/organisations/:org_id/systems/#{system}/edit")

      assert index_live
             |> form("#system-form", system: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert index_live
             |> form("#system-form", system: @update_attrs)
             |> render_submit()

      assert_patch(index_live, ~p"/organisations/:org_id/systems")

      html = render(index_live)
      assert html =~ "System updated successfully"
      assert html =~ "some updated name"
    end

    test "deletes system in listing", %{conn: conn, system: system} do
      {:ok, index_live, _html} = live(conn, ~p"/organisations/:org_id/systems")

      assert index_live |> element("#systems-#{system.id} a", "Delete") |> render_click()
      refute has_element?(index_live, "#systems-#{system.id}")
    end
  end

  describe "Show" do
    setup [:create_system]

    test "displays system", %{conn: conn, system: system} do
      {:ok, _show_live, html} = live(conn, ~p"/organisations/:org_id/systems/#{system}")

      assert html =~ "Show System"
      assert html =~ system.name
    end

    test "updates system within modal", %{conn: conn, system: system} do
      {:ok, show_live, _html} = live(conn, ~p"/organisations/:org_id/systems/#{system}")

      assert show_live |> element("a", "Edit") |> render_click() =~
               "Edit System"

      assert_patch(show_live, ~p"/organisations/:org_id/systems/#{system}/show/edit")

      assert show_live
             |> form("#system-form", system: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert show_live
             |> form("#system-form", system: @update_attrs)
             |> render_submit()

      assert_patch(show_live, ~p"/organisations/:org_id/systems/#{system}")

      html = render(show_live)
      assert html =~ "System updated successfully"
      assert html =~ "some updated name"
    end
  end
end
