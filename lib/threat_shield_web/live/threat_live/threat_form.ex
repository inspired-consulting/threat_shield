defmodule ThreatShieldWeb.ThreatLive.ThreatForm do
  use ThreatShieldWeb, :live_component

  import ThreatShieldWeb.FormHelpers

  alias ThreatShield.Scope
  alias ThreatShield.Threats

  import ThreatShieldWeb.Gettext

  @impl true
  def render(assigns) do
    ~H"""
    <div class="max-w-3xl">
      <.header>
        <%= @title %>
      </.header>

      <p class="help-text">
        <%= dgettext(
          "threats",
          "Threat: long description"
        ) %>
      </p>

      <.simple_form
        for={@form}
        id="threat-form"
        phx-target={@myself}
        phx-change="validate"
        phx-submit="save"
      >
        <.input field={@form[:name]} type="text" label={dgettext("threats", "Name")} required />
        <.input
          field={@form[:description]}
          type="text"
          label={dgettext("threats", "Description")}
          required
        />
        <.input
          :if={assigns[:system_options]}
          field={@form[:system_id]}
          type="select"
          label="System"
          options={@system_options}
        />
        <.input
          :if={assigns[:asset_options]}
          field={@form[:asset_id]}
          type="select"
          label="Asset"
          options={@asset_options}
        />
        <:actions>
          <.button_primary phx-disable-with={dgettext("common", "Saving...")} class="mt-2">
            <%= dgettext("threats", "Save Threat") %>
          </.button_primary>
        </:actions>
      </.simple_form>
    </div>
    """
  end

  @impl true
  def update(%{threat: threat} = assigns, socket) do
    changeset = Threats.change_threat(threat)

    socket
    |> assign(assigns)
    |> assign_form(changeset)
    |> ok()
  end

  @impl true
  def handle_event("validate", %{"threat" => threat_params}, socket) do
    changeset =
      socket.assigns.threat
      |> Threats.change_threat(threat_params)
      |> Map.put(:action, :validate)

    {:noreply, assign_form(socket, changeset)}
  end

  def handle_event("save", %{"threat" => threat_params}, socket) do
    save_threat(socket, socket.assigns.action, threat_params)
  end

  defp save_threat(socket, :edit_threat, threat_params) do
    scope = %Scope{} = socket.assigns.scope

    result = Threats.update_threat(scope.user, socket.assigns.threat, threat_params)

    socket
    |> handle_save_result(result, __MODULE__, "Threat updated successfully")
    |> noreply()
  end

  defp save_threat(socket, :new_threat, threat_params) do
    scope = %Scope{} = socket.assigns.scope

    result = Threats.create_threat(scope.user, scope.organisation, threat_params)
    socket = handle_save_result(socket, result, __MODULE__, "Threat created successfully")

    with {:ok, threat} <- result do
      notify_threat_list(id: socket.assigns.parent_id, added_threat: threat)
    end

    noreply(socket)
  end

  defp notify_threat_list(msg),
    do: send_update(self(), ThreatShieldWeb.ThreatLive.ThreatsList, msg)
end
