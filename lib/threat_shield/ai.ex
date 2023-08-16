defmodule ThreatShield.AI do
  alias ThreatShield.Organisations.Organisation
  alias ThreatShield.Threats.Threat
  alias ThreatShield.Assets.Asset

  defp make_chatgpt_request(system_prompt, user_prompt, response_extractor) do
    messages = [
      %{
        role: "system",
        content: system_prompt
      },
      %{
        role: "user",
        content: user_prompt
      }
    ]

    case OpenAI.chat_completion(
           model: "gpt-3.5-turbo",
           messages: messages
         ) do
      {:ok, response} ->
        response_extractor.(response)

      {:error, %{"error" => error}} ->
        {:error, error}
    end
  end

  def suggest_assets_for_organisation(%Organisation{} = organisation) do
    system_prompt = """
    You are a threat modelling assistant. Your response should comprise five potential assets, each item having between 200–254 characters in length. Your response should be in JSON format, like so:

    {"assets": _}
    """

    user_prompt = "I work at a company in the field of #{organisation.industry}."

    make_chatgpt_request(system_prompt, user_prompt, &get_assets_from_response/1)
  end

  def suggest_threats_for_organisation(%Organisation{} = organisation) do
    system_prompt = """
    You are a threat modelling assistant. Your response should comprise five potential threats, each item having between 200–254 characters in length. Your response should be in JSON format, like so:

    {"threats": _}
    """

    user_prompt = "I work at a company in the field of #{organisation.industry}."

    make_chatgpt_request(system_prompt, user_prompt, &get_threats_from_response/1)
  end

  defp get_content_from_reponse(response, root_key) do
    [first_choice | _] = response.choices
    %{"message" => message} = first_choice
    %{"content" => raw_response_string} = message

    {:ok, data} = Jason.decode(raw_response_string)

    %{^root_key => content} = data
    content
  end

  defp get_assets_from_response(response) do
    get_content_from_reponse(response, "assets")
    |> Enum.map(fn d -> %Asset{description: d, is_candidate: true} end)
  end

  defp get_threats_from_response(response) do
    get_content_from_reponse(response, "threats")
    |> Enum.map(fn d -> %Threat{description: d, is_candidate: true} end)
  end
end
