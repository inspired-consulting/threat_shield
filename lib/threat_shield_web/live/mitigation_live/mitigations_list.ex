defmodule ThreatShieldWeb.MitigationLive.MitigationsList do
  use ThreatShieldWeb, :live_component

  alias ThreatShield.AI
  alias ThreatShield.Scope
  alias ThreatShieldWeb.AiSuggestions

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
            <.link :if={may?(@scope, :create_mitigation)} patch={@origin <> "/mitigations/new"}>
              <.button_primary>
                <.icon name="hero-cursor-arrow-ripple" class="mr-1 mb-1" /><%= dgettext(
                  "mitigations",
                  "New Mitigation"
                ) %>
              </.button_primary>
            </.link>
            <.link>
              <.button_magic
                :if={may?(@scope, :create_mitigation)}
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
  def handle_event("suggest_mitigations", _params, socket) do
    risk = socket.assigns.risk
    scope = socket.assigns.scope

    socket
    |> AiSuggestions.request(scope, fn -> AI.suggest_mitigations_for_risk(scope, risk) end)
    |> noreply()
  end

  @impl true
  def handle_event("apply_selection", params, socket) do
    scope = %Scope{} = socket.assigns.scope
    risk = socket.assigns.risk

    new_mitigations =
      socket
      |> AiSuggestions.selected(params)
      |> Enum.map(fn s -> create_mitigation(scope.user, risk, s) end)

    socket
    |> assign(:show_suggest_dialog, false)
    |> assign(:mitigations, socket.assigns.mitigations ++ new_mitigations)
    |> noreply()
  end

  @impl true
  def handle_async(:ai_suggestions, result, socket) do
    socket
    |> AiSuggestions.handle_result(result)
    |> noreply()
  end

  defp create_mitigation(%User{} = user, %Risk{} = risk, %{name: name, description: desc}) do
    {:ok, mitigation} =
      Mitigations.create_mitigation(user, risk, %{name: name, description: desc})

    mitigation
  end
end
