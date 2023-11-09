defmodule ThreatShieldWeb.UserLoginLive do
  use ThreatShieldWeb, :live_view

  def render(assigns) do
    ~H"""
    <div class="w-1/2 ms-auto pt-20 px-20 bg-white h-full">
      <div class="mx-auto">
        <.flash_group flash={@flash} />
      </div>
      <.header class="text-center">
        <span class="threadshield-jumbo-header">
          <%= dgettext("accounts", "Welcome back") %>
        </span>
        <:subtitle>
          <%= dgettext("accounts", "Don't have an account yet?") %>
          <.link
            navigate={~p"/users/register"}
            class="font-semibold text-primary_col-500 hover:underline"
          >
            <%= dgettext("accounts", "Sign up now!") %>
          </.link>
        </:subtitle>
      </.header>

      <.simple_form for={@form} id="login_form" action={~p"/users/log_in"} phx-update="ignore">
        <.input field={@form[:email]} type="email" label="Email" required />
        <.input field={@form[:password]} type="password" label="Password" required />

        <:actions>
          <.input
            field={@form[:remember_me]}
            type="checkbox"
            label={dgettext("accounts", "remember me")}
          />
          <.link href={~p"/users/reset_password"} class="text-sm font-semibold">
            <%= dgettext("accounts", "Forgot your password?") %>
          </.link>
        </:actions>
        <:actions>
          <.button_magic phx-disable-with="Signing in..." class="text-lg w-full">
            <%= dgettext("accounts", "Sign in") %>
          </.button_magic>
        </:actions>
      </.simple_form>
    </div>
    """
  end

  def mount(_params, _session, socket) do
    email = live_flash(socket.assigns.flash, :email)
    form = to_form(%{"email" => email}, as: "user")

    socket
    |> assign(:form, form)
    |> ok(temporary_assigns: [form: form], layout: {ThreatShieldWeb.Layouts, :unauthenticated})
  end
end
