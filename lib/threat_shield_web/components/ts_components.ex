defmodule ThreatShieldWeb.TsComponents do
  @moduledoc """
  Provides custom UI components for ThreatShield.
  """
  use Phoenix.Component

  alias ThreatShield.Scope

  use ThreatShieldWeb, :verified_routes
  import ThreatShieldWeb.CoreComponents
  import ThreatShieldWeb.Labels
  import ThreatShieldWeb.Gettext

  # big building blocks

  slot :name, required: false
  slot :description, required: false
  slot :status, required: false
  slot :attribute, required: false
  slot :custom, required: false
  slot :actions, required: false
  slot :links, required: true
  attr :columns, :integer, default: 2

  def entity_info(assigns) do
    ~H"""
    <section class="w-full bg-white pb-6 shadow-primary-200 shadow-sm">
      <div class="ts-container flex justify-between">
        <div class="min-h-10 pb-2">
          <.h1>
            <%= render_slot(@name) %>
          </.h1>
          <p class="text-sm leading-6 text-gray-600 font-normal">
            <%= render_slot(@description) %>
          </p>
          <div :if={@status != []} class="my-2">
            <%= render_slot(@status) %>
          </div>
        </div>
        <div class="flex gap-2">
          <div :if={@actions != []}>
            <%= render_slot(@actions) %>
          </div>
          <.dropdown links={@links}></.dropdown>
        </div>
      </div>
      <div class="ts-container">
        <%= if @attribute != [] do %>
          <div class={[
            "w-full grid gap-4 mt-0 px-6 py-4 bg-primary-100",
            "grid-cols-#{@columns}"
          ]}>
            <%= render_slot(@attribute) %>
          </div>
        <% end %>
        <%= if @custom != [] do %>
          <%= render_slot(@custom) %>
        <% end %>
      </div>
    </section>
    """
  end

  attr :scope, Scope, required: true
  attr :suggestions, :list, default: []
  attr :listener, :string, required: true
  attr :title, :string, default: "Suggestions"
  attr :loading_title, :string, default: "Asking AI assistant for suggestions"

  def suggestions_dialog(assigns) do
    ~H"""
    <div class="min-h-64 lg:min-w-5xl">
      <div :if={has_suggestions?(assigns)}>
        <.header>
          <%= @title %>
        </.header>

        <.form :let={_f} phx-submit="apply_selection" phx-target={@listener}>
          <.table id="asset_suggestions" rows={@suggestions}>
            <:col :let={suggestion} label={dgettext("common", "Select")}>
              <input type="checkbox" name="selected_suggestions[]" value={suggestion.name} />
            </:col>
            <:col :let={suggestion} label="Name"><%= suggestion.name %></:col>
            <:col :let={suggestion} label="Description"><%= suggestion.description %></:col>
          </.table>

          <div>
            <.button_primary phx-disable-with="Saving...">
              <%= dgettext("common", "Apply selection") %>
            </.button_primary>
          </div>
        </.form>
      </div>

      <div :if={not has_suggestions?(assigns)}>
        <.header>
          <%= @loading_title %>
        </.header>

        <ThreatShieldWeb.Spinner.spinner />
      </div>
    </div>
    """
  end

  defp has_suggestions?(assigns) do
    not is_nil(assigns[:suggestions]) and not Enum.empty?(assigns[:suggestions])
  end

  # simple components

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

  def criticality_badge(assigns) do
    ~H"""
    <span
      class={[
        "inline-block text-center text-gray-900 font-medium rounded-full appearance-none cursor-pointer border-2",
        @size_classes
      ]}
      style={"background-color: #{color_code_for_criticality(@value, 0.4)}; border-color: #{color_code_for_criticality(@value, 1)}"}
      title={@title}
    >
      <%= @value %>
    </span>
    """
  end

  attr :status, :string, default: nil

  def risk_status_badge(assigns) do
    ~H"""
    <span class={[
      "inline-flex items-center rounded-md px-4 py-1 text-xs font-bold text-center leading-1 text-gray-100",
      bg_class_for_risk_status(assigns.status)
    ]}>
      <%= risk_status_label(assigns.status) %>
    </span>
    """
  end

  attr :status, :string, default: nil
  attr :light, :boolean, default: false

  def mitigation_status_badge(assigns) do
    ~H"""
    <span class={[
      "inline-flex items-center rounded-md px-4 py-1 text-xs font-bold text-center leading-1",
      if(@light, do: "bg-neutral-400 text-white", else: "bg-neutral-600 text-gray-100")
    ]}>
      <%= mitigation_status_label(assigns.status) %>
    </span>
    """
  end

  attr :value, :boolean, default: false

  def boolean_status_icon(assigns) do
    ~H"""
    <%= if @value do %>
      <span class="bg-green-200 rounded-full p-1">
        <.icon name="hero-check" class="text-green-600" />
      </span>
    <% else %>
      <span class="bg-red-200 rounded-full p-1">
        <.icon name="hero-x-mark" class="text-red-100 mb-0.5" />
      </span>
    <% end %>
    """
  end

  # utilities

  def color_code_for_criticality(criticality, opacity \\ 1.0)

  def color_code_for_criticality(criticality, opacity) when is_number(criticality) do
    red = if criticality < 2.5, do: trunc(220 * criticality / 2.5), else: 220
    green = if criticality > 2.5, do: trunc(220 * (5 - criticality) / 2.5), else: 220

    blue = 0
    "rgba(#{red}, #{green}, #{blue}, #{opacity})"
  end

  def color_code_for_criticality(criticality, opacity) when is_binary(criticality) do
    case Float.parse(criticality) do
      {criticality, _} -> color_code_for_criticality(criticality, opacity)
      :error -> color_code_for_criticality(0)
    end
  end

  def color_code_for_criticality(_criticality, opacity), do: "rgba(200, 200, 200, #{opacity})"

  def bg_class_for_risk_status(status) do
    case status do
      :mitigated -> "bg-green-700"
      :identified -> "bg-red-500"
      :assessed -> "bg-orange-600"
      _ -> "bg-neutral-600"
    end
  end
end
