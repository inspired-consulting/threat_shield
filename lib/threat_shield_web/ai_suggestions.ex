defmodule ThreatShieldWeb.AiSuggestions do
  @moduledoc """
  The AI suggestion flow for list components.

  A list component

    * calls `request/3` to ask the AI assistant for suggestions,
    * passes the result from its `handle_async/3` callback to `handle_result/2`,
    * and reads the suggestions that the user selected in the dialog with `selected/2`.

  The suggestions are kept in the assign `:ai_suggestions` of the component. The
  dialog is shown while `:show_suggest_dialog` is true. The component needs the
  assign `:origin`, the path to return to when a request fails.
  """

  import Phoenix.Component, only: [assign: 3]
  import Phoenix.LiveView, only: [start_async: 4, put_flash: 3, push_navigate: 2]
  import ThreatShieldWeb.Gettext

  alias ThreatShield.AI
  alias ThreatShield.Scope

  @doc """
  Opens the suggestion dialog and asks the AI assistant in the background.

  `fun` calls the AI module and returns the list of suggestions.
  """
  def request(socket, %Scope{} = scope, fun) when is_function(fun, 0) do
    socket
    |> assign(:ai_suggestions, nil)
    |> assign(:show_suggest_dialog, true)
    |> start_async(:ai_suggestions, fn -> AI.run_task(scope, fun) end,
      supervisor: ThreatShield.TaskSupervisor
    )
  end

  @doc """
  Handles the result of a request, as it is passed to `handle_async/3`.
  """
  def handle_result(socket, {:ok, {:ok, [_ | _] = suggestions}}) do
    assign(socket, :ai_suggestions, suggestions)
  end

  def handle_result(socket, {:ok, {:error, :quota_exceeded}}) do
    fail(socket, dgettext("common", "Your quota for AI suggestions is exceeded."))
  end

  # an error from the AI module, an empty list, or a crashed task
  def handle_result(socket, _result) do
    fail(
      socket,
      dgettext("common", "The AI assistant could not create suggestions. Please try again later.")
    )
  end

  @doc """
  Returns the suggestions that are selected in the parameters of the dialog form.
  """
  def selected(socket, %{"selected_suggestions" => names}) when is_list(names) do
    Enum.filter(socket.assigns[:ai_suggestions] || [], fn s -> s.name in names end)
  end

  def selected(_socket, _params), do: []

  defp fail(socket, message) do
    socket
    |> assign(:show_suggest_dialog, false)
    |> put_flash(:error, message)
    |> push_navigate(to: socket.assigns.origin)
  end
end
