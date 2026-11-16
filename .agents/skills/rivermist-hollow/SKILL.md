---
name: rivermist-hollow
description: Apply the Rivermist-Hollow-Vanderlin repository profile to BYOND DM development, review, navigation, build, and diagnostics work in this checkout. Use alongside the universal BYOND/SS13 skills after confirming repository identity; its fork-specific facts do not apply to other Vanderlin forks.
---

# Rivermist Hollow

Bind the universal BYOND/SS13 skills to this repository. Keep fork facts in the
[repository profile](../../../ai_navigation/rivermist_hollow_profile.md), rather
than copying universal skill instructions here.

## Establish the repository

Resolve the checkout root from ../../../ relative to this skill directory.
Confirm that its
`README.md` identifies Rivermist Hollow, `vanderlin.dme` exists, and both
`modular_rmh/` and `ai_navigation/` are present. Do not identify this fork from
the project filename alone. If these markers disagree, use source inspection
and the universal skills without applying this profile's fork facts.

Read the branch-local [main port status](../../../ai_navigation/MAIN_PORT_STATUS.md)
for validation scope and source revision. Main validation is not evidence that
another branch or a later checkout has identical contracts.

## Workflow

1. Read the root [AGENTS.md](../../../AGENTS.md) and
   [navigation instructions](../../../ai_navigation/AGENTS.md). Start navigation
   through [router.md](../../../ai_navigation/router.md); use the repository
   profile for fork-specific architecture and verification questions. Open
   further helpers only when the task needs them.
2. Use `byond-codemaster-controller` for skill routing and binding to the local
   navigation base. Use `byond-ss13-coding` for DM implementation and review,
   `ss13-tgui` for TGUI work, and `tgstation-modular-content` when a new placement
   or mergeability decision is needed. Resolve these skills from the session's
   available skills; do not assume an installation path. If one is unavailable,
   report that and continue from available instructions and source.
3. Inspect `git status` before edits, preserve existing work, and honor the
   user's scope and authorization. This profile does not authorize changes to
   the build graph, shared systems, commits, or publishing on its own.
4. Find the core definitions, then the relevant RMH declarations and actual
   include order. Follow the profile's source links for local signatures,
   placement, build commands, and diagnostics; do not import another Vanderlin
   profile's directory layout or API names.
5. Run the checks required for the files actually changed. After DM or `.dme`
   edits, use both repository diagnostics and the repository BYOND build as
   required by `AGENTS.md`. Report which checks ran and their actual results.

## Keeping facts current

The profile records a static inspection, not a permanent engine or runtime
guarantee. Source code wins over stale navigation facts; universal engine
semantics still apply. Report mismatches, and update local documentation only
within the authorized task. Do not modify universal skills to encode this
fork's paths or conventions.
