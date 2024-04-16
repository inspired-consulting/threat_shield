defmodule ThreatShieldWeb.RiskLive.RisksList do
  use ThreatShieldWeb, :live_component

  alias ThreatShield.AI
  alias ThreatShield.Scope
  alias ThreatShield.AI.AiSuggestion
  alias ThreatShield.Risks
  alias ThreatShield.Threats.Threat
  alias ThreatShield.Accounts.User

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
            <.link
              :if={ThreatShield.Members.Rights.may(:create_risk, @scope.membership)}
              patch={@origin <> "/risks/new"}
            >
              <.button_primary>
                <.icon name="hero-hand-raised" class="mr-1 mb-1" /><%= dgettext(
                  "risks",
                  "New Risk"
                ) %>
              </.button_primary>
            </.link>
            <.link>
              <.button_magic
                :if={ThreatShield.Members.Rights.may(:create_risk, @scope.membership)}
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
          row_click={fn risk -> JS.navigate(@origin <> "/risks/#{risk.id}") end}
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
          suggestions={@ai_suggestions[:risks]}
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

  @doc """
  Will start a background task to suggest risks for the current threat.
  When the task is finished, it will send a :new_ai_suggestion message to the current page.
  The page is expected to add the suggestions to the :ai_suggesstions assigns.
  """
  @impl true
  def handle_event("suggest_risks", _params, socket) do
    threat = socket.assigns.threat
    scope = socket.assigns.scope

    AI.run_task(scope, fn ->
      new_risks =
        AI.suggest_risks_for_threat(scope, threat)

      {:new_ai_suggestion, %AiSuggestion{result: new_risks, type: :risks, requestor: self()}}
    end)
    |> case do
      {:ok, _} ->
        socket
        |> assign(:show_suggest_dialog, true)
        |> noreply()

      {:error, :quota_exceeded} ->
        socket
        |> put_flash(:error, dgettext("common", "Your quota for AI suggestions is exceeded."))
        |> push_navigate(to: socket.assigns.origin)
        |> noreply()
    end
  end

  @impl true
  def handle_event("apply_selection", %{"selected_suggestions" => selected_names}, socket) do
    scope = %Scope{} = socket.assigns.scope
    threat = socket.assigns.threat

    ai_suggestions = socket.assigns.ai_suggestions

    new_risks =
      ai_suggestions[:risks]
      |> Enum.filter(fn s -> Enum.member?(selected_names, s.name) end)
      |> Enum.map(fn s -> create_risk(scope.user, threat, s) end)

    socket
    |> assign(:show_suggest_dialog, false)
    |> assign(:risks, socket.assigns.risks ++ new_risks)
    |> noreply()
  end

  @impl true
  def handle_event("apply_selection", _params, socket) do
    socket
    |> put_flash(:error, dgettext("common", "No suggestions selected."))
    |> assign(:show_suggest_dialog, false)
    |> noreply()
  end

  defp create_risk(%User{} = user, %Threat{} = threat, %{name: name, description: desc}) do
    {:ok, risk} = Risks.add_risk(user, threat.id, name, desc)
    risk
  end
end
