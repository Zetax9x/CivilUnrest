# Progressi CivilUnrest

## Personaggi 3D modulari e showcase indipendente — 2026-11-12

- Nuova scena `scenes/art_tests/CharacterShowcase.tscn`: 10/20 personaggi originali, archetipi civile/manifestante/polizia, varianti cromatiche, giacche/zaini e casco/gilet/equipaggiamento visivo. Luce coperta e palette coerenti con ItalianStreet, telecamera ortografica con zoom e comandi esistenti; nessun gameplay.
- Moduli in `scripts/characters/`: catalogo, stato visivo, banca condivisa di pose procedurali Idle/Walk/Run/Turn/Stop, adattatore in sola lettura verso CrowdState e renderer con tre MultiMesh. Zero nodi o fisica per individuo. LOD 547/412/295 parti a 20 personaggi; aggiornamenti pose misurati 59,93/30,16/9,88 Hz, movimento della radice per frame.
- Verifiche eseguite: validazione MCP, import headless exit 0; **6.314 controlli automatici superati** (pose/appoggio, transizioni, orientamento, replay visivo deterministico, adattatore/input core invariati, caricamento risorsa). Avvio MCP, screenshot standard/ravvicinato e secondo frame analizzati, movimento degli arti/posizioni, Stop → Idle, pausa, zoom e LOD controllati dal vivo. Run finale `0dcbc600`: zero errori/warning, poi arrestato.
- Prestazioni preliminari **debug**, Intel i3-1115G4/UHD, Windows 11, Godot 4.7.2 Compatibility, 1152×648, MSAA 4×, limite 60/VSync off, LOD 0, 4 s warm-up + 8,016 s (481 frame), una prova per quantità: **10 personaggi: 60 FPS, p95 17,004 ms, CPU renderer 0,529 ms, statica 87,95 MiB; 20: 60 FPS, p95 16,683 ms, CPU renderer 1,019 ms, statica 88,18 MiB**. CPU renderer media sul warm-up più campione, non CPU core/GPU. Nessuna misura a 600/1.000 né release; nessuna estrapolazione.
- ItalianStreet, Main, scene test/benchmark e algoritmi 2D invariati: confronto SHA-256 dei 250 file protetti preesistenti. Nessun commit, download, dipendenza o modifica a project.godot/skills/MCP/globali. Suite benchmark 2D non ripetuta perché invariata.
- Dettagli, API di integrazione e limiti: [CHARACTERS.md](CHARACTERS.md). Screenshot reali e dati: [standard](screenshots/characters/standard.png), [ravvicinato](screenshots/characters/closeup.png), [movimento](screenshots/characters/animation_next.png), [qa.json](screenshots/characters/qa.json).
- Limiti: modelli a parti rigide, niente animazione della stoffa o IK del terreno; possibile scivolamento durante inversioni/blend. LOD comune adatto alla camera ortografica, invio delle parti ancora per frame. Showcase isolato, adattatore testato ma nessuna integrazione nella scena del gioco. Prossimo passo: valutazione artistica e benchmark combinato solo su richiesta.


## Prototipo artistico italiano indipendente — 2026-11-12

- Ingresso autonomo: `res://scenes/art_tests/ItalianStreet.tscn` (F6 o avvio esplicito MCP). Nessuna integrazione in Main o nella simulazione. Diorama in metri: palazzo di quattro piani con balconi, persiane, cornici, cornicione, tetto a due falde, grondaie, negozio e numero civico; strada, attraversamento pedonale, parcheggi, tombini, lampioni, cestini, dissuasori, fioriere e alberi; automobile civile, mezzo della polizia e riferimento umano statico alto circa 1,78 m.
- Moduli in `scripts/art_tests/`: composizione/presentazione, generatore MultiMesh, edificio, strada, veicolo, riferimento umano e adattamento della telecamera esistente. Mesh condivise per forma e istanze raggruppate per materiale; nessuna fisica o elaborazione individuale della folla. Ventiquattro materiali riutilizzabili e uno shader originale con variazione superficiale/consumo in `assets/art_direction/materials/`; nessun asset esterno scaricato o copiato.
- Direzione proposta: intonaco desaturato, pietra chiara, ferro scuro, persiane verdi, asfalto e terracotta, illuminazione fredda diurna e ambiente coperto. Ortografica a yaw 45°/pitch −45°, dimensione iniziale 40; WASD, rotellina, Q/E e HOME ereditati senza modificare la telecamera del gioco. MSAA 4×, limite 60 FPS e VSync disabilitato soltanto nel processo/viewport del prototipo.
- Verifiche effettive: validazione GDScript MCP e importazione editor headless (exit 0); avvio grafico MCP del prototipo, ispezione diretta di tre screenshot, zoom tramite rotellina, movimento W, rotazione E (45° → 135°) e ripristino HOME. Corretti scala locale dei moduli ruotati, allineamento delle tende del negozio, tetto e inquadratura iniziale. L'importazione ha registrato gli UID dei nuovi script; esecuzione finale `4c6002dc` senza errori o warning runtime, poi arrestata.
- Prestazioni diagnostiche, scena statica con un solo umano, **debug process**, Godot 4.7.2, GL Compatibility, Intel UHD / i3-1115G4, Windows 11, 1152×648, MSAA 4×, limite 60 e VSync off: vista standard, attesa 4 s prima del campione, **601 frame / 10,016 s, 60 FPS medi, frame medio 16,666 ms, mediano 16,667 ms, p95 16,719 ms, massimo 16,925 ms**. Process monitor medio 1,764 ms (non misura GPU), memoria statica finale 88,67 MiB e video 35,42 MiB, 132 draw call, 80 nodi, zero nodi orfani. Nessuna conclusione su release o folle 3D di 1.000 agenti.
- Screenshot reali PNG 1152×648, aperti e verificati: [standard](screenshots/art_direction/italian_street_standard.png), [ravvicinato](screenshots/art_direction/italian_street_closeup.png), [riferimento umano](screenshots/art_direction/italian_street_human.png). Misure MCP, limiti, hash e verifica PNG in [qa.json](screenshots/art_direction/qa.json).
- Conservazione: SHA-256 identici per tutti i 165 file protetti preesistenti, inclusi Main, scene urbane/benchmark/MCP, script della simulazione, `project.godot`, istruzioni, skills e addon. Non rieseguita la suite benchmark: nessun suo codice è cambiato. Nessun commit, installazione o modifica globale/MCP.
- Limiti: umano statico senza rig/animazioni, vegetazione e veicoli ancora semplificati, vetri opachi stilizzati senza interni; nessun LOD. Il renderer Compatibility consente qui un'approssimazione filtrata delle ombre, senza PCSS/GI di Forward+. La qualità artistica definitiva richiede ancora valutazione dell'utente; prossimo passo: valutare questi tre riferimenti prima di integrare o produrre asset animati.

## Prima vertical slice 3D isometrica — 2026-11-12

- `Main.tscn` rimane l'ingresso del progetto e istanzia `scenes/urban/UrbanSquare.tscn` sotto `WorldHost`. Il precedente messaggio provvisorio è nascosto. Scene MCP e benchmark restano indipendenti.
- Piazza originale con tre edifici, asfalto/marciapiedi, segnaletica, lampioni, alberi/panchine, tre auto civili e un mezzo della polizia; geometrie procedurali e materiali semplici, nessun asset scaricato.
- Core 2D invariato: sessione a 30 Hz, adattatore X/Y → X/Z, renderer separato in cinque MultiMesh e telecamera indipendente. 50/100 segnaposto, senza fisica o aggiornamenti individuali. WASD, rotellina, Q/E a 90°, HOME, limiti configurabili; 1/2 cambia popolazione, SPAZIO mette in pausa.
- Parsing/caricamento headless: exit 0. Test grafico `tests/presentation/vertical_slice_checks.gd`: 49 controlli superati, inclusa uguaglianza deterministica con il core per 120 tick a 50/100 persone. Verificati dal vivo avvio Main tramite MCP, screenshot, movimento, tutti i comandi camera, limiti e pausa/ripresa. Corretto il getter diagnostico della slice affinché pubblichi snapshot senza ricostruire la griglia durante le letture MCP.
- Misure MCP debug, 1152×648, limite 60 FPS, VSync off, MSAA 2×, seed 20261112, warm-up 4 s + campione 8,016 s: **50 persone: 60 FPS medi, frame medio 16,666 ms, p95 16,718 ms; 100 persone: 60 FPS medi, frame medio 16,666 ms, p95 16,697 ms**. Una prova per popolazione; nessuna certificazione release/1.000 personaggi 3D.
- Scene originali rieseguite separatamente: MCP, 20 agenti, pausa/ripresa funzionante; benchmark 2D, 1.000 agenti congestionati, tick 36 → 361, zero sovrapposizioni oltre soglia/posizioni invalide/bloccati nelle letture. Zero errori/warning nelle prove finali; non è stata ripetuta l'intera suite benchmark 2D.
- SHA-256 invariati per 195 file protetti, inclusi algoritmi, test/benchmark, `project.godot`, AGENTS/CLAUDE, skills e addon. Nessun commit, plugin, dipendenza o modifica globale.
- Limiti: personaggi senza animazione articolata, LOD e occlusione tattica ancora assenti; uso del dominio disperso esistente, nessuna nuova navigazione urbana. I trasform MultiMesh richiedono il test grafico: i tentativi headless con backend Dummy non li verificano.
- Dettagli architetturali, comandi, screenshot, risultati originali e problemi risolti: [VISUAL_SLICE.md](VISUAL_SLICE.md). Prossimo passo: scenario urbano navigabile e gestione della leggibilità prima del gameplay.

## Separazione degli ingressi del progetto — 2026-11-12

- **Scena principale:** `res://scenes/main/Main.tscn`, impostata in `application/run/main_scene`. Contiene soltanto `Main` (Node), `WorldHost` (Node vuoto) e `PlaceholderUI/Status` (messaggio provvisorio). Nessuno script, autoload, caricamento del test o del benchmark.
- **Integrazione futura:** istanziare la futura scena urbana sotto `Main/WorldHost`; simulazione, adattatore visivo e telecamera resteranno moduli separati. In questa modifica non sono stati creati contenuti 3D o gameplay.
- **Struttura conservata:** `tests/mcp/MCP_Test.tscn` con tutti i file originali; `scenes/benchmarks/CrowdBenchmark.tscn`; test automatici in `tests/crowd/`; moduli esistenti in `scripts/simulation/`, `scripts/navigation/`, `scripts/rendering/` e `scripts/benchmarks/`. Nessuno spostamento, duplicazione o modifica degli algoritmi. Unica nuova directory: `scenes/main/`; nessuna cartella vuota per asset o script futuri.
- **Main tramite MCP:** avvio esplicito con `godot_run_start(mode="process", scene="res://scenes/main/Main.tscn")`, run `34b47b07`; albero runtime con i soli quattro nodi attesi, zero errori/warning.
- **Avvio progetto / F5:** verificato tramite `godot_run_start(mode="editor", scene="main")`, che nel backend chiama `EditorInterface.play_main_scene()`. Avvia Main anche con la scheda CrowdBenchmark selezionata; albero runtime confermato e zero errori/warning. Non è stata simulata la pressione fisica del tasto F5 né verificata una sua eventuale rimappatura locale.
- **Test MCP originale:** avvio separato, run `4109ce24`, 20 agenti e posizioni finite; SPAZIO mette in pausa (posizioni e tick identici in due letture al tick 245), poi riprende (tick 264 e posizioni cambiate). Zero errori/warning.
- **Benchmark 2D:** avvio separato, run `71f9efc4`, 1.000 agenti nello scenario `chokepoint`; tick 512 → 552, transiti unici 466 → 500; sovrapposizioni, posizioni invalide e agenti bloccati pari a zero nelle due letture. Zero errori/warning. È un controllo funzionale: non è stata ripetuta la suite prestazionale e questi campioni non sostituiscono `docs/BENCHMARK.md`.
- **Parsing/caricamento:** Godot 4.7.2, `--headless --path . --scene res://scenes/main/Main.tscn --quit-after 3`, exit code 0 e nessun errore. Le altre due scene sono state caricate ed eseguite dal vivo nei controlli sopra.
- **Conservazione:** confronto SHA-256 prima/dopo, identici tutti i 193 file presenti in `tests/mcp/`, `tests/crowd/`, `scripts/`, `scenes/benchmarks/`, `.agents/skills/`, `.claude/skills/` e `addons/`. Tutte le esecuzioni avviate sono state arrestate. Nessun commit creato.
- **Prossimo passo:** progettare la scena urbana solo su richiesta; mantenere test e benchmark avviabili singolarmente tramite il rispettivo percorso o F6.

## Portata nei passaggi stretti — 2026-11-12

- **Completato nel protocollo di riferimento:** a 1.000 agenti/tick 360, 27 eventi iniziali (26 ID) → 328 ID distinti; bloccati 669 → 0, overlap oltre 0.1 e posizioni invalide 0. Di questi, 316 hanno già superato interamente il varco.
- **Causa misurata:** fronti opposti convergenti prima dell'allineamento e interferenza fra ingresso/uscita; il blocco si propaga nelle code anche quando lo steering richiede ancora moto in avanti. Non è una cancellazione generale della spinta o un'apertura troppo piccola.
- **Modifica:** corsie ordinate precalcolate, allineamento con breve cessione di spazio verso l'esterno e separazione dei versi in uscita. Dati, griglia, solver, 30 Hz e rendering restano separati; niente nuovo sistema di AI/gameplay.
- **Collisioni:** nessun controllo disattivato. Diametro 10 invariato; margine conservativo sweep aumentato a 10.2 fra centri per proteggere l'interpolazione. Spawn/muri/seed invariati, verificati tramite hash e oracoli; velocità e spostamenti limitati.
- **Prestazioni debug standalone:** suite prima/dopo 100/300/500/600/800/1.000, entrambi gli scenari, seed 20261112, 4+8 s, 1152×648, limite 60, VSync off. Congestionato 1.000: CPU 13.01735 → 10.5873375 ms/tick; p95 32.062 → 29.066 ms; FPS medi 60.0023177610478 → 60.00212315205. Nessuna certificazione di 60 FPS stabili/release.
- **Regressioni PASS:** parsing MCP dei file modificati; controlli preesistenti griglia/movimento/contatti; repliche deterministiche per sei quantità; sweep continui agenti/muri, limite di spostamento e contatori verificati con osservatore indipendente. Fronti compatti opposti: 194 ID (86/108), zero bloccati finali, stessa apertura.
- **Durata:** 900 tick deterministici, 735 ID, zero bloccati finali. Prova grafica tardiva 22+8 s: CPU 7.58119166666667 ms/tick, p95 25.822 ms; conferma la prosecuzione della portata.
- **MCP dal vivo:** screenshot a 360 tick analizzato, pausa stabile e ripresa verificate, zero errori/warning, processo fermato. Test MCP originale indipendente e invariato.
- **Limiti:** micro-oscillazioni residue e arretramenti intenzionali durante la formazione; 98/100 anziché 100/100 transitano entro il termine nello scenario meno denso. Disperso a 1.000: CPU 5.53775 → 6.58737083333333 ms, p95 23.569 → 24.489; costo peggiorato, causa non isolata da una sola coppia di catture. Nessun beneficio generale dichiarato.
- **File:** `scripts/simulation/{benchmark_scenario,crowd_movement,crowd_simulation,crowd_state}.gd`, `scripts/benchmarks/crowd_benchmark.gd`, `tests/crowd/{flow_checks,flow_diagnosis,contact_checks}.gd`, questo documento, [BENCHMARK.md](BENCHMARK.md) e relative evidenze. 27 file protetti verificati identici, comprese istruzioni/skills, project.godot e test MCP; nessuna installazione o commit.
- **Prossimo passo:** ridurre il jitter dello steering e verificare il costo disperso con repliche comparate; nessun avvio del gameplay incluso in questa milestone.



## Ottimizzazione CPU e contatti — 2026-11-12

- Ottimizzati i moduli esistenti: celle occupate e coppie riutilizzate, buffer CSR, sweep continui tra agenti e ostacoli, scorrimento tangenziale, recupero dei contatti iniziali e blocco/rilascio deterministico. Nessuna riscrittura del renderer o delle scene.
- Confronto debug controllato completo 100/300/500/1.000, disperso e congestionato: seed 20261112, 1152×648, limite 60 FPS, VSync off, warm-up 4 s + misura wall-clock 8 s. Aggiunti 600/800 secondo AGENTS.md aggiornato esternamente.
- 1.000 congestionati: CPU 19.1576416666667 → 13.1535958333333 ms/tick; p95 frame 38.157 → 32.19 ms; FPS 59.7695291945451 → 60.0015617870137. Memoria media 64.5221956888835 → 65.2930192947388 MiB. Dati completi e limiti in BENCHMARK.md.
- Sovrapposizioni oltre 0,1: 336 → 0 al tick 360. Test automatici nuovi: alta densità, passaggio stretto, flussi opposti (anche traiettorie interpolate), blocco temporaneo e ripresa. Oracolo esaustivo, repliche identiche e coordinate valide; runner finali exit 0. Soglia delle regressioni originali stretta da 5 a 0,1.
- **Congestione non risolta:** 27 transiti contro 509 a tick 360; 669 bloccati nel benchmark, picco 676 nei test da 240 tick. La soluzione mantiene i corpi separati ma riduce fortemente la portata: non è un successo completo di comportamento.
- **60 FPS stabili non raggiunti:** p95 32.19 ms; CPU del movimento/sweep 6.28165 ms/tick, coppie 2.7151875. Rendering 0.308544698544699 ms/frame. I tempi cumulativi del profiler MCP dopo sono incoerenti e sono esclusi; usati span interni senza profiler.
- Export Windows release tentato, exit 1: manca export_presets.cfg; cartella template vuota. Nessuna installazione o configurazione creata. Release e prestazioni 3D non verificate.
- Controllo MCP live, screenshot analizzato: separazione visibile, coda bloccata, zero errori/warning; run arrestato. Nessun benchmark headless concorrente alle acquisizioni grafiche.
- Test MCP originale, project.godot, CLAUDE.md e skills invariati per hash. AGENTS.md cambiato da un'altra attività durante la sessione, preservato. Nessun commit o cambiamento globale/MCP.
- Prossimo passo: misurare portata e attesa, affrontare il blocco collettivo con instradamento/coordinamento riproducibili, poi ridurre il costo dei controlli swept; rieseguire gli stessi test senza tollerare compenetrazioni. Limite gameplay 600 non deciso; nessun lavoro 3D iniziato.


## Prima milestone tecnica: Crowd Benchmark — 2026-11-12

- Implementata la scena isolata `scenes/benchmarks/CrowdBenchmark.tscn` per 100/300/500/1.000 agenti, con scenari disperso e passaggio stretto, seed riproducibile 20261112, camera e HUD.
- Separati stato compatto, griglia spaziale, movimento/separazione, orchestrazione a 30 Hz e rendering interpolato. Sei nodi nella scena, nessun nodo o elaborazione individuale per agente. Stato controllato dai sistemi, buffer riutilizzabili e coppie locali univoche filtrate per distanza.
- Regressioni headless passate per le otto combinazioni: due esecuzioni identiche da 300 tick, popolazione, determinismo, movimento, coordinate finite, confini/ostacoli, attraversamento e ricerca spaziale. Corretto il contatto eccessivo: massimo campionato da 7,31 a 4,44 unità; tolleranza dichiarata 5, contatti morbidi.
- Parsing CLI e validazioni MCP passati. Controllo mirato aggiuntivo: la diagnostica ripetuta preserva stato e contatori.
- Eseguite tre suite grafiche tramite MCP, senza test headless concorrenti: baseline, tentativo intermedio più lento e versione finale filtrata. Documentati anche i risultati negativi.
- Finale con 1.000 agenti: disperso 69,03 FPS, CPU 10,71 ms/tick, frame p95 28,87 ms; passaggio stretto 53,90 FPS, CPU 22,83 ms/tick, frame p95 40,91 ms. Simulazione circa 30 Hz. CPU ridotta rispetto alla baseline del 37%/34% circa.
- Prova grafica CLI prolungata da circa 30 s a 1.000 agenti, limite 60 FPS: 59,77 FPS medi, p95 frame 32,75 ms, CPU 11,85 ms/tick, 30,003 Hz; memoria statica +0,068 MiB. Non confrontabile direttamente con il breve picco di congestione o con la memoria del bridge MCP.
- **60 FPS stabili non raggiunti/verificati**. Nessuna build Windows release esportata, nessuna prova di stabilità della memoria su lunghe sessioni. Il renderer MultiMesh opzionale non è stato benchmarkato.
- Input live verificati: pausa al tick 105, ripresa fino a 137, cambio scenario/popolazione e pan/zoom. Screenshot finale acquisito e analizzato; zero errori/warning runtime, tutti i run di lavoro arrestati.
- Metodologia, hardware, tabelle, limiti e comandi riproducibili in `docs/BENCHMARK.md`; campioni grezzi, screenshot e log in `docs/benchmark_results/` e `tests/crowd/`.
- Test MCP originale preservato: hash dei suoi 14 file invariati. Nessuna modifica diretta a `project.godot`; rilevata durante il lavoro un'assegnazione sopraggiunta della scena principale al test MCP originale, lasciata intatta. Nuova scena avviata sempre esplicitamente.
- Nessun gameplay, combattimento, asset definitivo, plugin/dipendenza installata, modifica globale/MCP o commit.
- Prossimo passo tecnico: ridurre i costi di griglia/coppie e contatti nella congestione, ripetendo le regressioni; preparare un export release solo con template e preset disponibili.


## Test operativo Godot MCP — 2026-11-12

- Creata con MCP la scena isolata `tests/mcp/MCP_Test.tscn`: 20 cerchi colorati, movimento autonomo, separazione locale tramite griglia, sfondo scuro, FPS e pausa/ripresa con Spazio. Stato in array separato dal disegno; Timer a 30 Hz, nessun nodo per agente.
- Godot `4.7.2.stable.official.ed1daf0bf`, renderer GL Compatibility, Intel UHD Graphics; runtime MCP `a2f9dc64`, viewport 1152 x 648.
- Validazione script MCP e parsing CLI riusciti. `mcp_test_checks.gd` verifica 900 tick deterministici, 20 agenti, movimento, coordinate finite, confini, separazione e una coppia coincidente; uscita 0.
- Test live MCP: movimento osservato; Spazio arresta la simulazione al tick 818, posizioni identiche dopo almeno 1 secondo mentre il rendering continua; secondo Spazio riprende il movimento, tick 849. Due toggle verificati tramite input reale del bridge, senza eval o pausa del debugger.
- Screenshot del gioco acquisiti e ispezionati: `tests/mcp/evidence/moving.png`, `paused.png`, `resumed.png`. HUD leggibile e agenti visibili. Evidenze numeriche e log in `tests/mcp/evidence/results.json`.
- Nessun errore o warning nel runtime. Scena arrestata tramite MCP. FPS diagnostici osservati: 60; non costituiscono un benchmark release o una prova su 1.000 agenti.
- Nessuna modifica a `project.godot` o alla scena principale; nessun plugin o framework installato, nessun commit.
- Limiti: non verificati prestazioni a 1.000 agenti e build Windows esportata, estranee a questo test operativo. Nessun blocco operativo rilevato.
- Prossimo passo: mantenere questa scena come smoke test riproducibile; sviluppo del Crowd Benchmark solo su richiesta.
