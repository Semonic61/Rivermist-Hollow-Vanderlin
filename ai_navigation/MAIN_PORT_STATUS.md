# Navigation documentation port status — main

**Source:** `Map-again` commit `4b394d3fd8b964445fbe7b0caf9b69461988d283`  
**Target:** `main` (base commit `efebebda520623c364c245a15194d787cf2fc000`)  
**Copied on:** 2026-11-16

This is a **documentation-only import**, not a merge of `Map-again` into `main`. It copies the complete `ai_navigation/` snapshot and the repository-scoped `rivermist-hollow` Agent Skill. No game maps, DM files, `.dme`, build scripts, or other gameplay source are imported.

## Confidence and limits

- `main` was confirmed as the repository's default branch, but its game code is materially different from `Map-again`: the comparison showed hundreds of changed code files and divergent histories.
- The original navigation base is a dated snapshot (`router.md` reports its own validation date); the Rivermist profile was checked for **`Map-again`**, not systematically refreshed for `main`.
- A focused existence check found the 16 important source/configuration files referenced by the profile still present in `main`; this **does not** establish equivalent contents, contracts or behavior.
- Documentation hyperlinks within the imported navigation tree retain their relative structure. Their semantic correctness in `main` remains to be reviewed.

## Mandatory use until refreshed

1. Start with `AGENTS.md`, `ai_navigation/AGENTS.md` and `router.md`, but interpret navigation output as potentially stale.
2. Inspect real definitions and include order in the **selected branch** before recommending or editing code.
3. If a claimed type, proc, signal or subsystem cannot be found, perform a direct source search instead of silently reading `Map-again`; report any discrepancy.
4. Before claiming that this documentation is validated for `main`, run a proper navigation refresh using `ai_navigation/update_policy.md`, updating profiles and indices from `main` only.
5. When working on `Map-again`, use its own branch-local documentation, not this imported snapshot, unless explicitly comparing versions.

Status: **ported, pending main-specific semantic refresh**.
