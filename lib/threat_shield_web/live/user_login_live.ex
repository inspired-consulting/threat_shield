defmodule ThreatShieldWeb.UserLoginLive do
  use ThreatShieldWeb, :live_view

  def render(assigns) do
    ~H"""
    <div class="md:flex md:h-full bg-white">
      <div class="hidden md:block md:w-1/2">
        <img src={~p"/images/shiba-hero1.png"} alt="" class="w-full h-full object-cover" />
      </div>
      <div class="md:w-1/2 flex flex-col justify-stretch px-4 lg:px-12 xl:px-20 h-full md:shadow md:shadow-lg shadow-primary-300">
        <div class="flex-grow h-32 pt-2">
          <.flash_group flash={@flash} />
        </div>
        <main class="xxl:w-[36rem] mx-auto">
          <.header class="text-center">
            <div class="threadshield-header text-4xl md:text-6xl 2xl:text-8xl">
              <%= dgettext("accounts", "Welcome back") %>
            </div>
            <:subtitle>
              <span class="text-gray-700">
                <%= dgettext("accounts", "Don't have an account yet?") %>
              </span>
              <.link
                navigate={~p"/users/register"}
                class="font-semibold text-primary-500 hover:underline"
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
              <.link href={~p"/users/reset_password"} class="text-sm font-semibold text-gray-700">
                <%= dgettext("accounts", "Forgot your password?") %>
              </.link>
            </:actions>
            <:actions>
              <.button_magic phx-disable-with="Signing in..." class="mt-4 text-lg w-full">
                <%= dgettext("accounts", "Sign in") %>
              </.button_magic>
            </:actions>
          </.simple_form>
        </main>
        <footer class="flex-grow text-center flex flex-col justify-center md:justify-end text-xs h-32">
          <div class="py-6 space-x-6">
            <a href="https://threatshield.eu" class="text-gray-500">
              threatshield.eu
            </a>
            <a href="https://inspired.consulting" class="text-gray-500">
              inspired.consulting
            </a>
          </div>
        </footer>
      </div>
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
