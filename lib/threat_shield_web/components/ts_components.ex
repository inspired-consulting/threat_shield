defmodule ThreatShieldWeb.TsComponents do
  @moduledoc """
  Provides custom UI components for ThreatShield.
  """
  use Phoenix.Component

  use ThreatShieldWeb, :verified_routes
  import ThreatShieldWeb.CoreComponents

  attr :id, :any, default: nil
  attr :name, :any
  attr :label, :string, default: nil
  attr :value, :any

  attr :field, Phoenix.HTML.FormField,
    doc: "a form field struct retrieved from the form, for example: @form[:email]"

  attr :errors, :list, default: []
  slot :inner_block

  attr :rest, :global,
    include: ~w(accept autocomplete capture cols disabled form list max maxlength min minlength
                multiple pattern placeholder readonly required rows size step)

  def criticality_picker(assigns) do
    ~H"""
    <.input id={@id} field={@field} type="range" label={@label} min="0" max="4" {@rest} />
    """
  end

  attr :id, :any, default: nil
  attr :name, :any
  attr :label, :string, default: nil
  attr :value, :any

  attr :rest, :global,
    include: ~w(accept autocomplete capture cols disabled form list max maxlength min minlength
                multiple pattern placeholder readonly required rows size step)

  def criticality_display(assigns) do
    ~H"""
    <.input id={@id} type="range" name={@name} value={@value} label={@label} {@rest} />
    """
  end
end
