defmodule ThreatShield.Breadcrumbs do
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

  def breadcrumb_lookup() do
    %{
      :home => %{name: "Home", path: "/dashboard"},
      :organisations => %{name: "Organisation", path: "/organisations/:org_id"},
      :assets => %{name: "Asset", path: "/organisations/:org_id/assets/:asset_id"},
      :systems => %{name: "System", path: "/organisations/:org_id/systems/:sys_id"},
      :threats => %{name: "Threat", path: "/organisations/:org_id/threats/:threat_id"},
      :risks => %{name: "Risk", path: "/organisations/:org_id/threats/:threat_id/risks/:risk_id"},
      :mitigations => %{
        name: "Mitigation",
        path:
          "/organisations/:org_id/threats/:threat_id/risks/:risk_id/mitigations/:mitigation_id"
      },
      :members => %{
        name: "Members",
        path: "organisations/:org_id/members"
      }
    }
  end

  defp replace_chunk(chunk, context) do
    case chunk do
      ":org_id" -> context[:organisation].id
      ":threat_id" -> context[:threat].id
      ":risk_id" -> context[:risk].id
      _ -> chunk
    end
  end

  def fill_in_ids(path, context) do
    path
    |> String.split("/")
    |> Enum.map(fn chunk -> replace_chunk(chunk, context) end)
    |> Enum.join("/")
  end
end
