defmodule ThreatShieldWeb.FormHelpers do
  @moduledoc """
  Shared functions for the form components.

  A form component gets the assign `:patch` from its parent: the path to return to
  after a successful save.
  """

  import Phoenix.Component, only: [assign: 3, to_form: 1]
  import Phoenix.LiveView, only: [put_flash: 3, push_patch: 2]

  @doc """
  Assigns the changeset as `:form`.
  """
  def assign_form(socket, %Ecto.Changeset{} = changeset) do
    assign(socket, :form, to_form(changeset))
  end

  @doc """
  Handles the result of a create or update function of a context.

  On success, it sends `{form_module, {:saved, entity}}` to the parent LiveView,
  shows the message, and returns to the path in the assign `:patch`. On a
  validation error, it shows the changeset in the form.
  """
  def handle_save_result(socket, {:ok, entity}, form_module, message) do
    send(self(), {form_module, {:saved, entity}})

    socket
    |> put_flash(:info, message)
    |> push_patch(to: socket.assigns.patch)
  end

  def handle_save_result(socket, {:error, %Ecto.Changeset{} = changeset}, _form_module, _message) do
    assign_form(socket, changeset)
  end
end
