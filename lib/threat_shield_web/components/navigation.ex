defmodule ThreatShieldWeb.Navigation do
  use Phoenix.Component

  alias Phoenix.LiveView.JS

  def render(assigns) do
    ~H"""
    <nav>
      <ul class="relative z-10 flex gap-4 px-4 sm:px-6 lg:px-8 justify-end">
        <%= if assigns[:organisation] do %>
          <li class="relative user-dropdown text-[0.8125rem] leading-loose text-primary_col-600 font-semibold hover:cursor-pointer">
            <%= @organisation.name %>
          </li>
          <ul class="absolute user-menu hidden right-10 mt-10 py-2 w-48 bg-white rounded-sm shadow-xl">
            <li class="px-4 py-2">
              <a
                href="/organisations"
                class="text-[0.8125rem] leading-6 text-primary_col-600 hover:underline"
              >
                List organisation
              </a>
            </li>
          </ul>
        <% end %>
        <%= if @current_user do %>
          <li class="relative user-dropdown text-[0.8125rem] leading-loose text-primary_col-600 font-semibold hover:cursor-pointer">
            <%= @current_user.email %>
          </li>
          <ul class="absolute user-menu hidden right-0 mt-10 py-2 w-48 bg-white rounded-sm shadow-xl">
            <li class="px-4 py-2">
              <a
                href="/users/settings"
                class="text-[0.8125rem] leading-6 text-primary_col-600 hover:underline"
              >
                Settings
              </a>
            </li>
            <li class="px-4 py-2">
              <a
                href="#"
                onclick="deleteUser(); return false;"
                class="text-[0.8125rem] leading-6 text-primary_col-600 hover:underline"
              >
                Log out
              </a>
            </li>
          </ul>
        <% else %>
          <li>
            <a
              href="/users/register"
              class="text-[0.8125rem] leading-6 text-primary_col-600 font-semibold hover:underline"
            >
              Register
            </a>
          </li>
          <li>
            <a
              href="/users/log_in"
              class="text-[0.8125rem] leading-6 text-primary_col-600 font-semibold hover:underline"
            >
              Log in
            </a>
          </li>
        <% end %>
      </ul>
    </nav>
    """
  end
end
