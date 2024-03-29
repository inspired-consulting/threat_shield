defmodule ThreatShieldWeb.ThreatLive.ThreatSuggestions do
  use Phoenix.Component
  import ThreatShieldWeb.CoreComponents

  alias ThreatShield.Scope
  alias Phoenix.LiveView.JS

  @moduledoc """
  Provides a component for displaying suggestions for threats.
  """

  attr :scope, Scope, required: true
  attr :suggestions, :list, default: []
  attr :listener, :string, required: true

  def suggestions_dialog(assigns) do
    ~H"""
    <.table :if={has_suggestions?(assigns)} id="threat_suggestions" rows={@suggestions}>
      <:col :let={suggestion} label="Name"><%= suggestion.name %></:col>
      <:col :let={suggestion} label="Description"><%= suggestion.description %></:col>

      <:action :let={suggestion}>
        <.link
          phx-click={JS.push("ignore_threat", value: %{description: suggestion.description})}
          phx-target={@listener}
        >
          Ignore
        </.link>
        <.link
          phx-click={
            JS.push("add_threat",
              value: %{name: suggestion.name, description: suggestion.description}
            )
          }
          phx-target={@listener}
        >
          Add
        </.link>
      </:action>
    </.table>
    """
  end

  defp has_suggestions?(assigns) do
    not is_nil(assigns[:suggestions]) and not Enum.empty?(assigns[:suggestions])
  end
end
