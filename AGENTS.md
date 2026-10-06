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
  `choices.js`, `@popperjs/core`) come from `assets/package.json` and need `npm install`
  in `assets/` (Node.js 20, see `.tool-versions`).
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
  (`:owner` / `:editor` / `:viewer`; a viewer has no action rights).
  `Rights.may(:create_threat, membership)`. The right→role map is the single source of
  truth in `rights.ex`.
- **`ThreatShield.Accounts.RBAC`** — global/platform permissions (e.g.
  `:administer_platform` for platform admins).

Most queries also enforce ownership at the DB level via `for_user/2` joins on the
schema — security is in the query, not just the UI.

### Web layer

- `lib/threat_shield_web/live/<entity>_live/` — LiveViews, one folder per entity
  (`threat_live`, `risk_live`, `asset_live`, `system_live`, `organisation_live`,
  `members_live`, `mitigation_live`, `admin_live`). `*_details.ex` modules are the main
  show/edit screens. `risk_live/risk_board.ex` is the risk board;
  `threat_live/threat_suggestions.ex` shows AI threat suggestions.
- `lib/threat_shield_web/components/` — shared function components: `core_components.ex`,
  `ts_components.ex`, `breadcrumbs.ex`, `labels.ex`, `suggestions.ex` (AI suggestion UI),
  `icons.ex`, `info_vis.ex`, `spinner.ex`.
- `lib/threat_shield_web/router.ex` — routes are deeply nested by the domain hierarchy
  (`/organisations/:org_id/systems/:sys_id/threats/:threat_id/risks/:risk_id/...`).
  Auth via `live_session` blocks: `redirect_if_user_is_authenticated`,
  `require_authenticated_user`, `platform_admin`, `current_user`.
- `lib/threat_shield_web/user_auth.ex` — session auth + LiveView `on_mount` hooks.

### AI integration

`ThreatShield.AI` builds prompts from the domain objects (organisation/system/asset
descriptions) and asks OpenAI for JSON suggestions. Every AI call goes through
`AI.run_task/2`, which checks the organisation's **quota** (`Quotas.QuotaManager`,
`ai_requests_per_month`) before running the task async under `ThreatShield.TaskSupervisor`
and logging usage. When adding AI features, route through `run_task/2` so quotas are
respected.

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

## Documentation

Plans, specs, and architecture decision records live in `docs/`. The folder structure and
the rules are defined in `docs/README.md` — read it before adding or changing a document.

- **Plan to spec:** when a step of a plan is built, remove it from the plan and describe
  the result in the spec.
- **Decisions:** a decision with a serious rejected alternative gets an ADR in `docs/adr/`.
- Working rules stay in this file; specs do not repeat them.

## Testing

- `mix test` auto-creates and migrates the test DB.
- Tests live under `test/threat_shield/` (contexts) and `test/threat_shield_web/`
  (LiveViews/controllers). Support in `test/support/` — `ConnCase`, `DataCase`, and
  fixtures under `test/support/fixtures/`. The SQL sandbox rolls back DB changes per test.

## CI/CD

- `.github/workflows/test.yml` — runs `mix test` against a Postgres 18 service on every push.
- `.github/workflows/build.yml`, `deploy_gcp.yml` — build and deploy to GCP. Deployment
  manifests are in `deployment/` and `rel/`.
