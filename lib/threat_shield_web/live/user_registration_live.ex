defmodule ThreatShieldWeb.UserRegistrationLive do
  use ThreatShieldWeb, :live_view

  alias ThreatShield.Accounts
  alias ThreatShield.Accounts.User

  @steps [
    :email,
    :password,
    :organisation
  ]

  defp is_hidden?(field, progress) do
    visible_steps =
      @steps
      |> Enum.reverse()
      |> Enum.drop_while(fn step -> step != progress end)

    field not in visible_steps
  end

  defp is_in_last_step?(progress) do
    progress == List.last(@steps)
  end

  defp form_section_classes(name, progress) do
    "chat-input grid justify-items-stretch" <>
      if is_hidden?(name, progress) do
        " hidden"
      else
        ""
      end
  end

  def render(assigns) do
    ~H"""
    <div class="mx-auto max-w-sm">
      <.header class="text-center">
        Register for an account
        <:subtitle>
          Already registered?
          <.link
            navigate={~p"/users/log_in"}
            class="font-semibold text-primary_col-500 hover:underline"
          >
            Sign in
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

        <section class="chat-input grid justify-items-stretch">
          <div class="fake-input-box justify-self-start">
            <label for id="email">Please provide your mail address</label>
          </div>
          <div class="justify-self-end">
            <.input field={@form[:email]} type="email" required />
          </div>
        </section>

        <section class={form_section_classes(:password, @progress)}>
          <div class="fake-input-box justify-self-start">
            <label for id="password">Please provide a password</label>
          </div>
          <div class="justify-self-end">
            <.input field={@form[:password]} type="password" required />
          </div>
        </section>

        <section class={form_section_classes(:organisation, @progress)}>
          <div class="fake-input-box justify-self-start">
            <label for id="organisation">Please name your organisation</label>
          </div>
          <div class="justify-self-end">
            <.input field={@form[:organisation]} type="text" />
          </div>
        </section>

        <:actions>
          <%= if is_in_last_step?(@progress) do %>
            <.button phx-disable-with="Creating account..." class="min-w-fit">
              Create an account
            </.button>
          <% else %>
            <.button
              type="button"
              phx-click={JS.push("continue")}
              disabled={!@can_continue}
              class="min-w-fit"
            >
              Continue
            </.button>
          <% end %>
        </:actions>
      </.simple_form>
    </div>
    """
  end

  def mount(_params, _session, socket) do
    changeset = Accounts.change_user_registration(%User{})

    first_step = List.first(@steps)

    socket =
      socket
      |> assign(
        trigger_submit: false,
        check_errors: false,
        can_continue: false,
        progress: first_step
      )
      |> assign_form(changeset)

    {:ok, socket, temporary_assigns: [form: nil]}
  end

  def handle_event("save", %{"user" => user_params}, socket) do
    user_params |> IO.inspect()

    case Accounts.register_user_with_organisation(user_params) do
      {:ok, {:ok, user}} ->
        {:ok, _} =
          Accounts.deliver_user_confirmation_instructions(
            user,
            &url(~p"/users/confirm/#{&1}")
          )

        changeset = Accounts.change_user_registration(user)
        {:noreply, socket |> assign(trigger_submit: true) |> assign_form(changeset)}

      {_, {:error, %Ecto.Changeset{} = changeset}} ->
        {:noreply, socket |> assign(check_errors: true) |> assign_form(changeset)}
    end
  end

  def handle_event("validate", %{"user" => user_params}, socket) do
    changeset = Accounts.change_user_registration(%User{}, user_params)

    {:noreply,
     socket
     |> assign_form(Map.put(changeset, :action, :validate))
     |> update_can_continue(changeset)}
  end

  def handle_event("continue", _params, socket) do
    {:noreply, advance_progress(socket)}
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

  defp update_can_continue(socket, changeset) do
    progress = socket.assigns.progress

    if !Keyword.has_key?(changeset.errors, progress) do
      socket |> assign(can_continue: true)
    else
      socket
    end
  end

  defp advance_progress(socket) do
    current = socket.assigns.progress

    new =
      @steps
      |> Enum.reverse()
      |> Enum.take_while(fn s -> s != current end)
      |> List.last(List.last(@steps))

    assign(socket, progress: new, can_continue: false)
  end
end
