# Backlog

**Status:** open list. Last updated 2026-10-07.

Short entries for open work without a plan of its own. When work on an entry starts and
needs steps, it gets its own file in this folder and is removed from here.

## Upgrade Phoenix LiveView to 1.0

The app runs on LiveView 0.20 (`mix.exs`: `~> 0.20.12`). The upgrade to 1.0 changes
`mix.exs`, `mix.lock`, `assets/package.json`, and parts of
`lib/threat_shield_web/components/core_components.ex`.

## Run tests on all branches

`.github/workflows/test.yml` triggers on `branches: "*"`. This pattern does not match
branch names that contain a `/`, such as `chore/upgrade-elixir-postgres`. Pushes to these
branches start no test run. Use `"**"` or remove the branch filter.

## Build only after the tests

`.github/workflows/build.yml` starts on a push to `main`, on a pull request, and after the
"Run Tests" workflow. Only the last trigger checks the test result.

- A push to `main` builds the image twice: once directly, once after the tests.
- The direct build and the pull-request build do not wait for the tests.
- Every build pushes the `latest` image tag, including builds of pull requests that are
  not merged.

## Login with OpenID Connect (Microsoft 365 / Entra ID)

Users log in with email and password only (`bcrypt_elixir`, `ThreatShieldWeb.UserAuth`).
Add login through an OpenID Connect provider. The first provider to support is
Microsoft Entra ID, so that users can log in with their Microsoft 365 account.

Open points: how an external identity maps to an existing user and to an organisation
membership, and whether an organisation can require this login for its members.

## REST API

The app has no API. The router defines an `:api` pipeline, but no route uses it. Add a
REST API for the domain objects (organisations, systems, assets, threats, risks,
mitigations).

Open points: authentication for API clients (for example API tokens), and how the
existing access control (`Scope`, `Members.Rights`) applies to API requests.

## Component hierarchy for systems

A system is a flat entry below an organisation. Allow a hierarchy, for example a system
that consists of sub-systems, which contain services.

Open points: the number of levels and their names, and how assets and threats relate to
a component and to its parent system.

## Upgrade PostgreSQL in production

Production runs PostgreSQL 15.18 (Cloud SQL instance `threatshield-db`, checked on
2026-10-07). The repository uses 18 everywhere: CI, Docker Compose, the Kubernetes files,
and `deployment/gcp/create_database.py`. So the tests run against a newer major version
than production.

Upgrade the instance to 18 with an in-place major version upgrade of Cloud SQL. Take a
backup first and check that automated backups are enabled. Until then, consider running
the tests against 15 as well.
