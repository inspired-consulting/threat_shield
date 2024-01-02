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
  attr :value, :any, default: 0.0
  attr :readonly, :boolean, default: false

  attr :field, Phoenix.HTML.FormField,
    doc: "a form field struct retrieved from the form, for example: @form[:email]"

  attr :errors, :list, default: []
  slot :inner_block

  attr :rest, :global,
    include: ~w(accept autocomplete capture cols disabled form list maxlength minlength
                multiple pattern placeholder required rows size step)

  def criticality_picker(assigns) do
    ~H"""
    <.input
      id={@id}
      field={@field}
      type="range"
      label={@label}
      min="0"
      max="5"
      step="0.1"
      readonly={@readonly}
      {@rest}
      style={"background-color: #{color_code_for_criticality(@field.value)}"}
    />
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
    <div class="flex justify-between">
      <.label for={@id}><%= @label %></.label>
      <span
        class="inline-block w-10 h-10 text-center leading-9 text-gray-800 font-semibold rounded-full appearance-none cursor-pointer border-2"
        style={"background-color: #{color_code_for_criticality(@value, 0.4)}; border-color: #{color_code_for_criticality(@value, 1)}"}
      >
        <%= @value %>
      </span>
    </div>
    """
  end

  attr :value, :any
  attr :title, :string, default: nil
  attr :size_classes, :string, default: "w-10 h-10 leading-9"

  def criticality_batch(assigns) do
    ~H"""
    <span
      class={[
        "inline-block text-center text-gray-800 font-semibold rounded-full appearance-none cursor-pointer border-2",
        @size_classes
      ]}
      style={"background-color: #{color_code_for_criticality(@value, 0.4)}; border-color: #{color_code_for_criticality(@value, 1)}"}
      title={@title}
    >
      <%= @value %>
    </span>
    """
  end

  # internal

  defp color_code_for_criticality(criticality, opacity \\ 1.0)

  defp color_code_for_criticality(criticality, opacity) when is_number(criticality) do
    red = if criticality < 2.5, do: trunc(220 * criticality / 2.5), else: 220
    green = if criticality > 2.5, do: trunc(220 * (5 - criticality) / 2.5), else: 220

    blue = 0
    "rgba(#{red}, #{green}, #{blue}, #{opacity})"
  end

  defp color_code_for_criticality(criticality, opacity) when is_binary(criticality) do
    case Float.parse(criticality) do
      {criticality, _} -> color_code_for_criticality(criticality, opacity)
      :error -> color_code_for_criticality(0)
    end
  end

  defp color_code_for_criticality(_criticality, opacity), do: "rgba(100, 100, 100, #{opacity})"
end
