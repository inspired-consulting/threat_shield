defmodule ThreatShield.AI do
  alias ThreatShield.Organisations.Organisation
  alias ThreatShield.Systems.System

  def suggest_initial_threats(%Organisation{} = organisation, %System{} = system) do
    messages = [
      %{
        role: "system",
        content:
          "You are a threat modelling assistant. Give results as a JSON list of strings. The results should be potential threats."
      },
      %{role: "user", content: "I have a Postgres database. Give a list of five threats."}
    ]

    case OpenAI.chat_completion(
           model: "gpt-3.5-turbo",
           messages: messages
         ) do
      {:ok, response} ->
        {:ok, response}

      {:error, %{"error" => error}} ->
        {:error, error}
    end
  end
end
