defmodule ThreatShield.AI do
  alias ThreatShield.Organisations.Organisation
  alias ThreatShield.Threats.Threat
  alias ThreatShield.Assets.Asset
  alias ThreatShield.Risks.Risk
  alias ThreatShield.Mitigations.Mitigation
  alias ThreatShield.Systems.System

  defp make_chatgpt_request(system_prompt, user_prompt, response_extractor) do
    messages =
      [
        %{
          role: "system",
          content: system_prompt
        },
        %{
          role: "user",
          content: user_prompt
        }
      ]
      |> IO.inspect()

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

  defp get_general_job_description(%Organisation{} = organisation) do
    """
    You are a threat modelling assistant at "#{organisation.name}".
    #{Organisation.describe(organisation)}
    """
  end

  defp get_response_format_description(resource_name_plural) do
    """
    Your response should comprise five response items, each item has a name and a description. The name should be up to 40 characters, the descriptions should be between 400 and 2000 characters long. The result is valid JSON like so:

    {"#{resource_name_plural}": [{"name": _, "description": _}, _ ]}
    """
  end

  def suggest_assets_for_organisation(%Organisation{} = organisation) do
    asset_info = """
      Assets are valuable resources or data, that need to be protected.
    """

    existing_assets =
      if Enum.empty?(organisation.assets) do
        ""
      else
        """
        I already know about the following assets:\n
        """ <>
          (organisation.assets
           |> Enum.map(fn a -> a.name end)
           |> Enum.join("\n"))
      end

    system_prompt = get_general_job_description(organisation)

    assignment = """
    Please suggest five additional assets that are different from the existing ones.
    """

    user_prompt =
      [get_response_format_description("assets"), asset_info, existing_assets, assignment]
      |> Enum.join(" ")

    make_chatgpt_request(system_prompt, user_prompt, &get_assets_from_response/1)
  end

  def suggest_assets_for_system(%System{} = system) do
    asset_info = """
      Assets are valuable resources or data for a particular system, that need to be protected.
    """

    existing_assets =
      if Enum.empty?(system.assets) do
        ""
      else
        """
        I already know about the following assets:\n
        """ <>
          (system.assets
           |> Enum.map(fn a -> a.name end)
           |> Enum.join("\n"))
      end

    system_prompt = get_general_job_description(system.organisation)

    assignment = """
    Please suggest five additional assets that are different from the existing ones. The assets should be specific to the system "#{system.name}".
    """

    user_prompt =
      [get_response_format_description("assets"), asset_info, existing_assets, assignment]
      |> Enum.join(" ")

    make_chatgpt_request(system_prompt, user_prompt, &get_assets_from_response/1)
  end

  def suggest_threats_for_organisation(%Organisation{} = organisation) do
    threat_info = """
    Threats are any potential event or action that can compromise the security of a system, organisation, or individual. Threats are not the negative outcome, i.e. not the loss, damage, or harm resulting from the exploitation of vulnerabilities by threats.
    """

    existing_threats =
      if Enum.empty?(organisation.threats) do
        ""
      else
        """
        I already know about the following threats:\n
        """ <>
          (organisation.threats
           |> Enum.map(fn a -> a.name end)
           |> Enum.join("\n"))
      end

    assignment = """
    Please suggest five additional threats that are different from the existing ones.
    """

    user_prompt =
      [get_response_format_description("threats"), threat_info, existing_threats, assignment]
      |> Enum.join(" ")

    system_prompt = get_general_job_description(organisation)

    make_chatgpt_request(system_prompt, user_prompt, &get_threats_from_response/1)
  end

  def suggest_threats_for_system(%System{} = system) do
    threat_info = """
    Threats are any potential event or action that can compromise the security of a system, organisation, or individual. Threats are not the negative outcome, i.e. not the loss, damage, or harm resulting from the exploitation of vulnerabilities by threats.
    """

    existing_threats =
      if Enum.empty?(system.threats) do
        ""
      else
        """
        I already know about the following threats:\n
        """ <>
          (system.threats
           |> Enum.map(fn a -> a.name end)
           |> Enum.join("\n"))
      end

    assignment = """
    Please suggest five additional threats that are different from the existing ones. The threats should be specific to the system "#{system.name}
    """

    user_prompt =
      [get_response_format_description("threats"), threat_info, existing_threats, assignment]
      |> Enum.join(" ")

    system_prompt = get_general_job_description(system.organisation)

    make_chatgpt_request(system_prompt, user_prompt, &get_threats_from_response/1)
  end

  def suggest_risks_for_threat(%Threat{} = threat) do
    risk_info = """
    Risks are the potential negative outcome — loss, damage, or harm resulting from the exploitation of vulnerabilities by threats.
    """

    existing_risks =
      if Enum.empty?(threat.risks) do
        ""
      else
        """
        I already know about the following risks:\n
        """ <>
          (threat.risks
           |> Enum.map(fn a -> a.name end)
           |> Enum.join("\n"))
      end

    assignment = """
    Please suggest five additional risks that are different from the existing ones. The risks should relate exclusively to the threat "#{threat.name}".
    """

    user_prompt =
      [get_response_format_description("risks"), risk_info, existing_risks, assignment]
      |> Enum.join(" ")

    system_prompt = get_general_job_description(threat.organisation)

    make_chatgpt_request(system_prompt, user_prompt, &get_risks_from_response/1)
  end

  def suggest_mitigations_for_risk(%Risk{} = risk) do
    mitigation_info = """
    Mitigations are strategies and measures put in place to mitigate the risks of a particular threat.
    """

    existing_mitigations =
      if Enum.empty?(risk.mitigations) do
        ""
      else
        """
        I already know about the following risks:\n
        """ <>
          (risk.mitigations
           |> Enum.map(fn a -> a.name end)
           |> Enum.join("\n"))
      end

    assignment = """
    Please suggest five additional mitigations that are different from the existing ones. The mitigations should relate exclusively to the risk "#{risk.name}" and the threat "#{risk.threat.name}".
    """

    system_exclusivity =
      if is_nil(risk.threat.system) do
        ""
      else
        """
        The only relvant system in this context is "#{risk.threat.system}".
        """
      end

    user_prompt =
      [
        get_response_format_description("mitigations"),
        mitigation_info,
        existing_mitigations,
        assignment,
        system_exclusivity
      ]
      |> Enum.join(" ")

    system_prompt = get_general_job_description(risk.threat.organisation)

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
    |> Enum.map(fn %{"name" => n, "description" => d} -> %Asset{name: n, description: d} end)
  end

  defp get_threats_from_response(response) do
    get_content_from_reponse(response, "threats")
    |> Enum.map(fn %{"name" => n, "description" => d} -> %Threat{name: n, description: d} end)
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
