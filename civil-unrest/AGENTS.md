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

- Obiettivo tecnico di stress test: 1.000 agenti. Possibile limite iniziale di gameplay: 600 agenti, da decidere dopo benchmark rappresentativi, anche con grafica 3D.
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

- Proponi un commit dopo milestone stabili, ma crealo solo su richiesta o autorizzazione esplicita dell’utente.
- Non eseguire push senza autorizzazione.
- Non eliminare modifiche preesistenti dell'utente.
- Non includere segreti o credenziali nei commit.

### Economia dei token (stile Caveman Lite)

- Comunica in italiano con frasi brevi e precise; evita introduzioni, ripetizioni, commenti celebrativi e spiegazioni non richieste. Non sacrificare chiarezza, sicurezza, accuratezza, né dettagli essenziali.
- Limita le letture dei file alle parti pertinenti; non rileggere interi documenti o l'intero repository quando bastano diff, percorsi o intervalli mirati.
- Restituisci solo sintesi di log e stack trace rilevanti; conserva integralmente evidenze, benchmark e log nei rispettivi file. Non comprimere, arrotondare o alterare numeri usati per confronti e regressioni.
- Non ripetere nel messaggio il contenuto di file già salvati. Cita percorsi e sezioni modificate. Evita output massivi e chiamate MCP ridondanti; non saltare controlli obbligatori e non inventare risultati.
- Riutilizza informazioni verificate nella sessione quando ancora valide; consulta Context7 solo quando serve documentazione esterna aggiornata.
- Rapporto sintetico standard: `Modifiche`, `Test`, `Prestazioni` (se pertinenti), `Problemi`, `Prossimo passo`, indicando file e misure reali.
- Eventuali plugin Caveman possono migliorare la brevità delle risposte, ma non sostituiscono queste regole, non autorizzano compressione con perdita di evidenze e non devono peggiorare la qualità del lavoro.

### Conflitti di istruzioni

Quando un workflow generale suggerisce procedure più onerose del necessario, preferisci il workflow proporzionato definito per CivilUnrest, purché compatibile con le istruzioni di priorità superiore e con i requisiti di sicurezza.

## Role and objective
You are the lead engineer and autonomous test agent for an ORIGINAL real-time civil-unrest crowd-simulation/strategy game for Windows, built in Godot 4.7.2 Standard using typed GDScript. The final visual direction is stylized-realistic **3D isometric** environments with an **orthographic camera**, zoom/pan, and optional **90-degree rotation steps**. Agent gameplay simulation remains **2D on the ground plane**, mapped to 3D world X/Z coordinates via a separate presentation adapter. Preserve the existing 2D benchmark renderer and tests as diagnostic tooling; do not discard or rewrite working simulation code merely for the presentation change.

Design references: RIOT: Civil Unrest for high-level tactical crowd-simulation genre mechanics and STILL for the broad visual mood (detailed urban spaces, readable isometric composition). Make entirely original assets, map layouts, art direction, UI, mechanics and branding; do not reproduce either game's distinctive assets. Technical stress target: 1,000 simulated agents; potential initial gameplay cap: 600 active agents, pending comparable benchmarks in a representative 3D scene and exported Windows release build. Target 60 FPS on an identified reference PC; targets are not measured results.

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
5. After a passing milestone, suggest a descriptive Git commit, but do not create one without the user’s explicit approval. Never reset, clean, force-push, rewrite history, or delete unrelated files automatically.
6. Update `docs/PROGRESS.md` with change summary, tests run, measured results, known issues, and next tasks. If absent, create it. Keep documentation concise and truthful.
7. Do not wait for routine approvals. Ask before destructive changes, external publishing, paid services, new credentials, or significant scope alterations.
8. Keep Codex and Claude Code from concurrently editing the same files. One agent is the active writer; the other can review using a separate Git worktree or read-only mode.

## Technical architecture
- Use Godot 4.7.2 Standard and typed GDScript initially. C++, GDExtension, and C# are optimization options ONLY if benchmarks establish a need and a design review justifies migration.
- Keep simulation data (2D coordinates and dynamics) separate from 3D visual representation and user-interface state. Aim for data-oriented arrays and systems rather than 1,000 independent complex scene trees.
- Do not give each agent its own expensive physics, navigation avoidance, AI decision update, or `_process()` script by default.
- Use a configurable fixed-step simulation, decoupled from presentation; interpolate where needed. Start with 30 Hz simulation and 60 FPS rendering target, then tune from measurements.
- Use a spatial hash/grid for nearby-neighbor queries, low-frequency group decisions and staggered individual AI updates.
- Use hierarchical AI: faction -> crowd/squad -> individual. Build deterministic seeded scenarios for regression and performance comparison.
- Define interfaces between crowd simulation, movement/pathfinding, collision/repulsion, tactical groups, morale/panic, interaction, rendering, UI, and mission rules.
- Keep the existing `MultiMeshInstance2D` or other 2D benchmark renderer where useful for diagnostics. For final 3D presentation, evaluate `MultiMeshInstance3D`, mesh LOD, visibility culling, efficient animations and shadow settings; benchmark actual appearance and cost rather than assuming one approach is faster.
- Use orthographic 3D camera with tactical zoom/pan and optional discrete 90-degree yaw rotations. Handle building occlusion with appropriate transparency, cutaways or tactical overlays; ensure squads remain readable.
- Keep visual fidelity scalable. Start with representative low-cost 3D placeholders; measure an actual 3D urban vertical slice before selecting expensive assets, lighting and effects. A 2D benchmark cannot validate final 3D frame rate.
- Avoid an all-to-all O(N^2) neighbor search and thousands of active per-agent navigation avoidance operations by default. Use navigation at group level or shared flow/waypoints when appropriate, without coupling simulation to the 3D renderer.
- Keep filenames and internal symbol names in English. User-facing UI, explanations, and progress reports should be in Italian.

## Original gameplay direction
- Three kinds of actors: civilian bystanders, demonstrators, and police units. Behavior must be systemic, not a pre-scripted visual trick.
- Example per-agent state: id, team/group, position, velocity, destination, current behavior, morale, fear, fatigue, health/injury state (if applicable), and current animation state.
- Gameplay must remain fictional and balanced. Prioritize believable, readable crowd behavior and player feedback rather than graphic violence.
- Do not build game logic tightly coupled to one specific map. Support repeatable test scenarios and later mission scenarios.

## Performance and testing contract
- Reference scenarios: 100, 300, 500, 600, 800, and 1,000 agents where relevant; include both dispersed movement and dense chokepoint interactions. Keep legacy 100/300/500/1,000 baselines comparable.
- Record hardware/OS, Godot version, build type (editor vs exported release), agent count, seed, test duration, rendering settings, measured average FPS, median frame time, p95/p99 frame time, simulation CPU time, memory, and errors.
- Run representative workloads in an exported Windows release build before making release-performance claims. Editor/debug FPS and the existing 2D benchmarks are diagnostic only; additionally profile a representative 3D scene with animation, lighting and geometry.
- Target 60 FPS and no unbounded memory growth; report actual data even when below target. Avoid optimizing for average FPS only.
- Add deterministic simulation tests for movement, collision separation, panic propagation, squad commands, map navigation, and save/load when implemented.
- Use MCP game input, screenshots, scene inspection, profiler and debugger only where the connected server exposes those tools. If unavailable, report that explicitly.
- On failures, preserve logs and create minimal reproducible test scenes. Never claim all tests passed without run logs.

## Milestone status and next steps
- Existing completed work (as reported, verify against repository): 20-agent MCP runtime test, modular 2D crowd benchmark, fixed 30 Hz simulation with interpolated rendering, spatial grid, deterministic tests and `docs/BENCHMARK.md`. Preserve all of it.
- The latest reported 1,000-agent chokepoint **debug** measurement was 53.90 average FPS, p95 40.91 ms, simulation 22.83 ms/tick; not a 3D or exported-release result. Read the latest repository benchmark before using these historical numbers.
- Finish the already requested CPU/performance and congestion investigation, including 600/800-agent comparison, without changing the gameplay cap silently.
- Next visual milestone, only after the current benchmark is documented: **3D isometric vertical slice**, with a small original urban space, a few buildings, a police vehicle, a manageable set of representative animated agents, orthographic camera, zoom/pan, and 90-degree camera rotation. Retain 2D simulation and the existing diagnostics; measure visual cost separately.
- Do not begin full combat/faction gameplay or polished asset production before the user accepts the technical and visual direction. Treat 600 as a *candidate* limit until data and user approval support it.

## File organization (adapt to existing code, do not rewrite unnecessarily)
- `scenes/` — levels, entities, menus, test scenes
- `scripts/simulation/` — core agent data and update systems
- `scripts/ai/` — group and individual behavior
- `scripts/navigation/` — shared routing and spatial lookup
- `scripts/rendering/` — independent 2D diagnostic and 3D isometric visual adapters
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
