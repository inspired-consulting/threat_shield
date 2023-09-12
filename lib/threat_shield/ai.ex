defmodule ThreatShield.AI do
  alias ThreatShield.Organisations.Organisation
  alias ThreatShield.Threats.Threat
  alias ThreatShield.Assets.Asset
  alias ThreatShield.Risks.Risk
  alias ThreatShield.Mitigations.Mitigation
  alias ThreatShield.Systems.System

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
    You are a threat modelling assistant. Your response should comprise five potential assets, each item having between 200–254 characters in length. Each item is simply a string. Your response should be in JSON format, like so:

    {"assets": _}
    """

    user_prompt = "I work at this organisation: #{Organisation.describe(organisation)}"

    make_chatgpt_request(system_prompt, user_prompt, &get_assets_from_response/1)
  end

  def suggest_assets_for_system(%System{} = system) do
    system_prompt = """
    You are a threat modelling assistant. Your response should comprise five potential assets, each item having between 200–254 characters in length. Each item is simply a string. Your response should be in JSON format, like so:

    {"assets": _}
    """

    user_prompt =
      """
      I use this system: #{System.describe(system)}.
      """

    make_chatgpt_request(system_prompt, user_prompt, &get_assets_from_response/1)
  end

  def suggest_threats_for_organisation(%Organisation{} = organisation) do
    system_prompt = """
    You are a threat modelling assistant. Your response should comprise five potential threats, each item having between 200–254 characters in length. Your response should be in JSON format, like so:

    {"threats": _}
    """

    user_prompt =
      """
      I work at this organisation: #{Organisation.describe(organisation)}
      """

    make_chatgpt_request(system_prompt, user_prompt, &get_threats_from_response/1)
  end

  def suggest_risks_for_threat(%Threat{} = threat) do
    system_prompt = """
    You are a threat modelling assistant. Your response should comprise five potential risks for a given threat, each item having a name between 5-20 characters in length and a description between 200–254 characters in length. Your response should be in JSON format, like so:

    {"risks": [{"name": _, "description": _}, _ ]}
    """

    user_prompt =
      """
      I work at this organisation: #{Organisation.describe(threat.organisation)}. The threat that I want risks identified for is: #{Threat.describe(threat)}.
      """

    make_chatgpt_request(system_prompt, user_prompt, &get_risks_from_response/1)
  end

  def suggest_mitigations_for_risk(%Risk{} = risk) do
    system_prompt = """
    You are a threat modelling assistant. Your response should comprise five potential mitigations for a given risk, each item having a name between 5-20 characters in length and a description between 200–254 characters in length. Your response should be in JSON format, like so:

    {"mitigations": [{"name": _, "description": _}, _ ]}
    """

    user_prompt =
      """
      I work at this organisation: #{Organisation.describe(risk.threat.organisation)}. The risk that I want mitigations for is: #{Risk.describe(risk)}.
      """

    make_chatgpt_request(system_prompt, user_prompt, &get_mitigations_from_response/1)
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
    |> Enum.map(fn d -> %Asset{description: d} end)
  end

  defp get_threats_from_response(response) do
    get_content_from_reponse(response, "threats")
    |> Enum.map(fn d -> %Threat{description: d} end)
  end

  defp get_risks_from_response(response) do
    get_content_from_reponse(response, "risks")
    |> Enum.map(fn %{"name" => n, "description" => d} -> %Risk{name: n, description: d} end)
  end

  defp get_mitigations_from_response(response) do
    get_content_from_reponse(response, "mitigations")
    |> Enum.map(fn %{"name" => n, "description" => d} -> %Mitigation{name: n, description: d} end)
  end
end
