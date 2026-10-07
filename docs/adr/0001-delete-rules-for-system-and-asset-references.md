# 0001 Delete rules for system and asset references

**Status:** Proposed (2026-10-07)

## Context

Assets and threats can reference a system, and threats can reference an asset. The
database had no delete rule for these references, so a system with assets or threats and
an asset with threats could not be deleted: the delete failed with a foreign key error,
and the page crashed. In production, 18 of 21 systems were in this state.

The migrations from September 2023 had set `on_delete: :delete_all` for both system
references. The consolidation of the migrations in February 2024 lost these rules.

## Decision

- Deleting a **system** deletes its assets and its threats (`on_delete: :delete_all` for
  `assets.system_id` and `threats.system_id`). This restores the original rule.
- Deleting an **asset** keeps its threats and clears the reference
  (`on_delete: :nilify_all` for `threats.asset_id`). A threat belongs to the organisation
  and may also belong to a system; the asset is one aspect of it.

The rules live in the database, not in application code, so every delete path behaves
the same.

## Consequences

- A system delete can remove many entities, with their risks and mitigations. The user
  interface asks for a confirmation already; the text should name the effect.
- After an asset delete, its former threats show no asset.

## Rejected alternatives

- **Clear the reference for all three columns.** Keeps all data, but leaves assets and
  threats that belong to no system, which the pages do not present well, and it differs
  from the original design.
- **Delete children in application code.** Would need the same logic in every delete
  path and would not protect against direct database changes.
