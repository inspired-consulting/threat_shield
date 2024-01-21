defmodule ThreatShieldWeb.ExportController do
  use ThreatShieldWeb, :controller

  alias ThreatShield.Organisations
  alias ThreatShield.Exporters.ExcelExporter

  def export_to_excel(conn, %{"org_id" => org_id} = _params) do
    user = conn.assigns.current_user

    org = Organisations.get_organisation!(user, org_id)

    case ExcelExporter.export(org.threats) do
      {:ok, content} ->
        send_download(conn, {:binary, content},
          filename: "ThreatModel_#{org.name}.xlsx",
          content_disposition: "attachment",
          content_type: "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet"
        )

      {:error, reason} ->
        conn
        |> put_flash(:error, "Error exporting threats: #{inspect(reason)}")
        |> redirect(to: ~p"/organisations/#{org.id}")
    end
  end

  # internal
end
