defmodule ThreatShieldWeb.UserForgotPasswordLive do
  use ThreatShieldWeb, :live_view

  alias ThreatShield.Accounts

  def render(assigns) do
    ~H"""
    <div class="mx-auto max-w-sm mt-6">
      <.header class="text-center">
        <span class="text-xl"><%= dgettext("accounts", "Forgot your password?") %></span>
        <:subtitle>We'll send a password reset link to your inbox</:subtitle>
      </.header>

      <.flash_group flash={@flash} />

      <.simple_form for={@form} id="reset_password_form" phx-submit="send_email">
        <.input field={@form[:email]} type="email" placeholder="Email" required />
        <:actions>
          <.button_primary phx-disable-with="Sending..." class="w-full">
            Send password reset instructions
          </.button_primary>
        </:actions>
      </.simple_form>
      <p class="text-center text-sm mt-4">
        <.link href={~p"/users/register"}><%= dgettext("accounts", "Sign up") %></.link>
        | <.link href={~p"/users/log_in"}><%= dgettext("accounts", "Sign in") %></.link>
      </p>
    </div>
    """
  end

  def mount(_params, _session, socket) do
    socket
    |> assign(form: to_form(%{}, as: "user"))
    |> ok(layout: {ThreatShieldWeb.Layouts, :unauthenticated})
  end

  def handle_event("send_email", %{"user" => %{"email" => email}}, socket) do
    if user = Accounts.get_user_by_email(email) do
      Accounts.deliver_user_reset_password_instructions(
        user,
        &url(~p"/users/reset_password/#{&1}")
      )
    end

    info =
      "If your email is in our system, you will receive instructions to reset your password shortly."

    {:noreply,
     socket
     |> put_flash(:info, info)
     |> redirect(to: ~p"/")}
  end
end
