defmodule ThreatShieldWeb.UserRegistrationLive do
  use ThreatShieldWeb, :live_view

  alias ThreatShield.Accounts
  alias ThreatShield.Accounts.User

  def render(assigns) do
    ~H"""
    <div class="w-1/2 me-auto pt-20 px-20 bg-white h-full">
      <.header class="text-center">
        <span class="threadshield-jumbo-header">
          <%= dgettext("accounts", "Join us") %>
        </span>
        <:subtitle>
          Already registered?
          <.link navigate={~p"/users/log_in"} class="font-semibold text-primary-500 hover:underline">
            <%= dgettext("accounts", "Sign in") %>
          </.link>
          to your account now.
        </:subtitle>
      </.header>

      <.flash_group flash={@flash} />

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

        <.input
          field={@form[:accept_toc]}
          type="checkbox"
          required
          label={dgettext("accounts", "By checking this box, you agree to our terms of service")}
        />

        <:actions>
          <.button_magic phx-disable-with="Creating account..." class="text-lg w-full">
            <%= dgettext("accounts", "Sign up") %>
          </.button_magic>
        </:actions>
      </.simple_form>
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
