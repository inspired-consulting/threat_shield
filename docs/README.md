# Documentation

Each folder holds one kind of content with its own lifetime.
Folders are created on demand, when the first document needs them.

| Folder       | Contains                                                                  | Lifetime                                            |
|--------------|---------------------------------------------------------------------------|-----------------------------------------------------|
| `plans/`     | What we plan to build, in steps. Links to the ADRs it depends on.         | Shrinks while the work is built. Deleted when done. |
| `specs/`     | What is built and how it behaves. Enough to rebuild behavior and design.  | Permanent. Updated with every change.               |
| `adr/`       | Architecture decision records: why we decided, and what we rejected.      | Permanent. Not edited after acceptance.             |
| `resources/` | Reference material, such as threat-modeling background and product facts. | Permanent.                                          |
| `audit/`     | Reviews and audit results.                                                | Kept as a record.                                   |

## Rules

- **Plan to spec.** When a step of a plan is built, remove it from the plan and
  describe the result in the spec. Move only what is built. Each plan has a
  status line at the top.
- **Decisions go into ADRs.** When a discussion ends in a decision with a serious
  rejected alternative, write an ADR. Plans and specs link to ADRs and do not
  repeat them.
- **Working rules stay in `AGENTS.md`.** Specs do not repeat them.
- **Backlog.** `plans/backlog.md` holds short entries for open work without a plan
  of its own. When work on an entry starts and needs steps, it gets its own file
  and is removed from the backlog.

## ADR conventions

- One decision per file, at most one screen long, named `NNNN-short-title.md`.
- An ADR is not edited after acceptance. A changed decision gets a new ADR, and
  the old one is set to "Superseded by NNNN".
