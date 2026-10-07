defmodule ThreatShield.AI do
  alias ThreatShield.DynamicAttribute
  alias ThreatShield.Accounts.Organisation
  alias ThreatShield.Threats.Threat
  alias ThreatShield.Assets.Asset
  alias ThreatShield.Risks.Risk
  alias ThreatShield.Mitigations.Mitigation
  alias ThreatShield.Systems.System
  alias ThreatShield.Scope
  alias ThreatShield.Quotas.QuotaManager

  require Logger

  @open_ai_model "gpt-3.5-turbo"
  # @open_ai_model "gpt-4-turbo-preview"

  @schemas %{assets: Asset, threats: Threat, risks: Risk, mitigations: Mitigation}

  # The changesets of these schemas allow names of up to 60 characters
  @max_name_length 60

  # The explanation of each kind of entity that is sent with a request
  @info %{
    assets: "  Assets are valuable resources or data, that need to be protected.\n",
    threats:
      "Threats are any potential event or action that can compromise the security of a system, organisation, or individual. Threats are not the negative outcome, i.e. not the loss, damage, or harm resulting from the exploitation of vulnerabilities by threats.",
    risks:
      "Risks are the potential negative outcome — loss, damage, or harm resulting from the exploitation of vulnerabilities by threats.\n",
    mitigations:
      "Mitigations are strategies and measures put in place to mitigate the risks of a particular threat.\n"
  }

  @quota_ai_requests_per_month "ai_requests_per_month"

  @doc """
  Runs an AI task for the scope: checks the quota of the organisation, records the
  usage, and calls `fun`.

  The call blocks until `fun` has returned. Run it in a separate process, for
  example with `ThreatShieldWeb.AiSuggestions.request/3`.
  """
  def run_task(%Scope{organisation: %Organisation{} = org} = scope, fun)
      when is_function(fun, 0) do
    case QuotaManager.check_quota(org, @quota_ai_requests_per_month, 1) do
      {:ok, :quota_available} ->
        {:ok, _usage} = protocol_quota_usage(scope, "AI request")
        {:ok, fun.()}

      {:error, :quota_exceeded} ->
        Logger.warning("AI quota exceeded for organisation '#{org.name}'")
        {:error, :quota_exceeded}
    end
  end

  # Attribute suggestions

  def suggest_values(%DynamicAttribute{name: name, description: description}) do
    # {resource_name_plural}": [{"name": _, "description": _}, _ ]}."
    system_prompt = """
    You are a software engineer. Your answer is in valid JSON format like so {"suggestions": [{"value": _}, _ ]}.
    """

    user_prompt = """
    Suggest 10 examples of typical values for an attribute with the name "#{name}". The user-facing description of the attribute is "#{description}".
    """

    make_chatgpt_request(system_prompt, user_prompt, &get_attribute_suggestions_from_response/1)
  end

  defp get_attribute_suggestions_from_response(response) do
    get_content_from_reponse(response, "suggestions")
    |> Enum.map(fn %{"value" => n} -> n end)
  end

  defp get_general_job_description(%Organisation{} = organisation) do
    """
    You are a threat modelling assistant at "#{organisation.name}".
    #{Organisation.describe(organisation)}
    """
  end

  defp get_response_format_description(resource_name_plural) do
    """
    Your response should comprise five response items, each item has a name and a description. The name should be up to 40 characters, the descriptions should be between 400 and 1000 characters long. The result must be valid JSON in this format:

    {"#{resource_name_plural}": [{"name": _, "description": _}, _ ]}
    """
  end

  # Suggestions for assets, threats, risks, and mitigations

  def suggest_assets(%Scope{} = scope) do
    case scope do
      %{system: %System{} = system} ->
        suggest(:assets, system.organisation, system.assets,
          info:
            "  Assets are valuable resources or data for a particular system, that need to be protected.\n",
          focus: ~s( The assets should be specific to the system "#{system.name}".)
        )

      %{organisation: %Organisation{} = organisation} ->
        suggest(:assets, organisation, organisation.assets)
    end
  end

  def suggest_threats(%Scope{} = scope) do
    # order is important here, as the most specific scope should be matched first
    case scope do
      %{asset: %Asset{} = asset, system: %System{} = system} ->
        suggest(:threats, asset.organisation, asset.threats,
          focus:
            " The threats should be specific to the system the system '#{system.name}'  and the asset '#{asset.name}'"
        )

      %{asset: %Asset{} = asset} ->
        suggest(:threats, asset.organisation, asset.threats,
          focus: " The threats should be specific to the asset '#{asset.name}'"
        )

      %{system: %System{} = system} ->
        suggest(:threats, system.organisation, system.threats,
          focus: " The threats should be specific to the system '#{system.name}'"
        )

      %{organisation: %Organisation{} = organisation} ->
        suggest(:threats, organisation, organisation.threats)
    end
  end

  def suggest_risks_for_threat(%Scope{} = _scope, %Threat{} = threat) do
    suggest(:risks, threat.organisation, threat.risks,
      focus: ~s( The risks should relate exclusively to the threat "#{threat.name}".)
    )
  end

  def suggest_mitigations_for_risk(%Scope{} = _scope, %Risk{} = risk) do
    system_exclusivity =
      if is_nil(risk.threat.system) do
        ""
      else
        """
        The only relvant system in this context is "#{risk.threat.system.name}".
        """
      end

    suggest(:mitigations, risk.threat.organisation, risk.mitigations,
      focus:
        ~s( The mitigations should relate exclusively to the risk "#{risk.name}" and the threat "#{risk.threat.name}".),
      extra: system_exclusivity
    )
  end

  # Asks for five suggestions of the given kind.
  #
  # `existing` are the entities of this kind that are known already. Options:
  #   * `:info` - replaces the default explanation of the kind
  #   * `:focus` - a sentence that narrows the assignment, e.g. to one system
  #   * `:extra` - a further part at the end of the prompt
  defp suggest(kind, %Organisation{} = organisation, existing, opts \\ []) do
    {system_prompt, user_prompt} = prompts(kind, organisation, existing, opts)

    make_chatgpt_request(system_prompt, user_prompt, &get_suggestions_from_response(&1, kind))
  end

  defp prompts(kind, %Organisation{} = organisation, existing, opts) do
    plural = Atom.to_string(kind)

    existing_names =
      if Enum.empty?(existing) do
        ""
      else
        "I already know about the following #{plural}:\n\n" <>
          Enum.map_join(existing, "\n", fn e -> e.name end)
      end

    assignment =
      "Please suggest five additional #{plural} that are different from the existing ones." <>
        Keyword.get(opts, :focus, "") <> "\n"

    user_prompt =
      ([
         get_response_format_description(plural),
         Keyword.get(opts, :info, @info[kind]),
         existing_names,
         assignment
       ] ++ List.wrap(opts[:extra]))
      |> Enum.join(" ")

    {get_general_job_description(organisation), user_prompt}
  end

  # OpenAI

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

    case open_ai_client().chat_completion(
           model: @open_ai_model,
           messages: messages
         ) do
      {:ok, response} ->
        response_extractor.(response)

      {:error, %{"error" => error}} ->
        {:error, error}

      {:error, :timeout} ->
        {:error, :timeout}
    end
  end

  # The client module can be replaced in the configuration, e.g. for tests.
  defp open_ai_client() do
    Application.get_env(:threat_shield, :open_ai_client, OpenAI)
  end

  defp get_content_from_reponse(response, root_key) do
    [first_choice | _] = response.choices
    %{"message" => message} = first_choice
    %{"content" => raw_response_string} = message

    case Jason.decode(raw_response_string) do
      {:error, error} ->
        Logger.error("Failed to decode response from OpenAI: #{inspect(error)}")
        []

      {:ok, data} ->
        %{^root_key => content} = data
        content
    end
  end

  defp get_suggestions_from_response(response, kind) do
    get_content_from_reponse(response, Atom.to_string(kind))
    |> Enum.map(fn %{"name" => n, "description" => d} ->
      struct(@schemas[kind], name: String.slice(n, 0, @max_name_length), description: d)
    end)
  end

  # Quotas

  defp protocol_quota_usage(%Scope{} = scope, message) do
    QuotaManager.add_usage(
      scope.organisation,
      scope.user,
      @quota_ai_requests_per_month,
      1.0,
      message
    )
  end
end
