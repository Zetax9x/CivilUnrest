# Personaggi 3D modulari — 2026-11-12

Prototipo originale realistico-stilizzato compatibile con Godot 4.7.2 Standard. Ingresso indipendente: `res://scenes/art_tests/CharacterShowcase.tscn` (F6 oppure avvio MCP esplicito). Main, ItalianStreet e core 2D non sono stati modificati.

## Contenuto e comandi

Tre archetipi: civile (maglie/giacche, pantaloni e carnagioni variabili), manifestante (giacca, zaino, cinghie e accessori variabili), polizia (uniforme blu, casco, visiera, gilet, cintura, radio e scudo opzionali). Accessori esclusivamente visivi, nessuna fazione o logica di scontro. Proporzioni intorno a 1,74 m, scala delle varianti 0,96–1,04; palette urbana desaturata, luce diurna coperta coerente con ItalianStreet. Geometrie e pose procedurali originali, nessun download.

Lo showcase dispone 20 personaggi su quattro file e cinque colonne: Idle, Walk, Run, Turn, Stop. Ogni colonna dimostra un comportamento; le transizioni sono temporali, quindi non tutte le colonne rimangono nello stato indicato per tutta la prova. Percorsi isolati e limitati, privi di collisioni di gameplay: non costituiscono una nuova simulazione della folla.
- `1` / `2`: 10 / 20 personaggi; il campione da 10 occupa slot alternati e contiene tutti e tre gli archetipi.
- `SPAZIO`: sospende/riprende lo stato dimostrativo; `R`: ripristina.
- WASD, rotellina, Q/E (90°), HOME: telecamera ortografica ereditata, con limiti configurabili.

## Moduli e contratto di integrazione

| File | Responsabilità |
|---|---|
| `scripts/characters/character_catalog.gd` | Parti, colori, archetipi e accessori; associazioni rigide alle articolazioni e visibilità per LOD. |
| `character_pose_library.gd` nella stessa directory | Banca condivisa per renderer di 5 × 32 pose con 14 trasformazioni ciascuna; campionamento interpolato. |
| `character_visual_state.gd` | Array visivi compatti: posizione, orientamento, velocità effettiva, stato, fase e dissolvenza. |
| `character_simulation_adapter.gd` | Lettura di CrowdState e riuso di crowd_3d_adapter; nessuna scrittura nel core. |
| `character_renderer.gd` | Tre MultiMesh per forma, mesh/materiale condivisi, cache delle pose e selezione LOD. |
| `scripts/art_tests/character_stage.gd` | Pedane, etichette e materiali riutilizzati dal prototipo artistico. |
| `character_camera.gd` / `character_showcase.gd` nella directory art_tests | Telecamera indipendente e sola regia dimostrativa/diagnostica. |

Integrazione futura, senza modifiche alla simulazione:
1. Creare un solo renderer per gruppo e chiamare `configure(types: PackedInt32Array, styles: PackedInt32Array)`; ordine e quantità devono coincidere con CrowdState.
2. Chiamare `present_simulation(data, alpha, delta, tick_delta, camera)` dal controller di presentazione. `alpha` interpola previous_positions/positions; tick_delta è il passo fisso del core.
3. L'adattatore conserva la conversione esistente (0,05 m/unità, piano X/Z e quote del terreno). Ricava la velocità visiva dallo spostamento realmente risolto fra tick: un agente bloccato non cammina sul posto solo perché lo steering richiede moto.
4. Per sorgenti diverse dal core, inviare i dati a `renderer.visual.submit(index, point, velocity, desired_heading, delta)`, poi chiamare `present(delta,camera)`. Nessun nodo fisico, Skeleton3D, AnimationTree o callback individuale per personaggio.

Idle include respirazione minima; Walk/Run hanno falcate distinte, braccia contrapposte e appoggio dei piedi con cinematica analitica a due segmenti. Turn limita la velocità angolare e muove leggermente gli arti; Stop dura 0,38 s, quindi ritorna Idle. Dissolvenza fra stati 0,16 s; fase della falcata legata alla distanza e soglia Run 2,1 m/s. La normalizzazione dello yaw evita salti al confine ±PI.

Per aggiungere gesti/interazioni estendere stati, generazione della banca e selezione nel solo livello visivo; eventuali eventi provenienti dal gameplay devono restare input di presentazione. Per sostituire i modelli mantenere questo contratto e rimpiazzare catalogo/renderer; gli indici delle 14 articolazioni sono interni al prototipo, non un formato universale di rig.

## LOD e costi residui

LOD ortografico basato sull'altezza proiettata di un umano di 1,78 m: vicino almeno 42 px, medio almeno 22 px, lontano sotto 22 px. Riduce segmenti delle forme e parti fini (viso, cinghie, tasche); uniformi, casco e zaino rimangono leggibili. Con 20 personaggi: 547 / 412 / 295 parti. Le pose sono ricampionate a 60 / 30 / 10 Hz; radice e trasformazioni delle parti vengono comunque inviate ogni frame per mantenere il movimento fluido.

Controllo MCP dei contatori, dopo la correzione del timer al limite di precisione float: **59,93 / 30,16 / 9,88 aggiornamenti di posa per personaggio al secondo**. Zoom runtime size 26 / 40 / 70 seleziona automaticamente LOD 0 / 1 / 2. I tre MultiMesh non crescono come numero di nodi con la popolazione.

Il LOD è comune al gruppo perché la telecamera è ortografica: la sola distanza non cambia la dimensione proiettata. Non è ancora un sistema per telecamere prospettiche, streaming o culling spaziale a blocchi. Cache e buffer sono riusati durante il funzionamento; cambio popolazione/LOD ricostruisce le associazioni. Il caricamento iniziale e questi cambi allocano memoria. L'invio CPU di ogni parte e le ombre rimangono costi da misurare prima di aumentare molto la popolazione.

## Verifiche effettive

- Script validati tramite Godot MCP; importazione editor headless finale exit 0.
- `Godot_v4.7.2-stable_win64_console.exe --headless --path . --script res://tests/presentation/character_checks.gd --log-file docs/screenshots/characters/logic_checks.log`: **6.314 controlli, zero errori**. Cataloghi, trasformazioni finite, giunti/piedi, falcate distinte e appoggio, sequenza Idle/Walk/Run/Stop/Idle/Turn/Idle, limite angolare, replay deterministico visivo, adattatore/interpolazione, input core invariati e risorsa scena caricabile. Scarto massimo fra giunto della caviglia e piede interpolati: 1,618 mm.
- Showcase caricato ed eseguito via MCP, run finale `0dcbc600`. Osservati tutti i cinque stati (4 personaggi per stato nella lettura a circa 1,7 s), cambiamenti reali delle trasformazioni MultiMesh degli arti e delle posizioni Walk/Run.
- Stop osservato dal vivo e successivo Idle nella stessa posizione; pausa con elapsed identico in due letture. Zoom tramite rotellina, LOD automatici e forzati verificati.
- Screenshot reali 1152×648, aperti e analizzati: [standard](screenshots/characters/standard.png), [ravvicinato](screenshots/characters/closeup.png), [fotogramma successivo](screenshots/characters/animation_next.png). Il confronto mostra cambio di appoggio e avanzamento; abiti, caschi, gilet e zaini distinguono gli archetipi. La cattura può perturbare temporaneamente FPS/HUD fuori dalla finestra del benchmark.
- **Zero errori e warning runtime**, processo arrestato. Conservazione SHA-256 dei 250 file protetti preesistenti, inclusi ItalianStreet, Main, simulazione/benchmark/test, project.godot, istruzioni, skills e addon: [preservation.json](screenshots/characters/preservation.json). Non rieseguita l'intera suite 2D poiché nessun suo codice è cambiato.

## Prestazioni preliminari misurate

PC: Intel Core i3-1115G4 / Intel UHD, Windows 11. Godot 4.7.2 **debug process MCP**, Compatibility/OpenGL, 1152×648, MSAA 4×, limite 60 FPS, VSync disabilitato solo nel processo, camera size 26, LOD 0. Una prova per popolazione, 4 s di warm-up + 8,016 s / 481 frame; medesime pedane, luce e traiettorie dimostrative. Nessuna simulazione della folla nel carico misurato.

| Personaggi | FPS medi | Frame mediano | Frame p95 | Frame massimo | CPU renderer media* | Memoria statica finale | Memoria video |
|---:|---:|---:|---:|---:|---:|---:|---:|
| 10 | 60 | 16,666 ms | 17,004 ms | 17,207 ms | 0,529 ms | 87,95 MiB | 39,53 MiB |
| 20 | 60 | 16,666 ms | 16,683 ms | 16,811 ms | 1,019 ms | 88,18 MiB | 39,54 MiB |

*Cronometro interno attorno a present(), include warm-up più campione, esclude update_demo e non misura CPU della simulazione né GPU. Monitor MCP process_ms medio 3,844 / 2,963 ms: è una lettura più ampia e campionata, non equivalente al cronometro interno. A 10 unità compare un campione process_ms di 15,111 ms senza spike di frame oltre 33,332 ms; con una sola prova non è significativo il vantaggio apparente del p95 a 20 unità.

Intera scena: 29 nodi, zero orfani e 28 draw call in entrambi i campioni (non confondere tre batch dei personaggi con le draw call totali, che includono ombre, pedane e testi). Crescita della memoria statica di 0,04 MiB per finestra: campioni troppo brevi per certificare assenza di perdite. Dati originali e controlli runtime: [qa.json](screenshots/characters/qa.json).

## Limiti e seguito

Personaggi ancora procedurali a parti rigide: mani/volti/capi semplificati, nessuna deformazione della stoffa o animazione scheletrica. Appoggio calcolato su terreno piano; nelle inversioni brusche e dissolvenze può restare scivolamento visivo. Nessuna IK per scale/terreno irregolare. Etichette piccole nella vista standard, leggibili soprattutto con zoom.

Nessuna integrazione in Main/ItalianStreet e nessuna modifica alla separazione/determinismo del core. Compatibilità del nuovo adattatore verificata automaticamente; nessun nuovo benchmark combinato core + questi personaggi. **Non misurati 600/1.000 personaggi 3D né build release**, nessuna estrapolazione da questi due campioni. Prossimo passo: valutazione artistica dell'utente e, se richiesta, integrazione controllata del renderer con un carico reale della simulazione.
