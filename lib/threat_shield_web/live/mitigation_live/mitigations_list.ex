defmodule ThreatShieldWeb.MitigationLive.MitigationsList do
  use ThreatShieldWeb, :live_component

  alias ThreatShield.AI
  alias ThreatShield.Scope
  alias ThreatShield.AI.AiSuggestion

  alias ThreatShield.Accounts.User
  alias ThreatShield.Risks.Risk
  alias ThreatShield.Mitigations

  @moduledoc """
  This component renders a list of mitigations for a given risk.
  """

  @impl true
  def render(assigns) do
    ~H"""
    <div class="mitigations">
      <div class="mt-4 px-8 py-6 bg-white rounded-lg shadow">
        <.stacked_list_header>
          <:name>
            <span class="text-gray-700 inline-block">
              <Icons.mitigation_icon class="w-5 h-5" />
            </span>
            <%= dgettext("mitigations", "Mitigations") %>
          </:name>

          <:subtitle>
            <%= dgettext(
              "mitigations",
              "Mitigations: short description"
            ) %>
          </:subtitle>

          <:buttons>
            <.link
              :if={ThreatShield.Members.Rights.may(:create_mitigation, @scope.membership)}
              patch={@origin <> "/mitigations/new"}
            >
              <.button_primary>
                <.icon name="hero-cursor-arrow-ripple" class="mr-1 mb-1" /><%= dgettext(
                  "mitigations",
                  "New Mitigation"
                ) %>
              </.button_primary>
            </.link>
            <.link>
              <.button_magic
                :if={ThreatShield.Members.Rights.may(:create_mitigation, @scope.membership)}
                phx-click="suggest_mitigations"
                phx-target={@myself}
              >
                <.icon name="hero-sparkles" class="mr-1 mb-1" /><%= dgettext(
                  "mitigations",
                  "Suggest Mitigations"
                ) %>
              </.button_magic>
            </.link>
          </:buttons>
        </.stacked_list_header>
        <.stacked_list
          :if={not Enum.empty?(@mitigations)}
          id={"mitigations_for_risk_#{@risk.id}"}
          rows={@mitigations}
          row_click={
            fn mitigation ->
              JS.navigate(
                @origin <>
                  "/mitigations/#{mitigation.id}"
              )
            end
          }
        >
          <:col :let={mitigation}>
            <%= mitigation.name %>
          </:col>
          <:col :let={mitigation}><.boolean_status_icon value={mitigation.is_implemented} /></:col>
          <:col :let={mitigation}>
            <.mitigation_status_badge status={mitigation.status} light />
          </:col>
          <:col :let={mitigation}><%= mitigation.description %></:col>
        </.stacked_list>

        <p :if={Enum.empty?(@mitigations)} class="mt-4">
          There are no mitigations. Please add them manually or let suggest some from the AI assistant.
        </p>
      </div>
      <.modal
        :if={assigns[:show_suggest_dialog] == true}
        id="suggest-mitigations-modal"
        show
        on_cancel={JS.navigate(@origin)}
      >
        <.suggestions_dialog
          title={dgettext("mitigations", "Suggested Mitigations")}
          listener={@myself}
          scope={@scope}
          suggestions={@ai_suggestions[:mitigations]}
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
  Will start a background task to suggest mitigations for the current scope
  When the task is finished, it will send a :new_ai_suggestion message to the current page.
  The page is expected to add the suggestions to the :ai_suggesstions assigns.
  """
  @impl true
  def handle_event("suggest_mitigations", _params, socket) do
    risk = socket.assigns.risk

    Task.Supervisor.async_nolink(ThreatShield.TaskSupervisor, fn ->
      new_mitigations =
        AI.suggest_mitigations_for_risk(risk)

      {:new_ai_suggestion,
       %AiSuggestion{result: new_mitigations, type: :mitigations, requestor: self()}}
    end)

    socket
    |> assign(:show_suggest_dialog, true)
    |> noreply()
  end

  @impl true
  def handle_event("apply_selection", %{"selected_suggestions" => selected_names}, socket) do
    scope = %Scope{} = socket.assigns.scope
    risk = socket.assigns.risk

    ai_suggestions = socket.assigns.ai_suggestions

    new_mitigations =
      ai_suggestions[:mitigations]
      |> Enum.filter(fn s -> Enum.member?(selected_names, s.name) end)
      |> Enum.map(fn s -> create_mitigation(scope.user, risk, s) end)

    socket
    |> assign(:show_suggest_dialog, false)
    |> assign(:mitigations, socket.assigns.mitigations ++ new_mitigations)
    |> noreply()
  end

  defp create_mitigation(%User{} = user, %Risk{} = risk, %{name: name, description: desc}) do
    {:ok, mitigation} = Mitigations.add_mitigation(user, risk.id, name, desc)
    mitigation
  end
end
