defmodule ThreatShield.AI do
  alias ThreatShield.Organisations.Organisation
  alias ThreatShield.Threats.Threat

  def suggest_initial_threats_for_organisation(%Organisation{} = organisation) do
    messages = [
      %{
        role: "system",
        content: ~s("""
          You are a threat modelling assistant. Your response should comprise five potential threats, each item having between 200–254 characters in length. Your response should be in JSON format, like so:

          {"threats": _}
          """)
      },
      %{
        role: "user",
        content: "I work at a company in the field of #{organisation.industry}."
      }
    ]

    case OpenAI.chat_completion(
           model: "gpt-3.5-turbo",
           messages: messages
         ) do
      {:ok, response} ->
        get_content_from_response(response)

      {:error, %{"error" => error}} ->
        {:error, error}
    end
  end

  defp get_content_from_response(response) do
    [first_choice | _] = response.choices
    %{"message" => message} = first_choice
    %{"content" => raw_response_string} = message

    {:ok, data} = Jason.decode(raw_response_string)

    %{"threats" => content} = data

    content
    |> Enum.map(fn d -> %Threat{description: d, is_candidate: true} end)
  end
end
