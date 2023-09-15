defmodule ThreatShieldWeb.Suggestions do
  use Phoenix.Component
  import ThreatShieldWeb.CoreComponents
  alias Phoenix.LiveView.JS

  attr :suggestions, :list, required: true
  attr :entity_name, :string, required: true

  def suggestions(assigns) do
    ~H"""
    <.table :if={not Enum.empty?(@suggestions)} id={"#{@entity_name}_suggestions"} rows={@suggestions}>
      <:col :let={suggestion} label="Name"><%= suggestion.name %></:col>
      <:col :let={suggestion} label="Description"><%= suggestion.description %></:col>

      <:action :let={suggestion}>
        <.link phx-click={JS.push("ignore_" <> @entity_name, value: %{description: suggestion.description})}>
          Ignore
        </.link>
        <.link phx-click={JS.push("add_" <> @entity_name, value: %{name: suggestion.name, description: suggestion.description})}>
          Add
        </.link>
      </:action>
    </.table>
    """
  end
end
