defmodule ThreatShield.AI do
  def suggest_initial_threats() do
    prompt = "Give me a threat analysis for my vacation in Paris."

    case OpenAI.completions(
           model: "davinci",
           prompt: prompt,
           max_tokens: 50
         ) do
      {:ok, response} ->
        {:ok, response}

      {:error, %{"error" => error}} ->
        {:error, error}
    end
  end
end
