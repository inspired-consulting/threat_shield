defmodule ThreatShieldWeb.Breadcrumbs do
  use Phoenix.Component
  import ThreatShieldWeb.CoreComponents

  require Logger
  alias ThreatShield.Scope

  @breadcrumb_def %{
    :home => %{name: "Home", path: ""},
    :organisations => %{name: "Organisation", path: "organisations/:org_id"},
    :assets => %{name: "Asset", path: "assets/:asset_id"},
    :systems => %{name: "System", path: "systems/:sys_id"},
    :threats => %{name: "Threat", path: "threats/:threat_id"},
    :risks => %{name: "Risk", path: "risks/:risk_id"},
    :mitigations => %{
      name: "Mitigation",
      path: "mitigations/:mitigation_id"
    },
    :members => %{
      name: "Members",
      path: "members"
    }
  }

  attr :breadcrumbs, :list, required: true
  attr :context, :map, required: true

  def breadcrumbs(assigns) do
    assigns = assign(assigns, :size, length(assigns.breadcrumbs))

    ~H"""
    <nav class="ts-container flex text-gray-500 text-sm font-medium" aria-label="breadcrumb">
      <ol class="inline-flex items-center space-x-1 md:space-x-3">
        <.breadcrumb_item
          :for={{breadcrumb, index} <- Enum.with_index(@breadcrumbs)}
          type={index_to_item_type(index, @size)}
          navigate={generate_path(breadcrumb, assigns.breadcrumbs, @context)}
          text={get_label(breadcrumb, @context)}
        />
      </ol>
    </nav>
    """
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
      <.link navigate="/organisations" class="inline-flex items-center text-sm font-medium">
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

  # utils

  def generate_path(breadcrumb, all_breadcrumbs, context) do
    all_breadcrumbs
    |> Enum.reverse()
    |> Enum.drop_while(fn b -> b != breadcrumb end)
    |> Enum.reverse()
    |> Enum.map(fn b -> Map.get(@breadcrumb_def, b) end)
    |> Enum.map(fn b -> Map.get(b, :path) end)
    |> Enum.join("/")
    |> fill_in_ids(context)
  end

  # internal

  defp get_label(chunk, context) do
    case chunk do
      :home ->
        "Home"

      :organisations ->
        name(context[:organisation])

      :systems ->
        name(context[:system])

      :assets ->
        name(context[:asset])

      :threats ->
        name(context[:threat])

      :risks ->
        name(context[:risk])

      :mitigations ->
        name(context[:mitigation])

      _ ->
        Logger.warning("Unknown breadcrumb chunk: #{inspect(chunk)}")
        %{name: name} = Map.get(@breadcrumb_def, chunk)
        name
    end
  end

  defp fill_in_ids(path, context) do
    path
    |> String.split("/")
    |> Enum.map(fn chunk -> replace_chunk(chunk, context) end)
    |> Enum.join("/")
  end

  defp replace_chunk(chunk, %{scope: %Scope{} = scope} = context) do
    case chunk do
      ":org_id" -> id(scope.organisation)
      ":sys_id" -> id(scope.system)
      ":asset_id" -> id(scope.asset)
      ":threat_id" -> id(scope.threat)
      ":risk_id" -> id(context[:risk])
      _ -> chunk
    end
  end

  defp replace_chunk(chunk, context) do
    case chunk do
      ":org_id" -> id(context[:organisation])
      ":sys_id" -> id(context[:system])
      ":asset_id" -> id(context[:asset])
      ":threat_id" -> id(context[:threat])
      ":risk_id" -> id(context[:risk])
      _ -> chunk
    end
  end

  defp id(nil), do: nil
  defp id(entity), do: entity.id

  defp name(nil), do: nil
  defp name(entity), do: entity.name
end
