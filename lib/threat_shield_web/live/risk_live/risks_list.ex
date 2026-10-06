defmodule ThreatShieldWeb.RiskLive.RisksList do
  use ThreatShieldWeb, :live_component

  alias ThreatShield.AI
  alias ThreatShield.Scope
  alias ThreatShieldWeb.AiSuggestions
  alias ThreatShield.Risks
  alias ThreatShield.Threats.Threat
  alias ThreatShield.Accounts.User
  import ThreatShieldWeb.Helpers

  @moduledoc """
  This component renders a list of risks for a given threat.
  """

  @impl true
  def render(assigns) do
    ~H"""
    <div class="risks">
      <div class="mt-4 px-8 py-6 bg-white rounded-lg shadow">
        <.stacked_list_header>
          <:name>
            <span class="text-gray-700 inline-block">
              <Icons.risk_icon class="w-5 h-5" />
            </span>
            <%= dgettext("risks", "Risks") %>
          </:name>

          <:subtitle>
            <%= dgettext("risks", "Risk: short description") %>
          </:subtitle>

          <:buttons>
            <.link :if={may?(@scope, :create_risk)} patch={@origin <> "/risks/new"}>
              <.button_primary>
                <.icon name="hero-hand-raised" class="mr-1 mb-1" /><%= dgettext(
                  "risks",
                  "New Risk"
                ) %>
              </.button_primary>
            </.link>
            <.link>
              <.button_magic
                :if={may?(@scope, :create_risk)}
                phx-click="suggest_risks"
                phx-target={@myself}
              >
                <.icon name="hero-sparkles" class="mr-1 mb-1" /><%= dgettext(
                  "risks",
                  "Suggest Risks"
                ) %>
              </.button_magic>
            </.link>
          </:buttons>
        </.stacked_list_header>
        <.stacked_list
          :if={not Enum.empty?(@risks)}
          id={"risks_for_threat_#{@threat.id}"}
          rows={@risks}
          row_click={fn risk -> JS.navigate(link_to(risk, @scope)) end}
        >
          <:col :let={risk}>
            <%= risk.name %>
          </:col>
          <:col :let={risk}>
            <.risk_status_badge status={risk.status} />
          </:col>
          <:col :let={risk}><%= risk.description %></:col>
          <:col :let={risk}>
            <.criticality_badge value={risk.severity} title={dgettext("risks", "Severity")} />
          </:col>
        </.stacked_list>

        <p :if={Enum.empty?(@risks)} class="mt-4">
          There are no risks. Please add them manually or let the AI assistant make some suggestions.
        </p>
      </div>
      <.modal
        :if={assigns[:show_suggest_dialog] == true}
        id="suggest-risks-modal"
        show
        on_cancel={JS.navigate(@origin)}
      >
        <.suggestions_dialog
          title={dgettext("risks", "Suggested Risks")}
          listener={@myself}
          scope={@scope}
          suggestions={assigns[:ai_suggestions]}
        />
      </.modal>
    </div>
    """
  end

  @impl true
  def update(assigns, socket) do
    socket
    |> assign(assigns)
    |> ok()
  end

  @impl true
  def handle_event("suggest_risks", _params, socket) do
    threat = socket.assigns.threat
    scope = socket.assigns.scope

    socket
    |> AiSuggestions.request(scope, fn -> AI.suggest_risks_for_threat(scope, threat) end)
    |> noreply()
  end

  @impl true
  def handle_event("apply_selection", params, socket) do
    scope = %Scope{} = socket.assigns.scope
    threat = socket.assigns.threat

    new_risks =
      socket
      |> AiSuggestions.selected(params)
      |> Enum.map(fn s -> create_risk(scope.user, threat, s) end)

    socket
    |> assign(:show_suggest_dialog, false)
    |> assign(:risks, socket.assigns.risks ++ new_risks)
    |> noreply()
  end

  @impl true
  def handle_async(:ai_suggestions, result, socket) do
    socket
    |> AiSuggestions.handle_result(result)
    |> noreply()
  end

  defp create_risk(%User{} = user, %Threat{} = threat, %{name: name, description: desc}) do
    {:ok, risk} = Risks.create_risk(user, threat.id, %{name: name, description: desc})
    risk
  end
end
