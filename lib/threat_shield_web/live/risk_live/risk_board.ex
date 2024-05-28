defmodule ThreatShieldWeb.RiskLive.RiskBoard do
  use ThreatShieldWeb, :live_view

  alias ThreatShield.Members

  @moduledoc """
  See an overview of all risks in the organisation.
  """

  @impl true
  def render(assigns) do
    ~H"""
    <section class="w-full bg-white py-6 shadow-primary-200 shadow-sm">
      <div class="ts-container">
        <.header>
          <.h1><%= dgettext("risks", "Risk board") %></.h1>
          <.h3>
            <span class="text-gray-700 inline-block">
              <Icons.organisation_icon class="w-5 h-5" />
            </span>
            <%= @organisation.name %>
          </.h3>
        </.header>
        <div class="grid grid-cols-4 gap-2 mt-2 px-2 py-2 bg-primary-100">
          <.input_attribute attributes={@organisation.attributes}></.input_attribute>
        </div>
      </div>
    </section>
    """
  end

  @impl true
  def mount(%{"org_id" => org_id}, _session, socket) do
    user = socket.assigns.current_user
    organisation = Members.get_organisation!(user, org_id)

    socket
    |> assign(:organisation, organisation)
    |> ok()
  end
end
