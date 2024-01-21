defmodule ThreatShield.Exporters.ExcelExporter do
  alias Elixlsx.Workbook
  alias Elixlsx.Sheet

  alias ThreatShield.Threats.Threat
  alias ThreatShield.Systems.System
  alias ThreatShield.Assets.Asset

  def export(threats) do
    # Add your header row, if necessary
    header_row = [header("Name"), header("System"), header("Asset"), header("Description")]

    rows =
      threats
      |> Enum.map(fn %Threat{} = threat ->
        [threat.name, system_name(threat), asset_name(threat), threat.description]
      end)

    sheet =
      %Sheet{
        name: "Threats",
        rows: [header_row] ++ rows
      }
      |> Sheet.set_col_width("A", 50)
      |> Sheet.set_col_width("B", 25)
      |> Sheet.set_col_width("C", 25)
      |> Sheet.set_col_width("D", 200)

    %Workbook{sheets: [sheet]}
    |> Elixlsx.write_to_memory("ThreatModel.xlsx")
    |> case do
      {:ok, {_filename, content}} -> {:ok, content}
      {:error, reason} -> {:error, reason}
    end
  end

  # labels

  def system_name(%Threat{} = threat), do: system_name(threat.system)

  def system_name(%System{} = system), do: system.name

  def system_name(_), do: nil

  def asset_name(%Threat{} = threat), do: asset_name(threat.asset)

  def asset_name(%Asset{} = asset), do: asset.name

  def asset_name(_), do: nil

  # utiles

  defp header(label, size \\ 12) do
    [label, bold: true, size: size]
  end
end
