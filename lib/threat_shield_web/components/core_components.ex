defmodule ThreatShieldWeb.CoreComponents do
  @moduledoc """
  Provides core UI components.

  At the first glance, this module may seem daunting, but its goal is
  to provide some core building blocks in your application, such as modals,
  tables, and forms. The components are mostly markup and well documented
  with doc strings and declarative assigns. You may customize and style
  them in any way you want, based on your application growth and needs.

  The default components use Tailwind CSS, a utility-first CSS framework.
  See the [Tailwind CSS documentation](https://tailwindcss.com) to learn
  how to customize them or feel free to swap in another framework altogether.

  Icons are provided by [heroicons](https://heroicons.com). See `icon/1` for usage.
  """
  use Phoenix.Component

  use ThreatShieldWeb, :verified_routes
  alias(Phoenix.LiveView.JS)
  import ThreatShieldWeb.Gettext

  def h1(assigns) do
    ~H"""
    <h1 class="text-2xl font-bold leading-9 text-gray-900">
      <%= render_slot(@inner_block) %>
    </h1>
    """
  end

  def h2(assigns) do
    ~H"""
    <h2 class="text-gray-900 text-xl font-semibold">
      <%= render_slot(@inner_block) %>
    </h2>
    """
  end

  def h3(assigns) do
    ~H"""
    <h3 class="text-gray-900 text-lg font-medium leading-normal">
      <%= render_slot(@inner_block) %>
    </h3>
    """
  end

  @doc """
  Renders a modal.

  ## Examples

      <.modal id="confirm-modal">
        This is a modal.
      </.modal>

  JS commands may be passed to the `:on_cancel` to configure
  the closing/cancel event, for example:

      <.modal id="confirm" on_cancel={JS.navigate(~p"/posts")}>
        This is another modal.
      </.modal>

  """
  attr :id, :string, required: true
  attr :show, :boolean, default: false
  attr :on_cancel, JS, default: %JS{}
  slot :inner_block, required: true

  def modal(assigns) do
    ~H"""
    <div
      id={@id}
      phx-mounted={@show && show_modal(@id)}
      phx-remove={hide_modal(@id)}
      data-cancel={JS.exec(@on_cancel, "phx-remove")}
      class="relative z-50 hidden"
    >
      <div id={"#{@id}-bg"} class="bg-zinc-50/90 fixed inset-0 transition-opacity" aria-hidden="true" />
      <div
        class="fixed inset-0 overflow-y-auto"
        aria-labelledby={"#{@id}-title"}
        aria-describedby={"#{@id}-description"}
        role="dialog"
        aria-modal="true"
        tabindex="0"
      >
        <div class="flex min-h-full items-center justify-center">
          <div class="min-w-3xl p-4 sm:p-6 lg:py-8">
            <.focus_wrap
              id={"#{@id}-container"}
              phx-window-keydown={JS.exec("data-cancel", to: "##{@id}")}
              phx-key="escape"
              phx-click-away={JS.exec("data-cancel", to: "##{@id}")}
              class="shadow-bg-gray-900/10 ring-bg-gray-900/10 relative hidden rounded-2xl bg-white p-14 shadow-xl transition"
            >
              <div class="absolute top-6 right-5">
                <button
                  phx-click={JS.exec("data-cancel", to: "##{@id}")}
                  type="button"
                  class="-m-3 flex-none p-3 opacity-60 hover:opacity-40"
                  aria-label={gettext("close")}
                >
                  <.icon name="hero-x-mark-solid" class="h-5 w-5" />
                </button>
              </div>
              <div id={"#{@id}-content"}>
                <%= render_slot(@inner_block) %>
              </div>
            </.focus_wrap>
          </div>
        </div>
      </div>
    </div>
    """
  end

  @doc """
  Renders flash notices.

  ## Examples

      <.flash kind={:info} flash={@flash} />
      <.flash kind={:info} phx-mounted={show("#flash")}>Welcome Back!</.flash>
  """
  attr :id, :string, default: "flash", doc: "the optional id of flash container"
  attr :flash, :map, default: %{}, doc: "the map of flash messages to display"
  attr :title, :string, default: nil
  attr :kind, :atom, values: [:info, :error], doc: "used for styling and flash lookup"
  attr :rest, :global, doc: "the arbitrary HTML attributes to add to the flash container"
  attr :absolute, :boolean, default: false, doc: "position absolute or relative"

  slot :inner_block, doc: "the optional inner block that renders the flash message"

  def flash(assigns) do
    ~H"""
    <div class={@absolute && "absolute top-2 right-2 z-50"}>
      <div
        :if={msg = render_slot(@inner_block) || Phoenix.Flash.get(@flash, @kind)}
        id={@id}
        phx-click={JS.push("lv:clear-flash", value: %{key: @kind}) |> hide("##{@id}")}
        role="alert"
        data-disappear-after={(@kind == :info && 5000) || -1}
        class={[
          "w-full p-3 border-l-4 shadow-lg",
          @kind == :info && "bg-green-200 border-green-500 text-green-800 ring-red-500 fill-red-900",
          @kind == :error &&
            "bg-red-100 border-red-500 text-red-700 shadow-md shadow-red-200 ring-red-500 fill-red-900"
        ]}
        {@rest}
      >
        <div class="flex items-start gap-3">
          <div class="flex-grow ">
            <p :if={@title} class="flex items-center gap-1.5 text-sm font-semibold leading-6">
              <.icon :if={@kind == :info} name="hero-information-circle-mini" class="h-4 w-4" />
              <.icon :if={@kind == :error} name="hero-exclamation-circle-mini" class="h-4 w-4" />
              <%= @title %>
            </p>
            <p class="mt-2 text-sm leading-5"><%= msg %></p>
          </div>
          <button type="button" class="group" aria-label={gettext("close")}>
            <.icon name="hero-x-mark-solid" class="h-5 w-5 opacity-40 group-hover:opacity-70" />
          </button>
        </div>
      </div>
    </div>
    """
  end

  @doc """
  Shows the flash group with standard titles and content.

  ## Examples

      <.flash_group flash={@flash} />
  """
  attr :flash, :map, required: true, doc: "the map of flash messages"
  attr :absolute, :boolean, default: false, doc: "position absolute or relative"

  def flash_group(assigns) do
    ~H"""
    <.flash kind={:info} title="Success!" flash={@flash} absolute={@absolute} />
    <.flash kind={:error} title="Error!" flash={@flash} absolute={@absolute} />
    <.flash
      id="client-error"
      kind={:error}
      title="We can't find the internet"
      phx-disconnected={show(".phx-client-error #client-error")}
      phx-connected={hide("#client-error")}
      hidden
      absolute={@absolute}
    >
      Attempting to reconnect <.icon name="hero-arrow-path" class="ml-1 h-3 w-3 animate-spin" />
    </.flash>

    <.flash
      id="server-error"
      kind={:error}
      title="Something went wrong!"
      phx-disconnected={show(".phx-server-error #server-error")}
      phx-connected={hide("#server-error")}
      hidden
      absolute={@absolute}
    >
      Hang in there while we get back on track
      <.icon name="hero-arrow-path" class="ml-1 h-3 w-3 animate-spin" />
    </.flash>
    """
  end

  @doc """
  Renders a simple form.

  ## Examples

      <.simple_form for={@form} phx-change="validate" phx-submit="save">
        <.input field={@form[:email]} label="Email"/>
        <.input field={@form[:username]} label="Username" />
        <:actions>
          <.button>Save</.button>
        </:actions>
      </.simple_form>
  """
  attr :for, :any, required: true, doc: "the datastructure for the form"
  attr :as, :any, default: nil, doc: "the server side parameter to collect all input under"

  attr :rest, :global,
    include: ~w(autocomplete name rel action enctype method novalidate target multipart),
    doc: "the arbitrary HTML attributes to apply to the form tag"

  slot :inner_block, required: true
  slot :actions, doc: "the slot for form actions, such as a submit button"

  def simple_form(assigns) do
    ~H"""
    <.form :let={f} for={@for} as={@as} {@rest}>
      <div class="mt-10 space-y-4">
        <%= render_slot(@inner_block, f) %>
        <div :for={action <- @actions} class="mt-2 flex items-center justify-between gap-6">
          <%= render_slot(action, f) %>
        </div>
      </div>
    </.form>
    """
  end

  @doc """
  Renders a button.

  ## Examples

      <.button_primary>Send!</.button_primary>
      <.button_primary phx-click="go" class="ml-2">Send!</.button_primary>
  """
  attr :type, :string, default: nil
  attr :class, :string, default: nil
  attr :rest, :global, include: ~w(disabled form name value)

  slot :inner_block, required: true

  def button_primary(assigns) do
    ~H"""
    <button
      type={@type}
      class={[
        "phx-submit-loading:opacity-75 rounded-lg bg-primary-500 hover:bg-primary-600 py-2 px-3",
        "font-semibold leading-6 text-white hover:text-white active:text-white whitespace-nowrap",
        "disabled:bg-secondary-900 disabled:pointer-events-none",
        @class
      ]}
      {@rest}
    >
      <%= render_slot(@inner_block) %>
    </button>
    """
  end

  attr :type, :string, default: nil
  attr :class, :string, default: nil
  attr :rest, :global, include: ~w(disabled form name value)

  slot :inner_block, required: true

  def button_secondary(assigns) do
    ~H"""
    <button
      type={@type}
      class={[
        "phx-submit-loading:opacity-75 rounded-lg bg-gray-200 hover:bg-gray-300 py-2 px-3",
        "font-semibold leading-6 text-gray-900 active:text-white whitespace-nowrap",
        "disabled:bg-secondary-900 disabled:pointer-events-none",
        @class
      ]}
      {@rest}
    >
      <%= render_slot(@inner_block) %>
    </button>
    """
  end

  attr :type, :string, default: nil
  attr :class, :string, default: nil
  attr :rest, :global, include: ~w(disabled form name value)

  slot :inner_block, required: true

  def button_unobstrusive(assigns) do
    ~H"""
    <button
      type={@type}
      class={[
        "phx-submit-loading:opacity-75 rounded-lg bg-primary-100 shadow shadow-inner hover:bg-primary-500 py-2 px-3",
        "text-gray-900 text-sm font-semibold hover:text-white active:text-white",
        "disabled:bg-secondary-900 disabled:pointer-events-none",
        @class
      ]}
      {@rest}
    >
      <%= render_slot(@inner_block) %>
    </button>
    """
  end

  attr :type, :string, default: nil
  attr :class, :string, default: nil
  attr :rest, :global, include: ~w(disabled form name value)

  slot :inner_block, required: true

  def button_magic(assigns) do
    ~H"""
    <button
      type={@type}
      class={[
        "threatshield-gradient phx-submit-loading:opacity-75 rounded-lg bg-primary-600 hover:bg-primary-600 py-2 px-3",
        "font-semibold leading-6 text-white hover:text-white active:text-white whitespace-nowrap",
        "disabled:bg-secondary-900 disabled:pointer-events-none hover:shadow-lg",
        @class
      ]}
      {@rest}
    >
      <%= render_slot(@inner_block) %>
    </button>
    """
  end

  attr :type, :string, default: nil
  attr :class, :string, default: nil
  attr :rest, :global, include: ~w(disabled form name value)

  slot :inner_block, required: true

  def button_danger(assigns) do
    ~H"""
    <button
      type={@type}
      class={[
        "phx-submit-loading:opacity-75  bg-red-500 hover:bg-red-600 py-2 px-3 shadow rounded-lg shadow-inner",
        "text-white text-sm font-semibold",
        "disabled:bg-red-800 disabled:pointer-events-none",
        @class
      ]}
      {@rest}
    >
      <%= render_slot(@inner_block) %>
    </button>
    """
  end

  @doc """
  Renders an input with label and error messages.

  A `Phoenix.HTML.FormField` may be passed as argument,
  which is used to retrieve the input name, id, and values.
  Otherwise all attributes may be passed explicitly.

  ## Types

  This function accepts all HTML input types, considering that:

    * You may also set `type="select"` to render a `<select>` tag

    * `type="checkbox"` is used exclusively to render boolean values

    * For live file uploads, see `Phoenix.Component.live_file_input/1`

  See https://developer.mozilla.org/en-US/docs/Web/HTML/Element/input
  for more information.

  ## Examples

      <.input field={@form[:email]} type="email" />
      <.input name="my-input" errors={["oh no!"]} />
  """
  attr :id, :any, default: nil
  attr :name, :any
  attr :label, :string, default: nil
  attr :value, :any

  attr :type, :string,
    default: "text",
    values: ~w(checkbox color date datetime-local email file hidden month number password
               range radio search select tel text textarea time url week)

  attr :field, Phoenix.HTML.FormField,
    doc: "a form field struct retrieved from the form, for example: @form[:email]"

  attr :errors, :list, default: []
  attr :checked, :boolean, doc: "the checked flag for checkbox inputs"
  attr :prompt, :string, default: nil, doc: "the prompt for select inputs"
  attr :options, :list, doc: "the options to pass to Phoenix.HTML.Form.options_for_select/2"
  attr :multiple, :boolean, default: false, doc: "the multiple flag for select inputs"

  attr :rest, :global,
    include: ~w(accept autocomplete capture cols disabled form list max maxlength min minlength
                multiple pattern placeholder readonly required rows size step)

  slot :inner_block

  def input(%{field: %Phoenix.HTML.FormField{} = field} = assigns) do
    assigns
    |> assign(field: nil, id: assigns.id || field.id)
    |> assign(:errors, Enum.map(field.errors, &translate_error(&1)))
    |> assign_new(:name, fn -> if assigns.multiple, do: field.name <> "[]", else: field.name end)
    |> assign_new(:value, fn -> field.value end)
    |> input()
  end

  def input(%{type: "checkbox", value: value} = assigns) do
    assigns =
      assign_new(assigns, :checked, fn -> Phoenix.HTML.Form.normalize_value("checkbox", value) end)

    ~H"""
    <div phx-feedback-for={@name}>
      <label class="flex items-center gap-4 text-sm leading-6 text-zinc-600">
        <input type="hidden" name={@name} value="false" />
        <input
          type="checkbox"
          id={@id}
          name={@name}
          value="true"
          checked={@checked}
          class="rounded border-zinc-300 text-gray-900 focus:ring-0"
          {@rest}
        />
        <%= @label %>
      </label>
      <.error :for={msg <- @errors}><%= msg %></.error>
    </div>
    """
  end

  def input(%{type: "select"} = assigns) do
    ~H"""
    <div phx-feedback-for={@name}>
      <.label for={@id}><%= @label %></.label>
      <select
        id={@id}
        name={@name}
        class="mt-2 block w-full rounded-sm border border-gray-300 bg-white shadow-sm focus:border-zinc-400 focus:ring-0 sm:text-sm"
        multiple={@multiple}
        {@rest}
      >
        <option :if={@prompt} value=""><%= @prompt %></option>
        <%= Phoenix.HTML.Form.options_for_select(@options, @value) %>
      </select>
      <.error :for={msg <- @errors}><%= msg %></.error>
    </div>
    """
  end

  def input(%{type: "textarea"} = assigns) do
    ~H"""
    <div phx-feedback-for={@name}>
      <.label for={@id}><%= @label %></.label>
      <textarea
        id={@id}
        name={@name}
        class={[
          "mt-2 block w-full rounded-lg text-gray-900 focus:ring-0 sm:text-sm sm:leading-6",
          "min-h-[6rem] phx-no-feedback:border-zinc-300 phx-no-feedback:focus:border-zinc-400",
          @errors == [] && "border-zinc-300 focus:border-zinc-400",
          @errors != [] && "border-rose-400 focus:border-rose-400"
        ]}
        {@rest}
      ><%= Phoenix.HTML.Form.normalize_value("textarea", @value) %></textarea>
      <.error :for={msg <- @errors}><%= msg %></.error>
    </div>
    """
  end

  # All other inputs text, datetime-local, url, password, etc. are handled here...
  def input(assigns) do
    ~H"""
    <div phx-feedback-for={@name}>
      <.label for={@id} mandatory={not is_nil(assigns[:required])}><%= @label %></.label>
      <input
        type={@type}
        name={@name}
        id={@id}
        value={Phoenix.HTML.Form.normalize_value(@type, @value)}
        class={[
          "mt-2 block w-full rounded-lg text-gray-900 focus:ring-0 sm:text-sm sm:leading-6",
          "phx-no-feedback:border-zinc-300 phx-no-feedback:focus:border-zinc-400",
          @errors == [] && "border-zinc-300 focus:border-zinc-400",
          @errors != [] && "border-rose-400 focus:border-rose-400"
        ]}
        {@rest}
      />
      <.error :for={msg <- @errors}><%= msg %></.error>
    </div>
    """
  end

  @doc """
  Renders a label.
  """
  attr :for, :string, default: nil
  attr :mandatory, :boolean, default: false
  slot :inner_block, required: true

  def label(assigns) do
    ~H"""
    <label
      for={@for}
      class={["block text-sm font-semibold leading-6 text-gray-500", @mandatory && "mandatory"]}
    >
      <%= render_slot(@inner_block) %>
    </label>
    """
  end

  @doc """
  Generates a generic error message.
  """
  slot :inner_block, required: true

  def error(assigns) do
    ~H"""
    <p class="mt-3 flex gap-3 text-sm leading-6 text-rose-600 phx-no-feedback:hidden">
      <.icon name="hero-exclamation-circle-mini" class="mt-0.5 h-5 w-5 flex-none" />
      <%= render_slot(@inner_block) %>
    </p>
    """
  end

  @doc """
  Renders a header with title.
  """
  attr :class, :string, default: nil

  slot :inner_block, required: true
  slot :subtitle
  slot :actions

  def header(assigns) do
    ~H"""
    <header class={[@actions != [] && "flex items-center justify-between gap-6", @class]}>
      <div>
        <h1 class="text-lg font-semibold leading-8 text-gray-900">
          <%= render_slot(@inner_block) %>
        </h1>
        <p :if={@subtitle != []} class="mt-2 help-text">
          <%= render_slot(@subtitle) %>
        </p>
      </div>
      <div class="flex-none"><%= render_slot(@actions) %></div>
    </header>
    """
  end

  @doc ~S"""
  Renders a table with generic styling.

  ## Examples

      <.table id="users" rows={@users}>
        <:col :let={user} label="id"><%= user.id %></:col>
        <:col :let={user} label="username"><%= user.username %></:col>
      </.table>
  """
  attr :id, :string, required: true
  attr :rows, :list, required: true
  attr :row_id, :any, default: nil, doc: "the function for generating the row id"
  attr :row_click, :any, default: nil, doc: "the function for handling phx-click on each row"

  attr :row_item, :any,
    default: &Function.identity/1,
    doc: "the function for mapping each row before calling the :col and :action slots"

  slot :col, required: true do
    attr :label, :string
  end

  slot :action, doc: "the slot for showing user actions in the last table column"

  def table(assigns) do
    assigns =
      with %{rows: %Phoenix.LiveView.LiveStream{}} <- assigns do
        assign(assigns, row_id: assigns.row_id || fn {id, _item} -> id end)
      end

    ~H"""
    <table class="w-full mx-4 mt-10 mx-auto justify-self-center">
      <thead class="text-sm text-left leading-6 text-primary-900">
        <tr class="">
          <th :for={col <- @col} class="px-2 pb-4 font-normal"><%= col[:label] %></th>
          <th :if={@action != []} class="relative px-2 pb-4">
            <span class="sr-only"><%= gettext("Actions") %></span>
          </th>
        </tr>
      </thead>
      <tbody
        id={@id}
        phx-update={match?(%Phoenix.LiveView.LiveStream{}, @rows) && "stream"}
        class="relative divide-y-2 divide-zinc-100 border-t border-zinc-200 text-sm leading-6 text-zinc-700"
      >
        <tr :for={row <- @rows} id={@row_id && @row_id.(row)} class="group hover:bg-zinc-50">
          <td
            :for={{col, i} <- Enum.with_index(@col)}
            phx-click={@row_click && @row_click.(row)}
            class={["relative px-2 py-0", @row_click && "hover:cursor-pointer"]}
          >
            <div class="block py-4 pr-0">
              <span class="absolute -inset-y-px -right-0 -left-4 group-hover:bg-zinc-50 sm:rounded-l-xl" />
              <span class={["relative", i == 0 && "font-semibold text-gray-900"]}>
                <%= render_slot(col, @row_item.(row)) %>
              </span>
            </div>
          </td>
          <td :if={@action != []} class="relative w-14 px-0">
            <div class="relative whitespace-nowrap py-4 text-right text-sm font-medium">
              <span class="absolute -inset-y-px -right-4 left-0 group-hover:bg-zinc-50 sm:rounded-r-xl" />
              <span
                :for={action <- @action}
                class="relative ml-4 font-semibold leading-6 text-gray-900 hover:text-bg-gray-900"
              >
                <%= render_slot(action, @row_item.(row)) %>
              </span>
            </div>
          </td>
        </tr>
      </tbody>
    </table>
    """
  end

  attr :label, :string, required: true
  attr :name, :atom, required: true
  attr :active, :boolean, default: false

  def tab_button(assigns) do
    ~H"""
    <button
      phx-click="switch_tab"
      phx-value-tab={@name}
      class={[
        "text-center py-2 bg-white cursor-pointer px-4 hover:bg-primary-100",
        @active && "border-b-2 border-primary-300"
      ]}
    >
      <%= @label %>
    </button>
    """
  end

  attr :organisation, :any, required: false
  attr :current_user, :any, required: false
  attr :background, :string, default: "bg-primary-900"

  def navbar(assigns) do
    ~H"""
    <div class={["flex justify-between h-16", @background]}>
      <div class="justify-start flex items-center gap-9 px-10">
        <a href="/" class="">
          <ThreatShieldWeb.Icons.app_icon class="h-8 w-8 text-primary-100" />
        </a>
        <%= if assigns[:organisation] do %>
          <.link
            href={~p"/organisations/#{@organisation.id}"}
            class="leading-6 text-white hover:underline"
          >
            <%= dgettext("common", "Threat model") %>
          </.link>
          <.link
            href={~p"/organisations/#{@organisation.id}/risk-board"}
            class="leading-6 text-white hover:underline"
          >
            <%= dgettext("common", "Risk board") %>
          </.link>
        <% end %>
        <%= if ThreatShield.Accounts.RBAC.has_permission(assigns[:current_user], :administer_platform) do %>
          <.link
            href={~p"/platform-administration/organisations"}
            class="leading-6 text-white hover:underline"
          >
            <%= dgettext("admin", "Admin") %>
          </.link>
        <% end %>
      </div>
      <nav class="text-white flex items-center px-10">
        <ul class="relative z-10 flex gap-4 justify-end">
          <%= if assigns[:organisation] do %>
            <li
              id="org-dropdown"
              class="relative nav-dropdown text-[0.8125rem] leading-loose font-semibold hover:cursor-pointer border border-2 rounded-md h-9 px-4 py-1"
              onclick="toggleDropdown(id)"
            >
              <%= @organisation.name %>
              <.icon name="hero-chevron-down" class="h-5 w-5" />

              <ul class="absolute org-dropdown-menu hidden right-2 mt-4 w-48 bg-white text-primary-500 rounded-lg shadow-xl">
                <li class="px-4 py-2 text-gray-900 text-sm font-medium flex justify-between">
                  <%= @organisation.name %><.icon name="hero-check" class="h-5 w-5 text-primary-600" />
                </li>
                <%= for org <- @current_user.organisations do %>
                  <%= if org.id != @organisation.id do %>
                    <li class="px-4 py-2 text-gray-900 text-sm font-normal">
                      <.link
                        href={~p"/organisations/#{org.id}"}
                        class="text-[0.8125rem] leading-6 text-primary-500 hover:underline"
                      >
                        <%= org.name %>
                      </.link>
                    </li>
                  <% end %>
                <% end %>
                <li class="px-4 py-2 flex justify-between border-t-2 items-center">
                  <.link
                    href={~p"/organisations/new"}
                    class="text-[0.8125rem] leading-6 text-primary-500 hover:underline text-primary-600"
                  >
                    <%= dgettext("organisations", "Create organisation") %>
                  </.link>
                  <.icon name="hero-plus" class="h-5 w-5 text-gray-400" />
                </li>
              </ul>
            </li>
          <% end %>
          <%= if assigns[:current_user] do %>
            <li
              id="user-dropdown"
              class="relative nav-dropdown text-white font-semibold hover:cursor-pointer border border-2 rounded-3xl px-1.5 py-1"
              onclick="toggleDropdown(id)"
            >
              <.icon name="hero-user" class="h-5 w-5" />
              <ul class="absolute hidden right-2 mt-4 py-1 bg-white rounded-lg shadow-xl text-gray-900 text-sm font-normal">
                <li class="px-4 py-2 border-b border-gray-300">
                  <p>
                    <%= dgettext("users", "Signed in as") %>
                  </p>
                  <p class="text-gray-900 text-sm font-medium">
                    <%= @current_user.email %>
                  </p>
                </li>
                <li class="context-menu-item">
                  <.link
                    href={~p"/users/settings"}
                    class="text-[0.8125rem] leading-6 text-primary-500 hover:underline"
                  >
                    <%= dgettext("users", "Account settings") %>
                  </.link>
                </li>
                <li class="context-menu-item">
                  <.link class="text-[0.8125rem] leading-6 text-primary-500 hover:underline text-gray-200">
                    <%= dgettext("users", "Support") %>
                  </.link>
                </li>
                <li class="context-menu-item border-t border-gray-300">
                  <.link
                    href={~p"/users/log_out"}
                    method="delete"
                    class="text-[0.8125rem] leading-6 text-primary-500 hover:underline"
                  >
                    <%= dgettext("users", "Log out") %>
                  </.link>
                </li>
              </ul>
            </li>
          <% else %>
            <li class="text-white">
              <.link
                href={~p"/users/register"}
                class="text-[0.8125rem] leading-6 font-semibold hover:underline"
              >
                <%= dgettext("accounts", "Sign up") %>
              </.link>
            </li>
            <li class="text-white">
              <.link
                href={~p"/users/log_in"}
                class="text-[0.8125rem] leading-6 font-semibold hover:underline"
              >
                <%= dgettext("accounts", "Sign in") %>
              </.link>
            </li>
          <% end %>
        </ul>
      </nav>
    </div>
    """
  end

  @doc """
  Renders a data list.

  ## Examples

      <.list>
        <:item title="Title"><%= @post.title %></:item>
        <:item title="Views"><%= @post.views %></:item>
      </.list>
  """
  slot :item, required: true do
    attr :title, :string, required: true
  end

  def list(assigns) do
    ~H"""
    <div class="mt-14">
      <dl class="-my-4 divide-y divide-zinc-100">
        <div :for={item <- @item} class="flex gap-4 py-4 text-sm leading-6 sm:gap-8">
          <dt class="w-1/4 flex-none text-zinc-500"><%= item.title %></dt>
          <dd class="text-bg-gray-900"><%= render_slot(item) %></dd>
        </div>
      </dl>
    </div>
    """
  end

  attr :id, :string, required: true
  attr :rows, :list, required: true
  attr :row_id, :any, default: nil, doc: "the function for generating the row id"
  attr :row_click, :any, default: nil, doc: "the function for handling phx-click on each row"

  attr :row_item, :any,
    default: &Function.identity/1,
    doc: "the function for mapping each row before calling the :col and :action slots"

  slot :col, required: true do
    attr :label, :string
  end

  slot :action, doc: "the slot for showing user actions in the last table column"
  slot :name, required: false

  def stacked_list(assigns) do
    assigns =
      with %{rows: %Phoenix.LiveView.LiveStream{}} <- assigns do
        assign(assigns, row_id: assigns.row_id || fn {id, _item} -> id end)
      end

    ~H"""
    <table class="w-full justify-self-center">
      <tbody
        id={@id}
        phx-update={match?(%Phoenix.LiveView.LiveStream{}, @rows) && "stream"}
        class="relative divide-y-2 divide-zinc-100 text-sm leading-6 text-gray-900"
      >
        <tr :for={row <- @rows} id={@row_id && @row_id.(row)} class="group hover:bg-zinc-50">
          <td
            :for={{col, i} <- Enum.with_index(@col)}
            phx-click={@row_click && @row_click.(row)}
            class={["relative p-0", @row_click && "hover:cursor-pointer"]}
          >
            <div class="block py-4 pr-4">
              <span class="absolute -inset-y-px -right-0 -left-4 group-hover:bg-zinc-50 sm:rounded-l-xl" />
              <span class={["relative", i == 0 && "font-semibold"]}>
                <%= render_slot(col, @row_item.(row)) %>
              </span>
            </div>
          </td>
          <td :if={@action != []} class="relative w-14 p-0">
            <div class="relative whitespace-nowrap py-4 text-right text-sm font-medium">
              <span class="absolute -inset-y-px -right-4 left-0 group-hover:bg-zinc-50 sm:rounded-r-xl" />
              <span
                :for={action <- @action}
                class="relative ml-4 font-semibold leading-6 text-gray-900 hover:text-bg-gray-900"
              >
                <%= render_slot(action, @row_item.(row)) %>
              </span>
            </div>
          </td>

          <td class="grid justify-items-end mt-3">
            <.link
              phx-click={@row_click && @row_click.(row)}
              class={["relative p-0", @row_click && "hover:cursor-pointer"]}
            >
              <.button_unobstrusive><%= dgettext("common", "View") %></.button_unobstrusive>
            </.link>
          </td>
        </tr>
      </tbody>
    </table>
    """
  end

  slot :name, required: false
  slot :buttons, required: false
  slot :subtitle, required: false

  def stacked_list_header(assigns) do
    ~H"""
    <section class="flex justify-between">
      <div class="w-[70%]">
        <.h2>
          <%= render_slot(@name) %>
        </.h2>
        <p :if={@subtitle != []} class="mt-2 text-gray-500 text-sm font-normal">
          <%= render_slot(@subtitle) %>
        </p>
      </div>
      <div class="flex flex-row flex-1 gap-2 justify-end">
        <%= render_slot(@buttons) %>
      </div>
    </section>
    """
  end

  slot :links, required: true

  def dropdown(assigns) do
    ~H"""
    <div
      id="link-dropdown"
      class="relative nav-dropdown text-[0.8125rem] font-semibold px-2 py-2 border border-gray-400 rounded-md h-10 hover:cursor-pointer hover:bg-primary-100 hover:border-gray-800"
      onclick="toggleDropdown(id)"
    >
      <.icon name="hero-ellipsis-vertical" class="h-5 w-5" />

      <ul class="absolute link-dropdown-menu hidden right-0 mt-4 bg-white text-primary-500 rounded-sm shadow-xl">
        <%= render_slot(@links) %>
      </ul>
    </div>
    """
  end

  def input_attribute(assigns) do
    ~H"""
    <%= for {key, value} <- @attributes do %>
      <div class="grid gap-2 px-6 py-2 w-72">
        <div class="text-gray-500 text-xs font-medium"><%= key %></div>
        <div class="text-gray-900 text-sm font-normal"><%= value %></div>
      </div>
    <% end %>
    """
  end

  @doc """
  Renders a back navigation link.

  ## Examples

      <.back navigate={~p"/posts"}>Back to posts</.back>
  """
  attr :navigate, :any, required: true
  slot :inner_block, required: true

  def back(assigns) do
    ~H"""
    <div class="mt-16">
      <.link
        navigate={@navigate}
        class="text-sm font-semibold leading-6 text-gray-900 hover:text-secondary-600"
      >
        <.icon name="hero-arrow-left-solid" class="h-3 w-3" />
        <%= render_slot(@inner_block) %>
      </.link>
    </div>
    """
  end

  @doc """
  Renders a link.
  """
  attr :name, :string, required: true
  attr :class, :string, default: nil

  def icon(%{name: "hero-" <> _} = assigns) do
    ThreatShieldWeb.Icons.heroicon(assigns)
  end

  ## JS Commands

  def show(js \\ %JS{}, selector) do
    JS.show(js,
      to: selector,
      transition:
        {"transition-all transform ease-out duration-300",
         "opacity-0 translate-y-4 sm:translate-y-0 sm:scale-95",
         "opacity-100 translate-y-0 sm:scale-100"}
    )
  end

  def hide(js \\ %JS{}, selector) do
    JS.hide(js,
      to: selector,
      time: 200,
      transition:
        {"transition-all transform ease-in duration-200",
         "opacity-100 translate-y-0 sm:scale-100",
         "opacity-0 translate-y-4 sm:translate-y-0 sm:scale-95"}
    )
  end

  def show_modal(js \\ %JS{}, id) when is_binary(id) do
    js
    |> JS.show(to: "##{id}")
    |> JS.show(
      to: "##{id}-bg",
      transition: {"transition-all transform ease-out duration-300", "opacity-0", "opacity-100"}
    )
    |> show("##{id}-container")
    |> JS.add_class("overflow-hidden", to: "body")
    |> JS.focus_first(to: "##{id}-content")
  end

  def hide_modal(js \\ %JS{}, id) do
    js
    |> JS.hide(
      to: "##{id}-bg",
      transition: {"transition-all transform ease-in duration-200", "opacity-100", "opacity-0"}
    )
    |> hide("##{id}-container")
    |> JS.hide(to: "##{id}", transition: {"block", "block", "hidden"})
    |> JS.remove_class("overflow-hidden", to: "body")
    |> JS.pop_focus()
  end

  @doc """
  Translates an error message using gettext.
  """
  def translate_error({msg, opts}) do
    # When using gettext, we typically pass the strings we want
    # to translate as a static argument:
    #
    #     # Translate the number of files with plural rules
    #     dngettext("errors", "1 file", "%{count} files", count)
    #
    # However the error messages in our forms and APIs are generated
    # dynamically, so we need to translate them by calling Gettext
    # with our gettext backend as first argument. Translations are
    # available in the errors.po file (as we use the "errors" domain).
    if count = opts[:count] do
      Gettext.dngettext(ThreatShieldWeb.Gettext, "errors", msg, msg, count, opts)
    else
      Gettext.dgettext(ThreatShieldWeb.Gettext, "errors", msg, opts)
    end
  end

  @doc """
  Translates the errors for a field from a keyword list of errors.
  """
  def translate_errors(errors, field) when is_list(errors) do
    for {^field, {msg, opts}} <- errors, do: translate_error({msg, opts})
  end
end
