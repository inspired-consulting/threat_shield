defmodule ThreatShieldWeb.UserRegistrationLive do
  use ThreatShieldWeb, :live_view

  alias ThreatShield.Accounts
  alias ThreatShield.Accounts.User

  def render(assigns) do
    ~H"""
    <div class="flex h-full bg-white">
      <div class="md:w-1/2 md:flex flex-col justify-stretch px-4 md:px-20 h-full shadow shadow-lg shadow-primary-300">
        <div class="flex-grow h-32 pt-2">
          <.flash_group flash={@flash} />
        </div>
        <main class="md:w-[36rem] mx-auto">
          <.header class="text-center">
            <span class="threadshield-jumbo-header">
              <%= dgettext("accounts", "Join us") %>
            </span>
            <:subtitle>
              Already registered?
              <.link
                navigate={~p"/users/log_in"}
                class="font-semibold text-primary-500 hover:underline"
              >
                <%= dgettext("accounts", "Sign in") %>
              </.link>
              to your account now.
            </:subtitle>
          </.header>

          <.simple_form
            for={@form}
            id="registration_form"
            phx-submit="save"
            phx-change="validate"
            phx-trigger-action={@trigger_submit}
            action={~p"/users/log_in?_action=registered"}
            method="post"
          >
            <.error :if={@check_errors}>
              Oops, something went wrong! Please check the errors below.
            </.error>

            <div class="grid grid-cols-2 gap-4">
              <.input field={@form[:first_name]} label="First name" required />
              <.input field={@form[:last_name]} label="Last name" required />
            </div>

            <.input field={@form[:email]} type="email" label="Email" required autocomplete="off" />
            <.input
              field={@form[:password]}
              type="password"
              label="Password"
              required
              autocomplete="new-password"
            />

            <label class="flex items-center gap-4 text-sm leading-6">
              <.input field={@form[:accept_toc]} type="checkbox" required />
              <span>
                <%= dgettext("accounts", "By checking this box, you agree to our") %>
                <a href="https://threatshield.eu/terms.html" target="_blank" class="text-primary-500">
                  <%= dgettext("accounts", "Terms of Service") %>
                </a>
                and our <a
                  href="https://threatshield.eu/privacy.html"
                  target="_blank"
                  class="text-primary-500"
                >
                <%= dgettext("accounts", "Privacy Policy") %>
                </a>.
              </span>
            </label>

            <:actions>
              <.button_magic phx-disable-with="Creating account..." class="text-lg w-full">
                <%= dgettext("accounts", "Sign up") %>
              </.button_magic>
            </:actions>
          </.simple_form>
        </main>
        <footer class="flex-grow text-center flex flex-col justify-end text-xs h-32">
          <div class="p-4 space-x-6">
            <a href="https://threatshield.eu" class="text-gray-500">
              threatshield.eu
            </a>
            <a href="https://inspired.consulting" class="text-gray-500">
              inspired.consulting
            </a>
          </div>
        </footer>
      </div>
      <div class="hidden md:block w-1/2">
        <img src={~p"/images/shiba-dancing.png"} alt="" class="w-full h-full object-cover" />
      </div>
    </div>
    """
  end

  @spec mount(any(), any(), any()) :: {:ok, any(), any()}
  def mount(_params, _session, socket) do
    changeset = Accounts.change_user_registration(%User{})

    socket
    |> assign(
      trigger_submit: false,
      check_errors: false
    )
    |> assign_form(changeset)
    |> ok(temporary_assigns: [form: nil], layout: {ThreatShieldWeb.Layouts, :unauthenticated})
  end

  def handle_event("save", %{"user" => user_params}, socket) do
    case Accounts.register_user(user_params) do
      {:ok, user} ->
        {:ok, _} =
          Accounts.deliver_user_confirmation_instructions(
            user,
            &url(~p"/users/confirm/#{&1}")
          )

        changeset = Accounts.change_user_registration(user)
        {:noreply, socket |> assign(trigger_submit: true) |> assign_form(changeset)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, socket |> assign(check_errors: true) |> assign_form(changeset)}
    end
  end

  def handle_event("validate", %{"user" => user_params}, socket) do
    changeset = Accounts.change_user_registration(%User{}, user_params)

    socket
    |> assign_form(Map.put(changeset, :action, :validate))
    |> noreply()
  end

  defp assign_form(socket, %Ecto.Changeset{} = changeset) do
    form = to_form(changeset, as: "user")

    if changeset.valid? do
      socket
      |> assign(form: form, check_errors: false)
    else
      socket
      |> assign(form: form)
    end
  end
end
