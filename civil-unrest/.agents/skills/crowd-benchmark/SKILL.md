---
name: crowd-benchmark
description: Use for explicitly requested CivilUnrest Godot 4.7.2 crowd benchmarks, FPS or frame-time analysis, memory or CPU analysis, performance regressions, and simulation stress tests. Excludes simple diagnostics, documentation-only changes, non-performance read-only analysis, and fixes unrelated to performance.
---

## Activation and scope

Use this skill only for explicitly requested benchmarks, analysis of FPS/frame time/memory/CPU, performance regressions, or simulation stress tests in CivilUnrest.

Do not activate it for simple diagnostics, documentation-only changes, non-performance read-only analysis, or fixes unrelated to performance. Generic troubleshooting alone is not a trigger.

Performance analysis does not automatically authorize code changes, game execution, or report files. Respect the requested scope and any read-only constraint; use existing measurements when execution is outside scope.

## Procedure

1. Read AGENTS.md and follow its shared verification and simulation-state rules. Identify the affected systems, existing benchmark scenes/scripts, and the performance question to answer. Do not create game scenes or install test dependencies merely to complete this checklist.
2. For editor or runtime operations, start with the available Godot MCP `godot_status` tool. Check the actual engine version, Git status and existing benchmark method. Use only tool names and parameters actually exposed by the connected server. Target the installed Godot 4.7.2 APIs; report any version mismatch.
3. Choose the smallest representative workload for the requested analysis or regression. The complete crowd milestone covers 100, 300, 500 and 1,000 agents, including dispersed movement and a dense chokepoint; a targeted investigation need only run the relevant cases. Keep seeds, duration, rendering settings and hardware/build conditions identical for comparisons. Never reduce the agent count to hide a failure.
4. When running a benchmark, record hardware/OS, Godot version, editor or exported build, agent count, seed, duration, rendering settings, average FPS, median/p95/p99 frame time, simulation CPU time, memory and relevant errors. Mark unavailable metrics explicitly; do not invent values. For analysis of existing measurements, report their source and limitations without claiming a new benchmark ran.
5. Profile the bottleneck before any authorized optimization. Change one major variable at a time, then rerun the same relevant scenarios and regression tests for affected critical systems. Keep simulation separate from rendering and compare against the original workload.
6. Write or update `docs/BENCHMARK.md` only when a benchmark was actually executed and its documentation is within the requested scope. Record methodology, measured results, bottlenecks and whether targets were achieved; distinguish editor diagnostics from exported Windows release results. Without an executed benchmark, report findings or blockers directly without creating or updating that file.
7. If measurements or tests cannot run, state why and provide a short reproducible next-step checklist. Do not claim 60 FPS or successful validation without measured evidence.
