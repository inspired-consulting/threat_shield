# Backlog

**Status:** open list. Last updated 2026-10-06.

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
