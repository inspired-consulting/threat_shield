# AGENTS.md

Guidance for working in this repository.

## What this is

ThreatShield is an **AI-powered threat-analysis and threat-modeling web app**, built with
**Elixir / Phoenix (LiveView)** and **PostgreSQL**. Users organize security work under an
**organisation**, then describe their **systems** and **assets**, identify **threats**,
assess **risks**, and plan **mitigations**. An OpenAI-backed assistant suggests entities
(threats, assets, risks, etc.) at each step.

## Tech stack

- **Elixir** 1.20.4 / **OTP** 29.1.1 (see `.tool-versions`; CI and the `Dockerfile` pin the
  same versions). `mix.exs` requires Elixir `~> 1.20`.
- **Phoenix** `~> 1.7` with **LiveView** `~> 0.20` — the UI is almost entirely LiveView.
- **Ecto** + **Postgrex** over **PostgreSQL**.
- **OpenAI** via the `openai` hex package (`gpt-3.5-turbo`, see `lib/threat_shield/ai.ex`).
- Assets: **esbuild** + **tailwind**, run through Mix. JS dependencies (`chart.js`,
  `@popperjs/core`) come from `assets/package.json` and need `npm install` in `assets/`
  (Node.js 20, see `.tool-versions`). `choices.js` is listed there but not used.
- Other: `bcrypt_elixir` (auth), `ex_rated` (rate limiting), `gettext` (i18n),
  `elixlsx` (Excel export), `swoosh`/`finch` (mail), `timex`, `logger_json`.

## Common commands

```bash
npm install --prefix assets   # JS dependencies (not part of mix setup)
mix setup                # deps.get + ecto.setup + assets.setup + assets.build
mix phx.server           # run the app at http://localhost:4000
iex -S mix phx.server    # run with an interactive shell

mix test                 # creates+migrates the test DB, then runs tests
mix test path/to/test.exs:NN   # single test

mix ecto.setup           # ecto.create + ecto.migrate + seeds
mix ecto.reset           # ecto.drop + ecto.setup
mix format               # format (see .formatter.exs)
```

Docker Compose is also supported (`docker compose up --build`); see `README.md`.
The app reads config from a `.env` file at the project root (DB creds, OpenAI key, etc.).
DB defaults: user/db `threat_shield`, password `secret`, host `localhost`.

`mix` only starts when exactly the Elixir and Erlang versions of `.tool-versions` are
installed (`asdf install`). Run `mix deps.get` when `mix.lock` has changed.

## Architecture

### Domain model (the core hierarchy)

```
Organisation ──< System ──< Asset
      │            │           │
      └──< Threat <┘<──────────┘     (a Threat may belong to a System and/or an Asset)
              └──< Risk ──< Mitigation
```

- **Contexts** live at `lib/threat_shield/<context>.ex` (e.g. `threats.ex`, `assets.ex`,
  `risks.ex`, `mitigations.ex`, `systems.ex`, `organisations.ex`, `members.ex`,
  `accounts.ex`). These are the public API for business logic.
- **Schemas** live under `lib/threat_shield/<context>/<entity>.ex`
  (e.g. `threats/threat.ex`). Schemas also host **composable Ecto query helpers**
  (`from/0`, `for_user/2`, `with_system/1`, `where_organisation/2`, …) which contexts
  pipe together. Follow this pattern when adding queries — put the query builders on the
  schema module, compose them in the context.

### Scope — the central access-control value

`ThreatShield.Scope` (`lib/threat_shield/scope.ex`) is a struct carrying the current
`user`, `organisation`, `membership`, and the relevant `system` / `asset` / `threat`.
It is built per-request (`Scope.for/2`, `Scope.for_system/3`, `Scope.for_asset/3`, …),
threaded through LiveViews and contexts, and is how the app scopes data and permissions to
the acting user. Prefer passing a `Scope` rather than loose ids.

### Authorization

Two layers, don't confuse them:

- **`ThreatShield.Members.Rights`** — per-organisation, role-based action rights
  (`:owner` / `:editor` / `:viewer`; a viewer has no action rights). The right→role map
  is the single source of truth in `rights.ex`. In templates and LiveViews use
  `may?(@scope, :create_threat)`; `may?/2` is imported everywhere and takes a scope or a
  membership.
- **`ThreatShield.Accounts.RBAC`** — global/platform permissions (e.g.
  `:administer_platform` for platform admins).

Most queries also enforce ownership at the DB level via `for_user/2` joins on the
schema — security is in the query, not just the UI.

### Access rules (apply to every change)

- **Every context function takes the acting user** (or a `Scope`). It loads through
  `for_user/2` to read, and through `for_user/3` with a right to change something. A
  function without an actor is not allowed, also not for "internal" use.
- **Hidden buttons are not protection.** A client can send any LiveView event with any
  id. Each `handle_event` must end in a context function that checks the right.
- **Do not cast foreign keys from parameters** (`organisation_id`, `risk_id`, …). Load the
  parent with `for_user/3` and set it with `put_assoc`.
- **Check references against the organisation.** When an entity points to another one
  (a threat to a system or an asset), verify that both belong to the same organisation;
  see `Threats.create_threat/3`.
- **Organisation rights go through `Rights`, never through `RBAC`.** `RBAC` returns false
  for every organisation right.
- **Invites are matched by email address.** They are listed and accepted only for users
  with a confirmed address.

### Web layer

- `lib/threat_shield_web/live/<entity>_live/` — LiveViews, one folder per entity
  (`threat_live`, `risk_live`, `asset_live`, `system_live`, `organisation_live`,
  `members_live`, `mitigation_live`, `admin_live`). `*_details.ex` modules are the main
  show/edit screens, `*_list.ex` and `*_form.ex` are LiveComponents used by them.
  `risk_live/risk_board.ex` is the risk board.
- `lib/threat_shield_web/components/` — shared function components: `core_components.ex`,
  `ts_components.ex`, `breadcrumbs.ex`, `labels.ex`, `icons.ex`, `info_vis.ex`,
  `spinner.ex`.
- Shared building blocks — use them, do not copy the pattern again:
  - `ThreatShieldWeb.FormHelpers` — `assign_form/2` and `handle_save_result/4` for form
    components. A form gets its return path in the assign `:patch`.
  - `ThreatShieldWeb.AiSuggestions` — the AI suggestion flow of the list components
    (`request/3`, `handle_result/2`, `selected/2`).
  - `delete_menu_item/1` and `edit_menu_item/1` in `ts_components.ex` — the entries of the
    context menu on detail pages.
- `lib/threat_shield_web/router.ex` — routes are deeply nested by the domain hierarchy
  (`/organisations/:org_id/systems/:sys_id/threats/:threat_id/risks/:risk_id/...`).
  Auth via `live_session` blocks: `redirect_if_user_is_authenticated`,
  `require_authenticated_user`, `platform_admin`, `current_user`.
- `lib/threat_shield_web/user_auth.ex` — session auth + LiveView `on_mount` hooks.

### AI integration

`ThreatShield.AI` builds prompts from the domain objects (organisation/system/asset
descriptions) and asks OpenAI for JSON suggestions. Every AI call goes through
`AI.run_task/2`, which checks the organisation's **quota** (`Quotas.QuotaManager`,
`ai_requests_per_month`), logs the usage, and then runs the task. The call blocks, so run
it in a separate process: the list components use `ThreatShieldWeb.AiSuggestions`, which
starts it with `start_async` under `ThreatShield.TaskSupervisor`. When adding AI features,
route through `run_task/2` so quotas are respected.

The OpenAI client module is read from the configuration (`:open_ai_client`). Call OpenAI
only through `ThreatShield.AI`, so that tests can replace the client.

### Other notable modules

- `lib/threat_shield/dynamic_attribute.ex` — organisations/systems carry flexible,
  AI-suggestable attributes stored as a JSON `:map` field.
- `lib/threat_shield/exporters/excel_exporter.ex` — Excel export (`/exports/excel`).
- `lib/threat_shield/analytics/risk_analytics.ex` — risk analytics for the risk board.
- `lib/threat_shield/quotas/` — quota tracking and enforcement.
- `lib/threat_shield/const/` — static reference data (locations, retention times).

## Conventions

- Module namespaces: `ThreatShield.*` for domain, `ThreatShieldWeb.*` for web.
- Keep business logic in contexts; keep LiveViews thin (mount → load via context →
  assign → render). See `live/threat_live/threat_details.ex` as the reference pattern.
- Build queries from schema-module query helpers; always scope by user/organisation.
- User-facing strings go through `gettext`.
- Run `mix format` before committing; `.formatter.exs` governs style.
- Compile after each change and add no new compiler warnings. Elixir 1.20 infers types
  and reports contradictions as warnings, for example a clause that never matches or a
  comparison that is always false. Treat a new warning as a defect in the change.

## Documentation

Plans, specs, and architecture decision records live in `docs/`. The folder structure and
the rules are defined in `docs/README.md` — read it before adding or changing a document.

- **Plan to spec:** when a step of a plan is built, remove it from the plan and describe
  the result in the spec.
- **Decisions:** a decision with a serious rejected alternative gets an ADR in `docs/adr/`.
- Working rules stay in this file; specs do not repeat them.
- `docs/audit/` is local only and ignored by git. Never commit audit reports; the
  repository is public.

## Testing

- `mix test` auto-creates and migrates the test DB.
- Tests live under `test/threat_shield/` (contexts) and `test/threat_shield_web/`
  (LiveViews/controllers). Support in `test/support/` — `ConnCase`, `DataCase`, and
  fixtures under `test/support/fixtures/`. The SQL sandbox rolls back DB changes per test.
- Add a regression test with every fix. For a new read or write path, add a test with a
  second organisation and with a `:viewer` (`MembersFixtures.membership_fixture/3`,
  `AccountsFixtures.confirmed_user_fixture/1`).
- Tests never call OpenAI: `config/test.exs` sets `ThreatShield.OpenAIStub` as the client.
- Examples to copy from: `test/threat_shield/members_test.exs` (access rules in a
  context), and in `test/threat_shield_web/live/`: `entity_form_live_test.exs` (forms),
  `entity_menu_live_test.exs` (rights in the UI), `ai_suggestions_live_test.exs` (async
  flow with `render_async`).
- The test output shows `Ecto.ConstraintError` lines from a background task. They come
  from a known defect (`quota_usages.user_id` references the wrong table) and are not
  caused by your change.

## CI/CD

- `.github/workflows/test.yml` — runs `mix test` against a Postgres 18 service on every push.
- `.github/workflows/build.yml`, `deploy_gcp.yml` — build and deploy to GCP. Deployment
  manifests are in `deployment/` and `rel/`.
- **Do not use `/` in branch names.** `test.yml` triggers on `branches: "*"`, which does
  not match such names, so no tests run for them (see `docs/plans/backlog.md`).
- **A push to `main` deploys to production** (Cloud Run) when the tests pass.
- CI runs only the tests. Format and compiler warnings are not checked there; check them
  locally.
