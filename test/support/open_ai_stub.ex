defmodule ThreatShield.OpenAIStub do
  @moduledoc """
  Replaces the OpenAI client in tests (see `config/test.exs`).

  It answers a chat completion with two items in the JSON format that the request
  asks for.

  A test can change this with the application environment of `:threat_shield`:

    * `:open_ai_stub_listener` - a pid that gets `{:open_ai_request, messages}`
      for each request
    * `:open_ai_stub_result` - the result to return
  """

  def chat_completion(params) do
    messages = Keyword.fetch!(params, :messages)

    if listener = Application.get_env(:threat_shield, :open_ai_stub_listener) do
      send(listener, {:open_ai_request, messages})
    end

    Application.get_env(:threat_shield, :open_ai_stub_result) || suggestions(messages)
  end

  defp suggestions(messages) do
    text = Enum.map_join(messages, "\n", & &1.content)
    [_, root_key, field] = Regex.run(~r/\{"(\w+)": \[\{"(\w+)":/, text)

    items =
      case field do
        "value" ->
          [%{"value" => "Example 1"}, %{"value" => "Example 2"}]

        _ ->
          [
            %{"name" => "Suggestion 1", "description" => "Description 1"},
            %{"name" => "Suggestion 2", "description" => "Description 2"}
          ]
      end

    content = Jason.encode!(%{root_key => items})

    {:ok, %{choices: [%{"message" => %{"content" => content}}]}}
  end
end
