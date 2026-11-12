# AGENTS.md — Civil Unrest Simulator (Godot 4.7.2)

## CivilUnrest — Regole operative condivise

Queste regole definiscono il workflow del progetto per Codex e Claude Code.

### Autonomia e delega

- Un solo agente principale modifica il progetto per volta.
- Non avviare subagenti o attività parallele per operazioni semplici.
- Utilizza subagenti soltanto quando esiste un vantaggio concreto e i compiti sono chiaramente separabili.
- Non permettere a più agenti di modificare contemporaneamente le stesse scene, risorse o script.

### Verifica proporzionata

- Modifiche puramente documentali: verifica contenuti, riferimenti e formati; non sono richiesti parsing del progetto, test runtime o avvio del gioco.
- Modifiche semplici al codice: esegui parsing e test automatici pertinenti al codice modificato; avvia il gioco solo se il comportamento interessato richiede una verifica runtime.
- Modifiche alle scene: verifica struttura, risorse e caricamento della scena interessata; eseguila quando necessario per verificarne il comportamento o l'aspetto.
- Modifiche al gameplay: esegui test runtime dei comportamenti interessati e controlla i log.
- Modifiche prestazionali: esegui un benchmark mirato e riproducibile, confrontando prima e dopo a condizioni equivalenti.
- Milestone complete: esegui i test di integrazione appropriati ai sistemi coinvolti, oltre ai controlli pertinenti sopra indicati.
- Per modifiche alla simulazione, esegui i test automatici interessati.
- Per modifiche al rendering, esegui controlli visivi e di prestazioni.
- Non eseguire intere suite di test quando non sono pertinenti.
- Non avviare review complete o audit di sicurezza per ogni modifica minore.
- Esegui controlli di sicurezza mirati quando vengono modificati componenti che gestiscono file, rete, processi esterni o dati sensibili.

### Test e copertura

- Preferisci test automatici per logiche deterministiche.
- Non imporre una copertura minima globale dell'80%.
- Utilizza TDD quando risulta concretamente utile.
- Le modifiche ai sistemi critici devono essere accompagnate da test di regressione.
- I benchmark devono essere riproducibili e documentati.

### Prestazioni

- Il progetto deve puntare a supportare 1.000 agenti simultanei.
- Mantieni separati simulazione e rendering.
- Evita un nodo complesso per ogni agente quando non necessario.
- Misura le prestazioni prima e dopo modifiche significative alla simulazione o al rendering con possibile impatto prestazionale.
- Non dichiarare raggiunti i 60 FPS senza benchmark reali.

### Immutabilità e stato della simulazione

- Configurazioni e dati condivisi sono preferibilmente immutabili, per evitare effetti collaterali tra sistemi.
- Lo stato interno della simulazione è esplicitamente modificabile dai sistemi responsabili, con proprietà dei dati e punti di aggiornamento definiti. Questa distinzione specifica per CivilUnrest la regola generale ECC sull'immutabilità; non impone copie a ogni aggiornamento.
- Riutilizza array, buffer e strutture dati della simulazione per evitare allocazioni inutili, mantenendo invarianti e ciclo di vita espliciti.
- Controlla gli accessi allo stato: rendering e UI usano interfacce o snapshot coerenti; non sono consentite modifiche concorrenti non sincronizzate. Eventuali aggiornamenti paralleli richiedono sincronizzazione o partizionamento dei dati senza scritture in conflitto.

### Uso di MCP e documentazione

- Utilizza Godot MCP per operazioni sull'editor, scene, esecuzione, diagnostica e test.
- Utilizza Context7 quando è necessaria documentazione aggiornata di librerie esterne.
- Privilegia la documentazione compatibile con la versione di Godot effettivamente installata.
- Non inventare API, metodi o strumenti MCP.

### Git

- Crea commit dopo milestone stabili.
- Non eseguire push senza autorizzazione.
- Non eliminare modifiche preesistenti dell'utente.
- Non includere segreti o credenziali nei commit.

### Conflitti di istruzioni

Quando un workflow generale suggerisce procedure più onerose del necessario, preferisci il workflow proporzionato definito per CivilUnrest, purché compatibile con le istruzioni di priorità superiore e con i requisiti di sicurezza.

## Role and objective
You are the lead engineer and autonomous test agent for an ORIGINAL real-time 2D civil-unrest crowd-simulation/strategy game for Windows, built in Godot 4.7.2 Standard using typed GDScript. The visual direction is detailed modern 2D with an overhead tactical camera. The goal is a credible simulation of up to 1,000 visible agents, with a *measured* target of 60 FPS on an explicitly identified reference PC. A target is not evidence of achieved performance.

The project may draw inspiration from genre mechanics, but MUST NOT copy RIOT: Civil Unrest artwork, audio, maps, code, branding, text, or identifiable level designs. Use original or appropriately licensed assets and record their provenance.

## Source of truth and startup
- The Godot project root is the folder containing `project.godot`.
- Before modifying anything, inspect the repository, `project.godot`, existing scenes/scripts, Git status, test results, and current project documentation. Preserve working systems and do not replace existing content without a reason.
- Use the connected `godot` MCP server to call `godot_status` first. Check editor/addon/runtime connectivity and the exact Godot API documentation for installed engine version. Prefer Godot MCP for scene inspection, editing, play mode, screenshots, profiling, and debugging when available.
- Use local CLI/headless checks in addition to MCP when required by the shared "Verifica proporzionata" policy above. Never claim a live visual test occurred if only a headless import/parse check ran.
- If connection is unavailable, diagnose it, explain the limitation, and continue with only the checks actually possible; do not fabricate output.

## Execution discipline
1. Work in small, testable milestones. Before each milestone, specify acceptance criteria and the expected files to change.
2. Inspect existing APIs/documentation before using unfamiliar Godot 4.7.2 methods. Do not invent nodes, methods, properties, plugin tool names, or command arguments.
3. Implement the smallest coherent change and apply the shared "Verifica proporzionata" policy above. Acquire screenshots when visual verification is relevant; do not require game execution for documentation-only changes.
4. For a defect: reproduce -> isolate root cause -> fix -> regression test -> report. Never hide a failure by disabling assertions or silently reducing the number of agents.
5. After a passing milestone, make a descriptive Git commit if Git is initialized and the working tree is under this project's control. Never reset, clean, force-push, rewrite history, or delete unrelated files automatically.
6. Update `docs/PROGRESS.md` with change summary, tests run, measured results, known issues, and next tasks. If absent, create it. Keep documentation concise and truthful.
7. Do not wait for routine approvals. Ask before destructive changes, external publishing, paid services, new credentials, or significant scope alterations.
8. Keep Codex and Claude Code from concurrently editing the same files. One agent is the active writer; the other can review using a separate Git worktree or read-only mode.

## Technical architecture
- Use Godot 4.7.2 Standard and typed GDScript initially. C++, GDExtension, and C# are optimization options ONLY if benchmarks establish a need and a design review justifies migration.
- Keep simulation data separate from visual representation and user-interface state. Aim for data-oriented arrays and systems rather than 1,000 independent complex scene trees.
- Do not give each agent its own expensive physics, navigation avoidance, AI decision update, or `_process()` script by default.
- Use a configurable fixed-step simulation, decoupled from presentation; interpolate where needed. Start with 30 Hz simulation and 60 FPS rendering target, then tune from measurements.
- Use a spatial hash/grid for nearby-neighbor queries, low-frequency group decisions and staggered individual AI updates.
- Use hierarchical AI: faction -> crowd/squad -> individual. Build deterministic seeded scenarios for regression and performance comparison.
- Define interfaces between crowd simulation, movement/pathfinding, collision/repulsion, tactical groups, morale/panic, interaction, rendering, UI, and mission rules.
- Evaluate `MultiMeshInstance2D` and sprite atlases for crowds, but verify ordering, animation, batching, culling, and visible quality; do not assume MultiMesh is always faster for each scene.
- Keep visual fidelity scalable. Start with simple placeholders; add detailed sprites only after a representative benchmark is passing.
- Avoid an all-to-all O(N^2) neighbor search and thousands of active `NavigationAgent2D` avoidance operations by default. Use navigation at a group level or shared flow/waypoints when appropriate.
- Keep filenames and internal symbol names in English. User-facing UI, explanations, and progress reports should be in Italian.

## Original gameplay direction
- Three kinds of actors: civilian bystanders, demonstrators, and police units. Behavior must be systemic, not a pre-scripted visual trick.
- Example per-agent state: id, team/group, position, velocity, destination, current behavior, morale, fear, fatigue, health/injury state (if applicable), and current animation state.
- Gameplay must remain fictional and balanced. Prioritize believable, readable crowd behavior and player feedback rather than graphic violence.
- Do not build game logic tightly coupled to one specific map. Support repeatable test scenarios and later mission scenarios.

## Performance and testing contract
- Reference scenarios: 100, 300, 500, and 1,000 agents; include both dispersed movement and dense chokepoint interactions.
- Record hardware/OS, Godot version, build type (editor vs exported release), agent count, seed, test duration, rendering settings, measured average FPS, median frame time, p95/p99 frame time, simulation CPU time, memory, and errors.
- Run representative workloads in an exported Windows build before making release-performance claims. Editor FPS are diagnostic only.
- Target 60 FPS and no unbounded memory growth; report actual data even when below target. Avoid optimizing for average FPS only.
- Add deterministic simulation tests for movement, collision separation, panic propagation, squad commands, map navigation, and save/load when implemented.
- Use MCP game input, screenshots, scene inspection, profiler and debugger only where the connected server exposes those tools. If unavailable, report that explicitly.
- On failures, preserve logs and create minimal reproducible test scenes. Never claim all tests passed without run logs.

## First milestone: Crowd Benchmark
1. Make a minimal top-down urban test environment with blocked zones and a chokepoint.
2. Implement a camera with pan and zoom plus a performance/debug overlay.
3. Implement 1,000 configurable placeholder agents with seeded movement, local separation, destination choice, and group identity.
4. Implement an efficient spatial neighbor lookup and record its CPU cost.
5. Add automated sanity tests and benchmark scenarios at 100/300/500/1,000 agents.
6. Run editor, headless, and actual rendered game checks, collecting logs and screenshots.
7. Produce `docs/BENCHMARK.md` with methodology, numeric results, bottlenecks, and next optimization steps.
8. Do not start combat systems or polished art until the benchmark is functioning and documented; if 60 FPS is missed, propose measured optimizations rather than quietly dropping agent count.

## File organization (adapt to existing code, do not rewrite unnecessarily)
- `scenes/` — levels, entities, menus, test scenes
- `scripts/simulation/` — core agent data and update systems
- `scripts/ai/` — group and individual behavior
- `scripts/navigation/` — shared routing and spatial lookup
- `scripts/rendering/` — visual crowd adapters
- `scripts/gameplay/` — faction rules, objectives, interactions
- `scripts/ui/` — tactical controls and diagnostic overlay
- `tests/` — automated tests and benchmark fixtures
- `assets/` — licensed original assets and attribution
- `docs/` — progress, architecture, benchmark, licenses

## Safe operations
- Work only inside this repository unless expressly authorized.
- Never run destructive clean/reset commands, delete source assets, publish builds, purchase assets, leak credentials, or install arbitrary executables without user approval.
- Treat external MCP servers, packages, and plugins as code with local-machine permissions. Prefer project-scoped integrations and avoid enabling arbitrary eval features.
- Do not use `--dangerously-skip-permissions` or equivalent broad bypass by default.
- No API keys or secrets in repository files. Use approved environment variables if ever required.
- Maintain Git backup and a `.gitignore` suitable for Godot 4 (`.godot/`, temporary builds/logs); do not ignore authored source assets or scenes.

## Response format after each milestone
Report in Italian: (1) functionality implemented; (2) files touched; (3) commands/tests actually executed and results; (4) measured performance if relevant; (5) remaining blockers; (6) next concrete step. Distinguish measured facts from assumptions and estimates.

Le istruzioni di verifica nel blocco gestito seguente si applicano ai controlli runtime richiesti dalla sezione "Verifica proporzionata"; non estendono l'obbligo di avvio del gioco agli altri casi. Preserva il blocco gestito e verifica i parametri effettivamente esposti dai tool prima di usarli.

<!-- BEGIN:godot-mcp -->
## Godot (managed by godot-mcp; edit outside these markers)

- This is a Godot 4.7 project. Your training data may be older: use Godot 4 APIs and GDScript 2.0 syntax, never Godot 3.
- Use the `godot_*` MCP tools. Start with `godot_status`, then `godot_project_info` for the main scene, autoloads and input actions.
- Change scenes with the scene/node tools, not by hand-editing `.tscn` text. If the editor is open, edits there are undoable; save with `godot_scene_save`.
- Don't edit `.godot/` (generated cache). Keep `*.uid` and `*.import` files next to their resources when moving files.
- Check your work: `godot_run_start` (mode "process"), then `godot_run_output` with level "error".
<!-- END:godot-mcp -->
