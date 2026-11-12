---
name: crowd-benchmark
description: Run reproducible Godot 4.7 crowd simulation benchmarks and investigate 100 to 1000-agent performance regressions.
---

When asked to benchmark, optimize or troubleshoot the crowd simulation:
1. Read AGENTS.md and identify the currently implemented benchmark scenes/scripts.
2. Check the Godot MCP connection, current Godot version, Git status and existing benchmark method.
3. Use reproducible seeds and identical rendering settings for 100, 300, 500 and 1,000 agents, including a dense chokepoint case.
4. Measure and record average FPS, median/p95/p99 frame time, simulation CPU time, memory, relevant errors and exact hardware/build information. Do not invent any values.
5. Profile the bottleneck before optimization, change one major variable at a time and rerun the same scenarios.
6. Save findings to docs/BENCHMARK.md and explain whether each target was achieved. Differentiate editor tests from exported Windows builds.
7. If tests cannot run, state why and provide a short reproducible next-step checklist.
