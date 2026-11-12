# Progressi CivilUnrest

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
