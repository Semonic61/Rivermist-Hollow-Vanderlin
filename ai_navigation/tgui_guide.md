# TGUI Guide

Last validated 2026-11-16 against main: source locations, route loading, imports,
locale wrappers, and build/test scripts. No browser session or frontend tests ran.
Use the universal `ss13-tgui` skill for UI lifecycle, security, and performance rules.

## Source Routes

| Concern | Open first |
|---|---|
| DM interface entrypoints | [external.dm](../code/modules/tgui/external.dm) |
| UI ownership | [tgui subsystem](../code/controllers/subsystem/tgui.dm) |
| Per-user UI datum | [tgui.dm](../code/modules/tgui/tgui.dm) |
| Browser window wrapper | [tgui_window.dm](../code/modules/tgui/tgui_window.dm) |
| Interface routing | [routes.tsx](../tgui/packages/tgui/routes.tsx) |
| Application entry | [index.tsx](../tgui/packages/tgui/index.tsx) |
| Backend hook | [backend.ts](../tgui/packages/tgui/backend.ts) |
| Window layouts | [layouts](../tgui/packages/tgui/layouts/) |
| Existing complete example | [ContractLedgerView.tsx](../tgui/packages/tgui/interfaces/ContractLedgerView.tsx) |
| Chat renderer | [renderer.tsx](../tgui/packages/tgui-panel/chat/renderer.tsx) |

The DM entry proc here is `ui_interact`, not `tgui_interact`.
Inspect a neighboring interface for its `SStgui.try_update_ui`, constructor,
`ui_data`, `ui_act`, and `ui_state` contracts. An interaction proc must actually
call `ui_interact`; do not assume every attack_hand/attack_self does so automatically.
Keep access and parameter validation on the DM side.

## Frontend Registration and Imports

`tgui/packages/tgui/routes.tsx` uses `require.context` and resolves an interface name to a matching
file or directory index and named export. New standard interfaces use the existing
interfaces directory and matching exported name; there is no separate manual route table.

Main's ContractLedgerView imports shared components from `tgui-core/components`,
`useBackend` from `../backend`, and `Window` from `../layouts`.
Shared UI building blocks come from tgui-core/components, not a components directory in this package.
A new interface filename mentioned in an example is a proposed file, not an existing route.

## RMH Locale Wrappers

Existing bilingual interfaces keep thin route wrappers, shared view logic, and locale data:

- [ContractLedger.tsx](../tgui/packages/tgui/interfaces/ContractLedger.tsx) and
  [ContractLedgerRu.tsx](../tgui/packages/tgui/interfaces/ContractLedgerRu.tsx);
- [ContractLedgerView.tsx](../tgui/packages/tgui/interfaces/ContractLedgerView.tsx);
- [English locale](../tgui/packages/tgui/interfaces/ContractLedger.i18n.en.ts) and
  [Russian locale](../tgui/packages/tgui/interfaces/ContractLedger.i18n.ru.ts);
- [preferred_language.dm](../modular_rmh/code/modules/client/preferred_language.dm).

Follow the neighboring wrapper and locale pattern when the task requires bilingual UI.
Preserve stable action names, ids, and state in the DM payload; check the actual language
selector before choosing the route. Existing multilingual support does not require an
unrelated feature request to stop for a localization approval.

## Build and Verification

Source commands: [tgui/package.json](../tgui/package.json),
[root package.json](../package.json), and [build.ts](../tools/build/build.ts).

- From the tgui workspace: `bun tgui:build` uses Rspack, `bun tgui:dev` starts the
  dev server, `bun tgui:tsc` type-checks, and `bun tgui:test` runs Bun tests.
- The test workspace declares happy-dom and Testing Library dependencies. The old
  Jest/jsdom description and webpack cache recipe do not describe these scripts.
- From the repository root, the build wrapper handles TGUI and DM. DmTarget's local
  dependency waits for TGUI and its RSC logic repacks changed packed bundles.
- Root `tgui:lint` is Biome lint; `tgui:fix` writes fixes. Do not describe lint as
  automatically fixing files or the frontend build as running the full CI suite.

## Audit Limits

Imports, source paths, locale wrappers, route lookup, and script definitions were
read. UI security for every caller, all payload shapes, browser cache behavior,
rendering, accessibility, localization coverage, and runtime updates were not
exercised. Consult the real backend and the universal skill before implementation.
