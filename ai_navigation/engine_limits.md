# Engine Limits and Local Runtime Settings

Last reviewed 2026-11-16 for main source settings and removal of unsupported claims.
This navigation file is not an engine specification. Use `byond-ss13-coding` for
DM semantics and `byond-engine-internals` when a question needs engine implementation
evidence. No runtime timing, memory, network, or client measurements ran in this audit.

## Checked Local Settings

| Setting or contract | Evidence in main |
|---|---|
| World FPS | `fps = 20` in [world.dm](../code/world.dm); nominal tick_lag is 0.5 deciseconds unless runtime configuration changes it |
| World view | `view = "15x15"` in the same file; do not substitute the engine's default viewport |
| Processing interval | [processing/_processing.dm](../code/controllers/subsystem/processing/_processing.dm) passes `wait * 0.1` to `process(delta_time)`, in seconds |
| Scheduler yield/resume | [subsystem.dm](../code/controllers/subsystem.dm) and [master.dm](../code/controllers/master.dm) handle sleeping and resumed subsystem states |
| Cooperative tick checks | [MC.dm](../code/__DEFINES/MC.dm) and [the master controller](../code/controllers/master.dm) |
| Queued deletion | [garbage.dm](../code/controllers/subsystem/garbage.dm), [datum.dm](../code/datums/datum.dm) |
| Global signal target | [DCS helpers](../code/__DEFINES/dcs/helpers.dm): `SEND_GLOBAL_SIGNAL` targets SSdcs |
| Compiler pin | [dependencies.sh](../dependencies.sh): BYOND 516.1687; a pin is not the installed version |

## Timing and Ownership

A configured interval and elapsed time are different quantities. Scale periodic work
according to the caller's documented units. A processing proc that sleeps can suspend
its own owning loop even though other DM work can run; inspect its caller and the
scheduler rather than assuming a sleep is a harmless delay.

Signals marked `SIGNAL_HANDLER` use the local non-sleeping contract. For asynchronous
work, use the existing project's timer/callback or subsystem pattern, then revalidate
references after the gap. Avoid inventing a second heartbeat loop.

## Deletion and Lists

`qdel` starts cleanup and queues reclamation according to its hint. It is not equivalent
to a completed hard deletion and does not promise every reference immediately becomes
null. Inspect `QDELETED` / `QDELING`, the target's Destroy chain, and the queue's ownership.

Ordinary list iteration and manual index loops have different mutation behavior and
allocation costs; consult the universal DM runtime reference. Do not infer safety from
an old blanket exception about world.contents, or copy numeric memory-cost estimates
without a verified source/build. Bound growing state and pair registration with cleanup.

## What This File Does Not Establish

The imported claims of a 16-bit bitwise limit, a maximum view of 10, a one-tick minimum
for every sleep/spawn, and a universal one-command-per-tick client cap were removed.
They were not supported by main source inspection. Engine limits require the current
DM Reference or build-specific evidence, not repository folklore.

Likewise, low world.cpu does not by itself distinguish network latency from a client
rendering bottleneck. Measure the relevant layer. Use [performance_gotchas.md](performance_gotchas.md)
for local investigation routes and [MAIN_PORT_STATUS.md](MAIN_PORT_STATUS.md) for audit limits.
