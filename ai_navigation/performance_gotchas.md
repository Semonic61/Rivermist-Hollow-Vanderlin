# Performance Gotchas

Main source-path and selected contract corrections: 2026-11-16. These are investigation routes and cost hypotheses, not performance measurements of main. Consult the universal DM skill for engine semantics.

Read `engine_limits.md` first for the underlying numbers. This file answers "what specific code patterns trigger those limits?"

---

## 1. Infinite Loop Without a Sleep → World Lockup

**Situation:** A `for(;;)` or `while(1)` loop that never calls `sleep()`, `spawn()`, or any other yielding instruction.

**Effect:** The single-threaded server cannot process any other procedure or player input until the loop exits. The engine's **automatic abort** will eventually kill the procedure, but not before causing a visible freeze.

**Fix:** Use the existing subsystem or timer pattern and its tick checks for recurring work. Do not add a sleep to a non-sleeping handler or create a second heartbeat loop.

**Repo anchor:** `code/controllers/subsystem.dm` → `fire()` is the correct scheduling unit for recurring work. See `ai_navigation/subsystem_map.md` for the full subsystem list.

---

## 2. Mutating an Indexed Processing Registry

**Situation:** Removing entries while a manual index loop is reading the same live list.

**Effect:** Indices and bounds can stop referring to the intended objects. Do not
reuse an old blanket claim that world.contents has undefined for-in behavior.

**Fix:** Inspect the caller's iteration contract. Main's generic processing loop
uses currentrun = processing.Copy() and checks QDELETED while it drains that
snapshot. Keep add/remove, resume state, and deletion checks paired. Ordinary
for-in semantics belong to the universal DM runtime reference; an extra Copy is
not automatically required on every ordinary list.

**Repo anchor:** code/controllers/subsystem/processing/_processing.dm.

---

## 3. Yielding Without Checking Caller and waitfor Semantics

**Situation:** A shared process/callback path sleeps or waits for input.

**Effect:** Whether the caller waits depends on the actual call and waitfor
contract. A pause can suspend an owning loop or detach work; it is not a
guaranteed delay of the original game action. Signal handlers are explicitly
non-sleeping in the local SIGNAL_HANDLER macro.

**Fix:** Trace the owning subsystem and callback chain. Use the existing async
or timer mechanism for delayed work and revalidate references afterward. Do
not apply the imported claim that every server callback treats sleep identically.

**Repo anchors:** code/controllers/subsystem.dm, code/controllers/master.dm,
code/__DEFINES/dcs/helpers.dm.

---

## 4. Not Null-Checking Object References After a Sleep → Proc Crash

**Situation:** A proc stores a reference to an object, calls `sleep()`, then uses the reference after resuming without checking it.

**Effect:** The object may have been deleted during the sleep. Accessing a variable or proc on a null (deleted-object) reference crashes the procedure and logs a runtime to `world.log`.

**Fix:** After every `sleep`, treat all object references as potentially null. Pattern:
```dm
sleep(10)
if(QDELETED(src) || QDELETED(myobj))
    return
```

**Repo anchor:** Common in status effect procs (`code/datums/status_effects/**`), timed combat effects, and any `do_after`-style pattern in `code/__HELPERS/**`.

---

## 5. `list + list2` in a Tight Loop → Repeated Allocation

**Situation:** Using `mylist = mylist + other` (the `+` operator) inside a loop or a frequently-called proc.

**Effect:** Each `+` creates a **new list object**. In a loop this allocates N new lists, all of which the GC must eventually reclaim. On a busy server this adds GC pressure between ticks.

**Fix:** Use `mylist += other` (in-place append) whenever you do not need to preserve the original list. Accumulate into a pre-allocated list and return it once.

**Repo anchor:** Spell effect resolution (`code/datums/components/**`), reagent chain processing (`code/modules/reagents/**`), anywhere a list of targets is built iteratively.

---

## 6. Broadcasting to `world` or `view()` With Heavy Data → Bandwidth Spike

**Situation:** `world << large_output` or sending large sound/icon resources to many clients at once.

**Effect:** Resources are automatically transmitted to all clients that don't have them cached. Sending many large files simultaneously creates a bandwidth spike that manifests as network lag (distinct from server CPU lag).

**Fix:** Prefer targeted sends. Pre-load resources during init if they will be needed at runtime. Use profiling and client/network evidence; low world.cpu alone does not distinguish network latency from rendering cost.

**Repo anchor:** `code/modules/tgui/**` (UI updates to all clients), `code/modules/visual_ui/**` (visual effect broadcasts), sound subsystem.

---

## 7. Excessive Unique Overlay Combinations → Appearance Object Accumulation

**Situation:** Dynamically generating overlays with many varying parameters per mob or object (e.g. per-player color-shifted icons, animated overlays that change every tick for many entities).

**Effect:** Each unique combination of icon/state/color/transform registers a distinct Appearance object in the engine. These accumulate in server memory. Every time an Appearance changes on a visible atom, the new state must be sent over the network to every client that can see it. High overlay churn on many entities = high memory + high bandwidth simultaneously.

**Fix:** Reuse Appearance objects by caching icon references rather than recomputing them. Limit per-tick overlay changes. Prefer icon state changes (`icon_state =`) over overlay add/remove cycling. Batch overlay updates and only apply them at the end of the owning proc.

**Repo anchor:** `modular_rmh/` overlay and clothing systems; `code/modules/visual_ui/**`; any system that calls `overlays +=` or `overlays -=` in a loop or per-tick proc.

---

## 8. Decreasing `tick_lag` Too Far → Counter-Productive CPU Overhead

**Situation:** Setting `world.tick_lag` to a very small value (e.g. `0.1` or lower) to get more precise timings.

**Effect:** The per-tick scheduling overhead grows with tick frequency. Below a viable threshold, the overhead itself consumes more CPU than the actual game logic, making `world.cpu` spike and the server run *slower* in absolute terms.

**Fix:** Profile `world.cpu` before changing `tick_lag`. The project's master controller (`code/controllers/master.dm`) manages tick budget — consult `ai_navigation/runtime_flow.md` before adjusting scheduler timing.

---

## 9. `view()` with a Large Range on Many Mobs → Spatial Query Flood

**Situation:** Calling `view(10)` or `range(10)` in a proc that fires every tick for every mob (e.g. inside a subsystem `process()` that iterates all living mobs).

**Effect:** Even though `view()` is a built-in VM instruction, calling it at tick frequency for hundreds of mobs multiplies its cost. The 21×21 grid at range 10 is roughly 4× the tile count of the default 11×11.

**Fix:** Cache the view list when the mob has not moved. Compute it only on movement or at a longer interval using a lower-priority subsystem. Use `range()` (ignores opacity) instead of `view()` if line-of-sight is not needed.

**Repo anchor:** NPC AI subsystem, spell AoE code (`code/modules/spells/**`), combat detection procs.

---

## 10. Bitwise Operations on Values Outside 0–65535 → Silent Truncation

**Situation:** Using `&`, `|`, `^`, `~`, or bit-shift operators on numbers outside the 16-bit unsigned range.

**Effect:** Values are silently truncated to 16 bits. No runtime error is thrown. Flag checks on large integers will produce wrong results without any warning.

**Fix:** Keep all bitwise flag values within 0–65535. The project's flag defines in `code/__DEFINES/` already do this — do not add new flags that require more than 16 bits without switching to a different mechanism.

---

*Cross-references: → `engine_limits.md` for the underlying numbers behind each hazard. → `processing_hazards.md` for subsystem-level freeze diagnosis. → `runtime_flow.md` for scheduler and tick-budget context. → `visuals_guide.md` for full overlay/plane/appearance system details. → `coding_standards.md` for appearance caching patterns and harddel fixes.*
