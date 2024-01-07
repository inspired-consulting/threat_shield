defmodule ThreatShieldWeb.Breadcrumbs do
  alias ThreatShield.Breadcrumbs
  use Phoenix.Component
  import ThreatShieldWeb.CoreComponents

  attr :breadcrumbs, :list, required: true
  attr :context, :map, required: true

  def breadcrumb(assigns) do
    assigns = assign(assigns, :size, length(assigns.breadcrumbs))

    ~H"""
    <nav class="ts-container flex text-gray-500 text-sm font-medium" aria-label="breadcrumb">
      <ol class="inline-flex items-center space-x-1 md:space-x-3">
        <.breadcrumb_item
          :for={{breadcrumb, index} <- Enum.with_index(@breadcrumbs)}
          type={index_to_item_type(index, @size)}
          navigate={generate_path(breadcrumb, assigns.breadcrumbs, @context)}
          text={get_text(breadcrumb)}
        />
      </ol>
    </nav>
    """
  end

  defp generate_path(breadcrumb, all_breadcrumbs, context) do
    Breadcrumbs.generate_path(breadcrumb, all_breadcrumbs, context)
  end

  defp get_text(breadcrumb) do
    Breadcrumbs.get_name(breadcrumb)
  end

  defp index_to_item_type(0, _size), do: "first"
  defp index_to_item_type(index, size) when index == size - 1, do: "last"
  defp index_to_item_type(_index, _size), do: "middle"

  attr :type, :string, default: "middle"
  attr :navigate, :string, default: "/"
  attr :text, :string, required: true

  defp breadcrumb_item(assigns) when assigns.type == "first" do
    ~H"""
    <li class="inline-flex items-center">
      <.link navigate="/dashboard" class="inline-flex items-center text-sm font-medium">
        <.icon name="hero-home" class="h-4 w-4" />
      </.link>
    </li>
    """
  end

  defp breadcrumb_item(assigns) when assigns.type == "last" do
    ~H"""
    <li aria-current="page">
      <div class="flex items-center">
        <.icon name="hero-chevron-right" class="h-4 w-4" />
        <span class="ml-1 text-sm font-medium md:ml-2">
          <%= @text %>
        </span>
      </div>
    </li>
    """
  end

  defp breadcrumb_item(assigns) do
    ~H"""
    <li>
      <div class="flex items-center">
        <.icon name="hero-chevron-right" class="h-4 w-4" />
        <.link navigate={@navigate} class="ml-1 text-sm font-medium md:ml-2 ">
          <%= @text %>
        </.link>
      </div>
    </li>
    """
  end
end
