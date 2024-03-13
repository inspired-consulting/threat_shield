defmodule ThreatShield.Accounts.UserNotifier do
  import Swoosh.Email

  alias ThreatShield.Mailer
  alias ThreatShield.Members.Invite

  # Delivers the email using the application mailer.
  defp deliver(recipient, subject, body) do
    email =
      new()
      |> to(recipient)
      |> from({"ThreatShield", "threatshield@inspired.consulting"})
      |> subject(subject)
      |> text_body(body)

    with {:ok, _metadata} <- Mailer.deliver(email) do
      {:ok, email}
    end
  end

  @doc """
  Deliver instructions to confirm account.
  """
  def deliver_confirmation_instructions(user, url) do
    deliver(user.email, "Confirmation instructions", """

    ==============================

    Hi #{user.email},

    You can confirm your account by visiting the URL below:

    #{url}

    If you didn't create an account with us, please ignore this.

    ==============================
    """)
  end

  @doc """
  Deliver instructions to reset a user password.
  """
  def deliver_reset_password_instructions(user, url) do
    deliver(user.email, "Reset password instructions", """

    ==============================

    Hi #{user.email},

    You can reset your password by visiting the URL below:

    #{url}

    If you didn't request this change, please ignore this.

    ==============================
    """)
  end

  @doc """
  Deliver instructions to update a user email.
  """
  def deliver_update_email_instructions(user, url) do
    deliver(user.email, "Update email instructions", """

    ==============================

    Hi #{user.email},

    You can change your email by visiting the URL below:

    #{url}

    If you didn't request this change, please ignore this.

    ==============================
    """)
  end

  @doc """
  Deliver organisation invites.
  """
  def deliver_invite(%Invite{} = invite) do
    deliver(invite.email, "Organisation invite", """

    ==============================

    Hi,

    You have been invited to join #{invite.organisation.name} on ThreatShield 🙂 Follow the link below to accept the invite:

    #{ThreatShield.Members.Invite.generate_url(invite)}

    ==============================
    """)
  end
end
