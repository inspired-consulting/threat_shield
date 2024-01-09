defmodule ThreatShield.Breadcrumbs do
  alias ThreatShield.Scope

  def relevant_url_parts() do
    %{
      "organisations" => :organisations,
      "assets" => :assets,
      "systems" => :systems,
      "threats" => :threats,
      "risks" => :risks,
      "mitigations" => :mitigations,
      "members" => :members
    }
  end

  defp breadcrumb_lookup() do
    %{
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
  end

  def generate_path(breadcrumb, all_breadcrumbs, context) do
    all_breadcrumbs
    |> Enum.reverse()
    |> Enum.drop_while(fn b -> b != breadcrumb end)
    |> Enum.reverse()
    |> Enum.map(fn b -> Map.get(breadcrumb_lookup(), b) end)
    |> Enum.map(fn b -> Map.get(b, :path) end)
    |> Enum.join("/")
    |> fill_in_ids(context)
  end

  def get_name(breadcrumb) do
    %{name: name} = Map.get(breadcrumb_lookup(), breadcrumb)
    name
  end

  defp replace_chunk(chunk, %{scope: %Scope{} = scope} = context) do
    case chunk do
      ":org_id" -> id(scope.organisation)
      ":sys_id" -> id(scope.system)
      ":threat_id" -> id(scope.organisation)
      ":risk_id" -> id(context[:risk])
      _ -> chunk
    end
  end

  defp replace_chunk(chunk, context) do
    case chunk do
      ":org_id" -> context[:organisation].id
      ":threat_id" -> context[:threat].id
      ":sys_id" -> context[:system].id
      ":risk_id" -> context[:risk].id
      _ -> chunk
    end
  end

  defp fill_in_ids(path, context) do
    path
    |> String.split("/")
    |> Enum.map(fn chunk -> replace_chunk(chunk, context) end)
    |> Enum.join("/")
  end

  defp id(nil), do: nil
  defp id(entity), do: entity.id
end
