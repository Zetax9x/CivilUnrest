# Crowd Benchmark — CivilUnrest

## Benchmark integrato 3D — 2026-11-12

Completata la matrice debug 20/100/300/600/800 personaggi animati, dispersi e congestionati, nella scena indipendente `scenes/benchmarks/UrbanCrowd3D.tscn`. Metodologia, CPU simulazione/renderer, frame time, memoria, contatti, screenshot e limiti sono in [URBAN_CROWD_3D.md](URBAN_CROWD_3D.md). A 800 congestionati: **32,47 FPS medi, p95 52,97 ms**, simulazione circa 30 Hz, nessuna sovrapposizione oltre soglia nelle letture. Nessuna certificazione di 60 FPS stabili o release. Il benchmark 2D originale è stato rieseguito separatamente a 1.000 nei due scenari ed è rimasto funzionante; i risultati storici sotto sono conservati.

## Portata nei passaggi stretti — 2026-11-12

Il blocco collettivo del caso di riferimento è risolto nel protocollo misurato: al tick 360 passano **328 agenti distinti**, contro 26 agenti/27 eventi iniziali; gli immobili scendono da 669 a **0**. Al tick 900 passano 735 agenti distinti e gli immobili restano 0. Non è una certificazione di 60 FPS stabili: il frame p95 finale a 1.000 agenti è 29.066 ms in debug standalone.

### Diagnosi prima della modifica

- Nel caso originale, al tick 360, 514/669 immobili richiedono ancora una velocità superiore a 50 unità/s. La spinta richiesta media verso il goal è 49.8311772285021 unità/s, mentre lo spostamento reale medio è 0.00186779790639098 unità/s. Solo 15/669 hanno proiezione richiesta sul goal non positiva; 667/669 sono immediatamente ostacolati anche provando il solo movimento verso il goal.
- I contatti dei bloccati includono 956 coppie nello stesso verso e 34 contrapposte: il conflitto delle due fronti si propaga nelle code. Inizializzare tutti verso est porta a 422 eventi al tick 360 contro 27; questo è un controllo diagnostico, non un benchmark equivalente. Alcuni agenti possono invertire direzione al bordo anche in questo controllo.
- Il contatore storico resta invariato: almeno 30 tick consecutivi con spostamento al quadrato < 0.001111 per tick, circa meno di 1 unità/s. Misura immobilità, non assenza di progresso verso il goal; non esclude da solo oscillazioni. `state.velocities` contiene lo steering richiesto, non la velocità effettivamente eseguita.
- Muri invariati: Rect2(780,20,40,350) e Rect2(780,530,40,350). Apertura fisica 160, raggio 5, diametro 10, intervallo geometrico dei centri y=375..525. Non è un varco incompatibile con il diametro.
- I goal originali attirano le fronti verso portali oltre il muro prima di allinearle; gli agenti in uscita incontrano gli ingressi ancora trasversali. Inoltre le cinque destinazioni per ID sono distanti 9 unità, meno del diametro. L'ordine per ID mescola le file di partenza. Il problema è soprattutto di organizzazione degli accessi e dello steering, non una cancellazione generalizzata della spinta da parte della separazione.

Evidenza: [diagnosi originale](benchmark_results/flow_diagnosis_before.json). Il nuovo controllo continuo ha anche trovato distanze interpolate <9.9 nei casi originali 300–800, pur con endpoint senza sovrapposizioni oltre 0.1: [controlli prima](benchmark_results/flow_checks_before.json), esito FAIL conservato.

### Correzione mantenuta e controlli causali

La struttura dati/sistemi, la griglia, il solver di separazione e il fixed step a 30 Hz restano gli stessi. Cambiano lo steering del fixture congestionato e la misura dei transiti:

1. Le righe contigue dello spawn ricevono cinque corsie ordinate, precalcolate una volta in un PackedFloat32Array; passo 10.5. Est: y=390..432, ovest: y=470..512.
2. Fuori dalla banda di ingresso (est 380..440, ovest 460..520), il waypoint è 20 unità verso l'esterno e alla quota della corsia. Gli agenti cedono spazio all'uscita mentre si allineano; poi attraversano mantenendo separati i versi fino alla destinazione. Il piccolo arretramento è intenzionale e sottoposto agli stessi sweep. Non si modificano spawn, muri, raggio, velocità massima 65 o seed.
3. Lo sweep usa una distanza conservativa di 10.2 fra centri, al posto di sqrt(100.02). È un **aumento dichiarato del margine di anticipazione della collisione**, non una riduzione dei corpi: protegge anche l'interpolazione fra tick. Restano attivi collisioni agenti/muri e recupero delle compenetrazioni, senza allentare la tolleranza 0.1.
4. Eventi, ID transitati e versi sono contati separatamente con buffer riutilizzabili. I transiti ripetuti non aumentano il conteggio degli agenti distinti.

Il solo nuovo margine, con i vecchi goal, produce 22 ID transitati e 681 bloccati: [ablazione](benchmark_results/flow_ablation_clearance_only.json). Il guadagno non deriva dal margine o da collisioni ignorate. La spinta laterale isolata non migliora il caso originale; avanzare durante l'allineamento migliora lo spawn normale ma lascia bloccati i fronti compatti. Allinearsi sul posto, limitare la repulsione o aggiungere detour campionati non supera il test compatto; i detour aumentano anche il costo. Queste varianti sono scartate, senza nuovo stato di deadlock o manovre casuali nella versione finale.

### Metodo prima/dopo e portata

Due suite grafiche complete, una prima delle modifiche alla simulazione e una dopo: seed 20261112, 100/300/500/600/800/1.000 agenti, entrambi gli scenari, 4 s warmup + 8 s campionamento, 1152×648, limite 60 FPS, VSync disattivo, renderer Compatibility e draw_texture_rect. Godot 4.7.2.stable.official.ed1daf0bf, debug standalone, i3-1115G4, Intel UHD, Windows 10.0.26300. Nessun altro test di simulazione gira durante le catture prestazionali. Una sola esecuzione per cella: differenze piccole possono risentire di scheduling/frequenza del portatile; non sono intervalli di confidenza.

I valori di riferimento CPU 13.15/p95 32.19 vengono dalla prova precedente. Il confronto corrente riproduce il blocco e usa la nuova cattura prima: CPU 13.01735/p95 32.062, non quei tempi storici. La terminazione è a tempo reale: il caso disperso prima/300 chiude a 361 tick anziché 360; tutte le sei prove congestionate chiudono a 360 prima e dopo.

| Agenti | Eventi prima | ID prima | ID dopo (est/ovest) | Bloccati prima → dopo | Interamente oltre il varco dopo |
|---|---:|---:|---:|---:|---:|
| 100 | 100 | 100 | 98 (49/49) | 0 → 0 | 97 |
| 300 | 129 | 126 | 199 (101/98) | 10 → 0 | 192 |
| 500 | 57 | 57 | 253 (125/128) | 271 → 0 | 244 |
| 600 | 50 | 48 | 273 (136/137) | 345 → 0 | 264 |
| 800 | 39 | 39 | 304 (152/152) | 512 → 0 | 293 |
| 1000 | 27 | 26 | 328 (165/163) | 669 → 0 | 316 |

Tutti i conteggi della tabella sono al tick 360. La linea storica è x=800; l'ultima colonna conta chi ha già superato anche x=825 verso est o x=775 verso ovest. Nel finale congestionato eventi=ID, nessun transito ripetuto. A 100 agenti passano 98 anziché 100 entro il termine: l'allineamento più prudente ha un costo di latenza, non nascosto.

### Prestazioni grafiche prima → dopo

Unità ms salvo FPS. Valori numerici conservati senza arrotondamento aggiuntivo; campioni completi, p99, massimi e tempi dei componenti nei JSON.

| Scenario | Agenti | CPU/tick media | Frame mediano | Frame p95 | FPS medi |
|---|---:|---:|---:|---:|---:|
| dispersed | 100 | 0.384454166666667 → 0.5098125 | 16.487 → 16.522 | 17.257 → 17.328 | 59.9084086371236 → 60.0018836350164 |
| dispersed | 300 | 1.15926556016598 → 1.52609583333333 | 15.796 → 15.57 | 18.171 → 18.474 | 60.002175546656 → 60.0019809385807 |
| dispersed | 500 | 2.104125 → 2.59545416666667 | 16.66 → 16.706 | 19.345 → 19.688 | 60.0020483027716 → 60.0018761501399 |
| dispersed | 600 | 2.58652916666667 → 3.37390833333333 | 16.668 → 16.672 | 19.833 → 20.674 | 60.0022054864719 → 60.0019285443145 |
| dispersed | 800 | 3.8348125 → 4.69411666666666 | 16.705 → 13.307 | 21.33 → 22.267 | 60.0021980015152 → 60.0021530918136 |
| dispersed | 1000 | 5.53775 → 6.58737083333333 | 12.45 → 16.669 | 23.569 → 24.489 | 60.0021081821794 → 60.0022429112839 |
| chokepoint | 100 | 0.546170833333333 → 0.607216666666667 | 16.675 → 16.232 | 17.404 → 17.485 | 60.0021306369881 → 60.0021306369881 |
| chokepoint | 300 | 2.64746666666667 → 2.151 | 14.861 → 16.644 | 20.059 → 19.288 | 60.0020183631125 → 60.0021006972469 |
| chokepoint | 500 | 5.27216666666666 → 4.10327083333334 | 12.888 → 13.958 | 23.34 → 21.689 | 60.0020632726123 → 60.00212315205 |
| chokepoint | 600 | 6.78793333333333 → 5.01032083333333 | 11.593 → 13.227 | 25.109 → 22.798 | 60.002175546656 → 60.0022653661935 |
| chokepoint | 800 | 9.88989999999999 → 7.56284166666667 | 16.748 → 16.817 | 28.827 → 25.317 | 60.0020707575355 → 60.0021980015152 |
| chokepoint | 1000 | 13.01735 → 10.5873375 | 16.509 → 16.666 | 32.062 → 29.066 | 60.0023177610478 → 60.00212315205 |

Sovrapposizioni oltre 0.1 e posizioni invalide finali: 0 in tutte le 12 celle finali; bloccati: 0 anche nelle sei celle disperse. Il caso disperso **non migliora**: a 1.000 CPU 5.53775 → 6.58737083333333 e p95 23.569 → 24.489. Il confronto non isola quanto dipenda dal maggiore margine rispetto alla variabilità del sistema; non si attribuisce un beneficio generale alla patch.

Nel caso congestionato a 1.000, tempi medi dei componenti prima → dopo:
- rebuild: 0.3766 → 0.41755 ms/tick.
- pairs: 2.71547916666667 → 2.3341375 ms/tick.
- avoidance: 1.885825 → 1.44546666666667 ms/tick.
- positions: 6.21801666666667 → 4.96445 ms/tick.
- Invio rendering/interpolazione: 0.310796257796258 → 0.314081081081081 ms/frame; non è il tempo GPU.

Il maggiore costo resta il movimento con sweep (4.96445 ms/tick), seguito dalle coppie spaziali (2.3341375). La minore congestione riduce i costi di coppie, repulsione e sweep senza cambiare l'algoritmo della griglia. Il tick a 30 Hz concentra ancora lavoro su alcuni frame: la media limitata a 60 non equivale a p95 <=16.666666666666668 ms. Nessuna nuova misura release; questi risultati non certificano una build esportata.

### Memoria

Allocazioni statiche Godot in MiB, **non** working set del processo. Prima/ultima misura della finestra di 8 s:

| Scenario | Agenti | Prima: inizio → fine | Dopo: inizio → fine |
|---|---:|---:|---:|
| dispersed | 100 | 64.2038288116455 → 64.2329158782959 | 64.2223739624023 → 64.2513236999512 |
| dispersed | 300 | 64.3939609527588 → 64.4225673675537 | 64.413610458374 → 64.4422168731689 |
| dispersed | 500 | 64.6249752044678 → 64.6534786224365 | 64.6455173492432 → 64.6740207672119 |
| dispersed | 600 | 64.878306388855 → 64.9068098068237 | 64.9002847671509 → 64.9287881851196 |
| dispersed | 800 | 65.2524900436401 → 65.2809934616089 | 65.2765007019043 → 65.305004119873 |
| dispersed | 1000 | 65.3234243392944 → 65.3519277572632 | 65.3476791381836 → 65.3761825561523 |
| chokepoint | 100 | 64.3892993927002 → 64.4179058074951 | 64.4091491699219 → 64.4376525878906 |
| chokepoint | 300 | 64.5787715911865 → 64.6073780059814 | 64.5995807647705 → 64.6281871795654 |
| chokepoint | 500 | 64.8093776702881 → 64.8378810882568 | 64.8313846588135 → 64.8599910736084 |
| chokepoint | 600 | 65.0627775192261 → 65.0912809371948 | 65.086220741272 → 65.1148271560669 |
| chokepoint | 800 | 65.436915397644 → 65.4654188156128 | 65.4623908996582 → 65.4909973144531 |
| chokepoint | 1000 | 65.5035467147827 → 65.5325155258179 | 65.5292663574219 → 65.5580520629883 |

I buffer aggiunti sono configurati al reset, non allocati per agente a ogni tick. Le piccole crescite nelle finestre includono la raccolta dei campioni: 8 s non dimostrano assenza di leak a lungo termine.

### Correttezza, flussi opposti e durata

- [Regressioni finali a sei numerosità](benchmark_results/flow_safety_final.json): repliche con posizioni e direzioni identiche a ogni tick; zero violazioni dei muri lungo i segmenti, zero overlap endpoint oltre 0.1; spostamento massimo complessivo 2.16673350334167 unità/tick, compatibile con 65/30 e floating point. Minimo fra corpi interpolati sull'insieme delle prove: 9.99185752868652, compenetrazione inferiore a 0.1. L'oracolo usa moto relativo continuo; le coppie conservative della griglia sono verificate anche dalle regressioni preesistenti e da oracoli esaustivi di contatto.
- [Confronto geometria/spawn](benchmark_results/flow_geometry_comparison.json): hash delle posizioni iniziali e rettangoli identici prima/dopo per tutte e sei le quantità; nessun teletrasporto o attraversamento dei muri. A 1.000 il minimo interpolato è 10.0063943862915, senza compenetrazione.
- [Fronti opposti compatti](benchmark_results/flow_opposing_final.json): 1.000 agenti, due reticoli separati a passo 10.5, stessa apertura, 360 tick, due repliche; 194 ID (86 est/108 ovest), 0 bloccati, 0 overlap oltre 0.1, minimo interpolato 9.98472499847412, zero violazioni dei muri. Mantiene la soglia automatica di almeno 50 ID per verso. Non si usa questa disposizione diversa nel confronto prestazionale prima/dopo.
- [Contatti](benchmark_results/flow_contact_checks.json) e `tests/crowd/flow_crowd_checks.log`: PASS per griglia, confini, popolazione, determinismo, alta densità, passaggio, versi opposti, agenti pinned e ripresa dopo rilascio. Nessuna assertion disabilitata. Il test contatti scrive un nuovo file senza sovrascrivere l'evidenza della milestone precedente.
- [Estensione deterministica a 900 tick](benchmark_results/flow_soak_final.json): 735 ID (371 est/364 ovest), 0 bloccati finali, zero overlap oltre 0.1, zero violazioni dei muri. Ci sono 45 eventi ripetuti esclusi dai 735 ID. I tempi del runner headless con repliche/oracoli non sostituiscono un benchmark grafico.
- [Finestra grafica tardiva](benchmark_results/flow_late_after.json), warmup 22 s + misura 8 s: 735 ID al tick 900, CPU media 7.58119166666667, frame mediano 10.719, p95 25.822, FPS 60.0020033932942; memoria statica 65.4670667648315 → 65.4955701828003 MiB. Conferma che la portata prosegue oltre i primi 12 s.
- [MCP dal vivo](benchmark_results/flow_mcp_runtime.json): screenshot analizzato [al tick 360](benchmark_results/flow_mcp_1000.png), 328 ID e zero bloccati/overlap; due letture in pausa restano al tick 360, dopo ripresa tick 391/356 ID; 0 errori e 0 warning, processo fermato. È verifica funzionale, separata dai tempi della suite controllata.

Restano **micro-oscillazioni di steering**: nel caso normale a 1.000 si registrano 20102 inversioni >120° fra spostamenti consecutivi significativi; un massimo di 1 agente percorre >1 unità e torna entro 0.25 dal punto iniziale in una finestra di 30 tick, 0 nell'ultima finestra. Nel fixture compatto le inversioni sono 35588 e il picco è 3 agenti oscillanti per finestra. Gli arretramenti prima della corsia sono intenzionali; non si dichiara il moto visivamente definitivo o privo di jitter. La classificazione di bloccato non è stata alleggerita per ottenere gli zeri.

### Riproduzione ed evidenze finali

```powershell
& 'C:\Tools\Godot\Godot_v4.7.2-stable_win64_console.exe' --path . --scene res://scenes/benchmarks/CrowdBenchmark.tscn --resolution 1152x648 --max-fps 60 --disable-vsync -- --suite --quit-on-complete --tag=flow_recheck --warmup=4 --duration=8
& 'C:\Tools\Godot\Godot_v4.7.2-stable_win64_console.exe' --headless --path . --script res://tests/crowd/flow_checks.gd -- --all --determinism --tag=flow_recheck_safety
& 'C:\Tools\Godot\Godot_v4.7.2-stable_win64_console.exe' --headless --path . --script res://tests/crowd/flow_checks.gd -- --opposing --determinism --tag=flow_recheck_opposed
```

Suite autorevoli: [prima](benchmark_results/flow_before.json), [dopo](benchmark_results/flow_after.json), `flow_safety_final.json`, `flow_opposing_final.json`, `flow_soak_final.json`, `flow_counters_final.json` e rispettivi log. La suite B ora include anche 600/800; `--count` seleziona una quantità. `flow_sources_before.json` conserva i sorgenti iniziali; `flow_sources_baseline.json` registra la sola estensione della lista a sei quantità già applicata prima della cattura iniziale; `flow_sources_after.json` e `flow_source_hashes_after.json` identificano i sorgenti finali. Il comando sopra riproduce i sorgenti correnti. `flow_probe_*`, `flow_opposing_after` e `flow_checks_yield_after` documentano tentativi preliminari, compresi fallimenti conservati, non l'esito finale.

Le impronte di 27 file protetti coincidono con l'inizio del lavoro: AGENTS/CLAUDE, project.godot, cinque skill in entrambe le copie e test MCP originale. Nessun MCP, configurazione globale, scena, dipendenza o commit modificato/creato da questo intervento. Modifiche limitate a quattro script simulazione/scenario, controller benchmark, runner di test e documentazione/evidenze. Il prossimo intervento utile è ridurre jitter e verificare il costo disperso con repliche prestazionali, prima di aggiungere gameplay.



## Ottimizzazione CPU e contatti — 2026-11-12

**60 FPS stabili non raggiunti. Export Windows release non disponibile.**
La simulazione 2D resta un diagnostico: questi risultati non validano grafica 3D, gameplay o un limite definitivo di popolazione.

Il confronto controllato a 1.000 agenti congestionati passa da CPU **19.1576416666667** a **13.1535958333333 ms/tick**, p95 frame da **38.157** a **32.19 ms**, FPS da **59.7695291945451** a **60.0015617870137**. Le sovrapposizioni oltre 0,1 unità passano da **336 a 0**. Tuttavia i transiti cumulativi al tick 360 scendono da **509 a 27** e risultano **669 agenti bloccati**: la congestione resta un problema funzionale. Nessuna riduzione della popolazione, disattivazione delle collisioni o attraversamento intenzionale dei corpi.

### Metodo e confronto

Stesso PC della prima milestone: Intel Core i3-1115G4 @ 3 GHz, 2 core/4 thread, Intel UHD, driver 30.0.100.9805, Windows 11 Home 10.0.26300, RAM visibile 8105456 KiB. Godot 4.7.2.stable.official.ed1daf0bf Standard, eseguibile editor eseguito come gioco standalone **debug**, rendering OpenGL Compatibility, draw_texture_rect, finestra/viewport 1152×648, mondo 1600×900, raggio 5, velocità 65, simulazione 30 Hz. Seed 20261112, limite FPS 60, VSync disabilitato da CLI, 4 s warm-up e almeno 8 s di acquisizione wall-clock per caso; scenari e spawn invariati.

Le due suite principali usano lo stesso recorder e la stessa strumentazione; nessun profiler script né test headless concorrente durante l'acquisizione. I timer di durata ora usano l'orologio monotono: durate reali, campioni e frequenza effettiva sono nei JSON. Il primo intervallo del recorder è parziale e resta incluso in entrambe le suite, spiegando anche FPS di poco superiori al limite. Una sola ripetizione per caso: non è una valutazione statistica su più sessioni.

Il vecchio risultato 53,90 FPS / 40,91 ms / 22,83 ms è conservato nello storico; aveva VSync attivo, nessun limite FPS esplicito e bridge MCP. Non è il riferimento diretto per attribuire il beneficio di questa modifica. Il riferimento equivalente è `optimization_before.json`.

### Risultati debug prima/dopo

Valori numerici riportati dalla raccolta; campioni integrali nei JSON, senza sostituirli con valori arrotondati. Frame p50/p95 e CPU in ms. Memoria = media delle allocazioni statiche Godot in MiB, non RSS del processo.

| Scenario | Agenti | FPS prima | FPS dopo | p50 prima | p50 dopo | p95 prima | p95 dopo | CPU prima | CPU dopo | Memoria prima | Memoria dopo |
| --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| dispersed | 100 | 60.0020258480245 | 60.0021680617067 | 16.164 | 16.699 | 17.689 | 17.297 | 0.825916666666667 | 0.417754166666666 | 64.0622620582581 | 64.2157881259918 |
| dispersed | 300 | 60.0024300360439 | 60.0016291502634 | 16.642 | 16.664 | 19.17 | 18.475 | 1.94520416666667 | 1.28092916666667 | 64.1393353939056 | 64.4059493541718 |
| dispersed | 500 | 60.0018611803925 | 60.0021530918136 | 16.69 | 14.969 | 20.996 | 19.378 | 3.3466125 | 2.153125 | 64.219343662262 | 64.636561870575 |
| dispersed | 1000 | 60.0017938166218 | 60.0023551859998 | 10.792 | 12.222 | 26.963 | 24.215 | 8.57009583333334 | 5.99069166666667 | 64.3792462348938 | 65.1724553108215 |
| chokepoint | 100 | 60.0021980015152 | 60.0023402160134 | 16.669 | 16.672 | 17.976 | 17.4 | 0.891479166666666 | 0.5613375 | 64.1861016750336 | 64.3408861160278 |
| chokepoint | 300 | 60.0020857273875 | 60.0021530918136 | 16.663 | 14.844 | 20.122 | 20.296 | 2.81334166666667 | 2.86490833333333 | 64.2625932693481 | 64.530396938324 |
| chokepoint | 500 | 60.0019809385807 | 60.0021830316072 | 16.509 | 12.791 | 23.94 | 24.521 | 6.171975 | 6.10308333333334 | 64.3426766395569 | 64.7610201835632 |
| chokepoint | 1000 | 59.7695291945451 | 60.0015617870137 | 16.245 | 16.139 | 38.157 | 32.19 | 19.1576416666667 | 13.1535958333333 | 64.5221956888835 | 65.2930192947388 |

### Dove si spende il tempo

Medie per tick nel caso congestionato da 1.000 agenti; il totale include anche orchestrazione e contatori.

| Componente | Prima, ms | Dopo, ms |
| --- | ---: | ---: |
| Ricostruzione griglia | 0.746920833333333 | 0.381158333333333 |
| Enumerazione/filtraggio coppie vicine | 6.48107916666667 | 2.7151875 |
| Repulsione; dopo include costruzione adiacenze CSR | 2.27278333333333 | 1.87265 |
| Aggiornamento posizioni; dopo include sweep e scorrimento | 1.56609583333333 | 6.28165 |
| Proiezione residua dei contatti | 7.84082083333334 | 1.4311 |
| Invio rendering, per frame | 0.315772442588727 | 0.308544698544699 |

L'interpolazione resta nel renderer esistente. Nel profiler MCP iniziale `present` richiedeva 0.691 ms su 120 chiamate, mentre `_draw` (interpolazione e invio insieme) 54.644 ms su 120 chiamate. Non è disponibile un timing isolato del solo lerp né un timing GPU separato: non li si deduce per sottrazione. Il rendering ha 5 draw call e 8 nodi runtime; non è stato riscritto.

Profiling MCP iniziale salvato in `optimization_mcp_profile_before.json`. Il profiler successivo è conservato integralmente in `optimization_mcp_profile_after.json`, ma riporta 14131.013 ms per `_travel_fraction` in una cattura di 2.006 s: **tempi script cumulativi incoerenti, esclusi dalle conclusioni quantitative**. La tabella usa span monotoni interni, raccolti senza profiler.

### Modifiche mantenute e tentativi scartati

- Griglia: lista di celle occupate riutilizzata, pulizia delle sole teste occupate, posizione sorgente letta una volta nel ciclo interno, capacità iniziale delle coppie predisposta al reset.
- Una sola enumerazione del vicinato all'inizio del tick, riutilizzata per movimento e recupero contatti. A 30 Hz ogni agente percorre al massimo 65/30 unità: diametro più due spostamenti resta entro il raggio conservativo 20. La lista viene ricostruita ogni quattro iterazioni soltanto se occorre recuperare sovrapposizioni preesistenti.
- Movimento: adiacenze compatte CSR in buffer riutilizzabili, sweep analitico cerchio/cerchio e punto/rettangolo espanso, arresto al primo impatto e secondo tentativo tangenziale. Ordine degli ID alternato deterministicamente per ridurre favoritismi persistenti.
- Contatti: mobilità esplicita per agenti temporaneamente immobili; correzioni ripartite solo tra corpi mobili. Proiezione di recupero fino a 16 passaggi, uscita anticipata a tolleranza 0,05. Negli otto benchmark finali basta un passaggio, senza correzioni di sovrapposizioni oltre soglia.
- Ostacoli: rettangoli espansi precalcolati tramite `refresh_obstacles()`; chi modifica la geometria deve aggiornare la cache. Nessun cambiamento a geometria, spawn o destinazioni nel risultato finale.
- Recorder/controller: timing separati di ricostruzione, coppie, repulsione/adiacenze e posizioni/sweep; finestre wall-clock; tipo di build rilevato con `OS.is_debug_build()`; output esistente preservato tramite suffisso univoco.

Beneficio misurato della combinazione: meno lavoro di griglia/coppie e proiezione; aumenta il costo del movimento, che ora verifica i contatti durante il percorso. Le traiettorie e il numero di interazioni cambiano con collisioni più rigide: queste misure non isolano il beneficio di ogni micro-ottimizzazione. Non si attribuisce un guadagno numerico autonomo alla sola cache degli ostacoli.

Scartati: proiezione iterativa più intensa senza sweep (test stretto: compenetrazione massima 3.16476726531982, CPU media 32.4684125 ms/tick); primo sweep con vincolo soltanto sull'endpoint (ingresso nello spigolo dell'ostacolo, corretto con sweep continuo); corsie più larghe e coerenti oltre il passaggio (30 transiti contro 27 a 240 tick, 650 contro 676 bloccati: beneficio insufficiente per cambiare anche l'instradamento). Log dei tentativi conservati.

### Memoria e allocazioni

Nei casi finali il contatore di crescita dei buffer coppie è zero. Griglia, forze, adiacenze e contatti riutilizzano packed array; non si creano liste per singolo agente o query. Capacità insufficienti possono comunque crescere: non si dichiara un allocatore completamente privo di allocazioni.

Con 1.000 agenti congestionati, memoria statica da 65.2804002761841 a 65.3088045120239 MiB nella finestra. Il recorder aggiunge campioni a packed array durante la misura; le nuove strutture richiedono più memoria della baseline. Mancano un profiler delle allocazioni per chiamata e una nuova prova prolungata: nessuna conclusione generale sull'assenza di leak. L'MCP espone memoria statica e video, non una scomposizione affidabile delle allocazioni per tick.

### Qualità dei contatti e regressioni

`tests/crowd/contact_checks.gd`: 240 tick per scenario, due repliche identiche, coordinate valide, contatti e blocchi misurati ogni tick. Oracolo esaustivo per tutti i tick dei fixture da 100 agenti; per 1.000 ai tick 0/60/120/180/239. Il flusso opposto verifica anche la distanza minima durante l'interpolazione lineare relativa, tolleranza 0,1. Un agente è contato bloccato dopo almeno 30 tick consecutivi con spostamento sotto circa 1 unità/s; i corpi volutamente immobili sono inclusi.

Sovrapposizione = distanza < 9,9; compenetrazione = 10 − distanza, media sulle coppie oltre soglia. Valore zero significa nessuna violazione oltre 0,1, non assenza matematica di qualsiasi errore subpixel. Contatto = distanza ≤ 10,05; non coincide con sovrapposizione.

| Test | Agenti | Massima compenetrazione oltre soglia | Media sulle violazioni | Picco contatti | Picco bloccati | Transiti a 240 tick |
| --- | ---: | ---: | ---: | ---: | ---: | ---: |
| high_density | 100 | 0 | 0 | 20 | 0 | 50 |
| narrow_passage | 1000 | 0 | 0 | 1111 | 676 | 27 |
| opposing_flows | 100 | 0 | 0 | 18 | 0 | 60 |
| temporary_block | 100 | 0 | 0 | 39 | 12 | 100 |

Flussi opposti: distanza minima swept 9.9111442565918. Blocco temporaneo: i dieci agenti fissati restano fermi per 90 tick e il primo riprende con spostamento > 10 unità dopo il rilascio. Oracolo: 1188000 confronti per fixture da 100, 2497500 per quello da 1.000.

Anche `tests/crowd/crowd_checks.gd` passa tutte le otto combinazioni da 300 tick: popolazione, determinismo esatto, movimento, attraversamento, ostacoli, coincidenza iniziale e completezza/unicità delle coppie. La soglia di regressione è stata **stretta da 5 a 0,1**, senza disabilitare verifiche.

Esiti finali: parsing MCP dei file modificati valido; entrambi i runner headless terminano con codice 0. Suite debug senza errori/warning runtime nei log. Run MCP `a1723f03` eseguito, screenshot analizzato, zero errori/warning e poi arrestato. Nell'immagine i corpi sono separati ma la coda si addensa e si blocca al passaggio: conferma visiva del limite, non prova del target FPS.

### Confronto supplementare 600/800 agenti

Aggiunto dopo un aggiornamento esterno di AGENTS.md rilevato durante la sessione. Stesso protocollo; solo misure dopo, nessuna baseline precedente a queste quantità e nessuna decisione sul limite gameplay.

| Scenario | Agenti | FPS | p50 ms | p95 ms | CPU ms/tick | Memoria MiB | Sovrapposizioni | Bloccati | Transiti a 360 tick |
| --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| dispersed | 600 | 60.001965968781 | 14.664 | 20.58 | 3.0530875 | 65.0053210258484 | 0 | 0 | 517 |
| chokepoint | 600 | 60.0021381219281 | 15.785 | 27.269 | 8.41435833333333 | 65.0399737358093 | 0 | 345 | 50 |
| dispersed | 800 | 60.0021456068699 | 13.251 | 22.197 | 4.65160833333333 | 65.0419592857361 | 0 | 0 | 666 |
| chokepoint | 800 | 60.0021306369881 | 14.959 | 29.229 | 11.5168125 | 65.0766453742981 | 0 | 512 | 39 |

### Debug contro release e colli di bottiglia rimasti

**Debug:** misurato come sopra. **Windows release:** non esportato né eseguito, quindi nessun numero e nessuna stima. Tentativo CLI reale terminato con codice 1 perché manca `export_presets.cfg`; la cartella `C:/Users/yuris/AppData/Roaming/Godot/export_templates` è vuota e `C:/Tools/Godot` contiene solo gli eseguibili editor/console. Non sono stati creati preset, installati template o modificati `project.godot` e configurazioni globali/MCP. Il log è `optimization_export_check.log`. Il fallimento è di preparazione export, non un errore runtime della scena.

A 1.000 agenti congestionati il nuovo collo di bottiglia CPU è l'aggiornamento con sweep (6.28165 ms medi/tick), seguito dalle coppie (2.7151875). Il tick p95 è 17.433 ms, superiore al budget di un frame a 60 Hz, e l'esecuzione a 30 Hz concentra lavoro in frame alterni. La media FPS limitata a 60 nasconde questa disuniformità.

Il problema funzionale rimasto è il blocco collettivo all'ingresso e tra flussi: 669 bloccati a tick 360, 27 transiti contro i precedenti 509 ottenuti con contatti compenetrabili. Non si presenta questa regressione di portata come una soluzione completa della congestione o come prova di realismo. Il prossimo intervento deve separare costo CPU e qualità del flusso: misurare portata e tempo in coda, migliorare instradamento/coordinamento dei flussi preservando clearance e determinismo, poi valutare riduzione dei controlli di sweep ridondanti. Nessuna migrazione architetturale o riduzione silenziosa degli agenti.

### Riproduzione e file

Da PowerShell nella radice del progetto:

```powershell
& C:\Tools\Godot\Godot_v4.7.2-stable_win64_console.exe --path . --scene res://scenes/benchmarks/CrowdBenchmark.tscn --resolution 1152x648 --max-fps 60 --disable-vsync -- --suite --quit-on-complete --warmup=4 --duration=8 --tag=nuova_prova
& C:\Tools\Godot\Godot_v4.7.2-stable_win64_console.exe --headless --path . --script res://tests/crowd/crowd_checks.gd
& C:\Tools\Godot\Godot_v4.7.2-stable_win64_console.exe --headless --path . --script res://tests/crowd/contact_checks.gd
```

Aggiungere `--count=600` o `--count=800` dopo `--` per i casi supplementari. I quattro conteggi storici rimangono la suite predefinita. Per ripetere il codice precedente usare lo snapshot `optimization_sources_before.json` in una copia separata del progetto; non sovrascrivere la cartella di lavoro.

Fonti correnti in `docs/benchmark_results/`: `optimization_before.json`, `optimization_after.json`, `optimization_after_600.json`, `optimization_after_800.json`, `optimization_contact_checks.json`, profili, log e screenshot `optimization_chokepoint.png`. Test finali in `tests/crowd/optimization_checks_final_strict.log` e `optimization_contacts_final.log`.

File sorgente coinvolti: i quattro moduli in `scripts/simulation/`, `scripts/navigation/spatial_grid.gd`, i due moduli in `scripts/benchmarks/`, `tests/crowd/crowd_checks.gd` e il nuovo `tests/crowd/contact_checks.gd`. Renderer e scene esistenti non riscritti.

Hash di 27 file protetti verificati: test MCP originale, skills, CLAUDE.md e project.godot invariati; **AGENTS.md aggiornato esternamente**, preservato, non scritto da questo intervento. Nessuna modifica globale, dipendenza o commit. I dettagli sono in `optimization_protected_before.json` / `optimization_protected_after.json`.

API verificate nella documentazione Godot 4.7 tramite Context7: [packed array](https://github.com/godotengine/godot-docs/blob/4.7/classes/class_packedvector2array.rst), [requisiti export](https://github.com/godotengine/godot-docs/blob/4.7/tutorials/export/exporting_projects.rst); `OS.is_debug_build` verificato anche nella documentazione offline del motore installato.

---

## Storico: prima milestone, precedente a questa ottimizzazione

Le sezioni seguenti conservano metodo, architettura e risultati della prima milestone; il comportamento corrente e la conclusione sono definiti sopra.


Data: 2026-11-12. Prima milestone tecnica: simulazione funzionante fino a 1.000 agenti, senza gameplay o grafica definitiva.

**Target 60 FPS stabili: non raggiunto/verificato.** Con 1.000 agenti nel passaggio stretto la suite finale misura **53,90 FPS**, p95 **40,91 ms**, CPU simulazione **22,83 ms/tick**. La media da sola non descrive la fluidità. Nessuna misura proviene da un export Windows release.

## Architettura implementata

| File | Responsabilità |
| --- | --- |
| `scripts/simulation/crowd_state.gd` | Stato interno modificabile: posizioni attuali/precedenti, velocità, direzioni e gruppi in PackedVector2Array/PackedInt32Array. ID = indice stabile. |
| `scripts/simulation/benchmark_scenario.gd` | Mondo 1600×900, spawn deterministico, destinazioni, ostacoli e vincoli ai confini. Parametri di base costanti: raggio 5, velocità 65 unità/s. |
| `scripts/navigation/spatial_grid.gd` | Griglia densa di celle da 22 unità, liste concatenate heads/links, celle adiacenti precalcolate; buffer candidati e coppie riutilizzabili. |
| `scripts/simulation/crowd_movement.gd` | Repulsione entro 20 unità, integrazione e tre passaggi di proiezione dei contatti con distanza nominale 10. |
| `scripts/simulation/crowd_simulation.gd` | Orchestrazione del tick a 30 Hz; timing di griglia, movimento, separazione e tick completo; diagnostica. |
| `scripts/rendering/crowd_renderer.gd` | Un renderer per l'intera folla, texture circolare condivisa, colori dei gruppi, interpolazione tra stati; nessun nodo o callback per agente. |
| `scripts/benchmarks/benchmark_recorder.gd` | Campioni wall-clock, percentili, CPU e memoria statica, senza profiler script durante le suite. |
| `scripts/benchmarks/crowd_benchmark.gd` | Controlli, camera, HUD, raccolta risultati e suite configurabile. |
| `scenes/benchmarks/CrowdBenchmark.tscn` | Scena dedicata creata/salvata con gli strumenti scena/nodi Godot MCP. |
| `tests/crowd/crowd_checks.gd` | Regressioni deterministiche, ricerca spaziale confrontata con un oracolo esaustivo e correttezza del movimento. |

Tick: ricostruzione griglia → coppie univoche entro 20 unità → forze simmetriche e movimento → ricostruzione griglia/coppie → tre passaggi di separazione → conteggio transiti. La posizione precedente alimenta l'interpolazione del renderer. Lo stato è posseduto dai sistemi della simulazione: accesso sequenziale sul thread principale, nessuna scrittura concorrente.

La griglia si ricostruisce in O(celle + agenti); il costo del vicinato dipende dalle coppie locali e dalla densità. Non viene eseguita una scansione globale N×N. Nel caso patologico di tutti gli agenti nella stessa zona, il numero di coppie può comunque diventare quadratico. I buffer crescono se necessario, senza troncare coppie o ridurre la popolazione.

L'accumulatore usa tempo reale e non scarta tick: massimo quattro recuperi per frame, debito conservato e misurato. Il rendering continua indipendentemente dai tick. La scena contiene sei nodi; il processo MCP ne espone otto includendo root/strumentazione. Snapshot finale: cinque draw call, nessun nodo orfano. MultiMeshInstance2D è disponibile come alternativa (`--multimesh`), ma **non è stato benchmarkato**: tutti i dati qui riportati usano draw_texture_rect già raggruppato dal renderer.

## Scenari e comandi

- `dispersed`: due flussi opposti distribuiti nel mondo.
- `chokepoint`: muro verticale con apertura di 160 unità; due flussi opposti e corsie di attraversamento. Verifica congestione e contatti, senza promettere un sistema generale di navigazione.
- Popolazioni: 100, 300, 500, 1.000. Seed fisso: **20261112**.
- Tasti **1/2/3/4**: popolazione; **C**: scenario; **Spazio**: pausa/ripresa; **B**: suite; frecce: camera; **+/-**: zoom. Durante la suite gli altri comandi sono esclusi per proteggere il carico.
- Il test originale `tests/mcp/MCP_Test.tscn` rimane indipendente.

Dalla radice del progetto, PowerShell:

```powershell
$godot = 'C:/Tools/Godot/Godot_v4.7.2-stable_win64.exe'
# Parsing e regressioni; il pipe attende anche l'eseguibile Windows GUI.
& $godot --headless --path . --check-only --script res://scripts/benchmarks/crowd_benchmark.gd 2>&1 | Out-Host
& $godot --headless --path . --script res://tests/crowd/crowd_checks.gd 2>&1 | Out-Host
# Replica della suite finale: processo grafico, tutte le otto combinazioni.
& $godot --path . --scene res://scenes/benchmarks/CrowdBenchmark.tscn -- --suite --warmup=4 --duration=8 --tag=repeat --quit-on-complete 2>&1 | Out-Host
# Prova prolungata effettivamente eseguita, con limite a 60 FPS:
& $godot --path . --max-fps 60 --scene res://scenes/benchmarks/CrowdBenchmark.tscn -- --suite --count=1000 --scenario=chokepoint --warmup=4 --duration=30 --tag=soak_1000 --quit-on-complete 2>&1 | Out-Host
```

I risultati sono scritti in `docs/benchmark_results/<tag>.json`. Scegliere un tag nuovo per conservare le misure precedenti. Senza `--count` e `--scenario` si eseguono tutte le combinazioni. Non eseguire test headless, profiler o altri benchmark contemporaneamente alla raccolta prestazionale.

## Hardware e metodologia

- Windows 11 Home, versione 10.0.26300; Intel Core i3-1115G4 @ 3,00 GHz, due core/quattro thread; RAM visibile 8.105.456 KiB.
- Intel UHD Graphics, driver 30.0.100.9805; OpenGL 3.3, GL Compatibility.
- Godot Standard **4.7.2.stable.official.ed1daf0bf**, eseguibile Windows debug/editor. Suite avviate tramite MCP in modalità **process**, finestra reale 1152×648, senza profiler durante la misura. Editor aperto.
- VSync richiesto: enabled; nessun limite Engine.max_fps nella suite MCP. Il pacing osservato varia e alcuni intervalli superano 60 FPS: non sono prove di un refresh stabile o di capacità release.
- Warmup nominale 4 s per caso, campionamento nominale 8 s tramite timer del motore. Gli intervalli reali finali sono **7,895–8,292 s**, registrati in ogni risultato: i timer Godot e il tempo wall-clock possono differire.
- FPS = frame raccolti / durata wall-clock. Frame time da Time.get_ticks_usec; mediana/p95/p99 sui campioni, non da 1000/FPS medio. Il primo intervallo può essere parziale.
- CPU simulazione = durata wall-clock del codice del tick, inclusa eventuale preemption del sistema operativo; non è utilizzo percentuale dell'intero processore. I sottotiming separano griglia/coppie, movimento e contatti.
- Memoria statica: OS.get_static_memory_usage ogni 30 frame, allocazioni Godot debug; non include tutto il working set o la memoria GPU. I campioni grezzi frame/tick/memoria restano nei JSON.
- La suite finale e il confronto baseline sono singole esecuzioni per caso, senza intervalli di confidenza. Il carico include la congestione transitoria dopo lo spawn.

## Risultati finali — suite MCP

Fonte: [filtered_pairs.json](benchmark_results/filtered_pairs.json). Tempi in millisecondi; memoria media delle allocazioni statiche in MiB.

| Scenario | Agenti | FPS medi | Frame p50 | p95 | p99 | CPU/tick media | Memoria |
| --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| Disperso | 100 | 83,63 | 14,64 | 18,17 | 19,06 | 1,12 | 83,80 |
| Disperso | 300 | 60,62 | 16,48 | 19,82 | 20,65 | 2,31 | 83,87 |
| Disperso | 500 | 60,02 | 14,32 | 21,90 | 22,85 | 3,96 | 83,95 |
| Disperso | 1.000 | 69,03 | 15,38 | 28,87 | 31,86 | 10,71 | 84,11 |
| Passaggio stretto | 100 | 60,01 | 16,49 | 18,46 | 18,81 | 1,26 | 83,91 |
| Passaggio stretto | 300 | 59,97 | 17,97 | 21,42 | 22,76 | 3,75 | 83,98 |
| Passaggio stretto | 500 | 60,05 | 16,71 | 25,80 | 27,06 | 7,37 | 84,06 |
| Passaggio stretto | 1.000 | 53,90 | 23,27 | 40,91 | 44,25 | 22,83 | 84,21 |

La simulazione finale mantiene circa 30 Hz in tutti i casi (29,94–30,06); il debito massimo misurato resta entro un tick. Nessuna posizione non finita, fuori confine o dentro gli ostacoli nei controlli finali. Nel caso stretto da 1.000 agenti, al termine: 519 transiti sul piano centrale, 528 agenti nella zona centrale, 357 coppie con distanza <9,9 e penetrazione massima 2,73 unità. I transiti possono contare lo stesso agente più volte: non sono persone uniche o un throughput certificato.

## Profiling e ottimizzazioni misurate

Il profiler iniziale individua `SpatialGrid.gather`, `integrate` e `separate` come costi prevalenti; il rendering dei cerchi è secondario. Il primo tentativo di coppie univoche più tre passaggi di contatto corregge la regressione fisica, ma enumera troppe coppie e peggiora il costo. Il filtro di distanza nella costruzione delle coppie riduce i buffer da percorrere: è la versione finale mantenuta.

| Versione, 1.000 agenti | Disperso CPU/tick | Stretto CPU/tick | Stretto FPS | Stretto p95 frame |
| --- | ---: | ---: | ---: | ---: |
| Baseline: query ripetute, un passaggio contatti | 16,99 | 34,62 | 8,47 | 172,25 |
| Intermedia: coppie senza filtro, tre passaggi | 19,54 | 51,12 | 4,86 | 244,32 |
| Finale: coppie filtrate, tre passaggi | 10,71 | 22,83 | 53,90 | 40,91 |

Riduzione CPU rispetto alla baseline: circa 37% disperso, 34% stretto, pur usando più passaggi di contatto. Il conteggio transiti è incluso nel timing finale; la baseline lo escludeva (sottostima leggermente il suo costo). La traiettoria può cambiare con l'ordine delle coppie e il solver: confronto sullo stesso scenario/seed, non sugli stessi identici stati fisici.

Nel caso finale da 1.000 agenti stretto: griglia e costruzione coppie **9,03 ms**, movimento **4,46 ms**, separazione **9,09 ms**; submission dei cerchi **0,33 ms/frame**, esclusa esecuzione GPU. Il tick di circa 23 ms sul thread principale spiega i frame oltre il budget di 16,67 ms. La griglia da sola non elimina il costo della densità.

Artefatti: [baseline.json](benchmark_results/baseline.json), [optimized_pairs.json](benchmark_results/optimized_pairs.json), [baseline_sources.json](benchmark_results/baseline_sources.json), [baseline_profile.json](benchmark_results/baseline_profile.json). Il profilo intermedio `pairs_profile_raw.json` contiene durate script incoerenti con il suo intervallo di circa due secondi: **scartato come fonte quantitativa**. I timing della tabella provengono dal recorder interno, senza profiling.

## Prova prolungata e memoria

[soak_1000.json](benchmark_results/soak_1000.json): processo CLI grafico senza bridge MCP, limite esplicito a 60 FPS, stesso seed/scenario, 29,997 s misurati dopo warmup nominale 4 s.

- 59,77 FPS; frame p50 21,91 ms, p95 32,75 ms, p99 35,06 ms.
- 900 tick misurati: 30,003 Hz; CPU media 11,85 ms/tick, p95 21,36 ms.
- Allocazioni statiche da 64,474 a 64,542 MiB: +0,068 MiB, compatibile con i buffer di registrazione che crescono durante il campionamento. Non dimostra assenza di crescita illimitata su sessioni lunghe.
- Snapshot del processo durante la prova: working set 251,46 MiB, memoria privata 185,12 MiB; è un singolo campione, non un picco o una media.
- Fine prova: 1.000 agenti, zero posizioni invalide, 1.160 transiti, nessuna sovrapposizione residua nello snapshot finale. Nessun errore nel log; uscita 0.

La finestra da 30 s include una fase finale più dispersa e un limite FPS diverso dalla suite MCP: la sua media non sostituisce il risultato della congestione iniziale, né è un confronto diretto della memoria con il processo strumentato.

## Verifiche eseguite ed evidenze

- Validazione MCP di tutti gli script e parsing CLI del controller: nessun errore.
- Regressioni headless: otto combinazioni scenario/popolazione, due simulazioni identiche di 300 tick ciascuna; identità deterministica esatta sulla stessa build, popolazione costante, movimento, coordinate finite e ostacoli controllati ogni tick, attraversamento e vicini ai bordi.
- Coppie spaziali univoche e complete confrontate con ricerca esaustiva; coppia coincidente separata, punto nel muro respinto e apertura percorribile.
- Penetrazione campionata ogni 30 tick: limite di regressione 5 unità. Baseline falliva a **7,31**; finale passa con massimo **4,44** nel caso stretto da 1.000 agenti. Contatti **morbidi**, non collisioni rigide prive di sovrapposizione: questo limite non garantisce tutti gli istanti o configurazioni arbitrarie.
- Ultima correzione solo diagnostica: preservati i contatori delle query tra letture ripetute; test mirato e parsing ripetuti con uscita 0. Non cambia la dinamica o i timing della suite.
- Input live MCP: pausa ferma il tick a 105 per due letture separate; ripresa porta a 137. Cambio popolazione/scenario e pan/zoom della camera verificati.
- Screenshot [chokepoint_final.png](benchmark_results/chokepoint_final.png) acquisito e analizzato: 1.000 marcatori, congestione leggibile, muro/apertura visibili, HUD leggibile. Catturato in pausa: il suo FPS non è un risultato benchmark. `chokepoint_initial.png` è una prova funzionale iniziale con test headless concorrente, esclusa dalle misure.
- Log runtime MCP: zero errori e zero warning; run avviati per il lavoro arrestati. Evidenze in `runtime_checks.json`; test in `tests/crowd/checks_initial.log`, `checks_optimized.log`, `checks_filtered.log`, `grid_checks.log`, `parse.log`.
- I 14 file originali sotto `tests/mcp` conservano gli hash iniziali. Nessuna scrittura diretta a `project.godot`: durante il lavoro è comparsa l'assegnazione della scena principale al test MCP originale (`uid://6iovwjj8k5rv`), estranea alle operazioni esplicite effettuate. È stata lasciata intatta; la nuova scena viene sempre avviata tramite percorso esplicito. Confronti in `protected_files.json`.

## Limiti e prossimi passi

Nessun export Windows release eseguito: manca `export_presets.cfg` e la directory locale dei template non contiene template installati. Non sono state installate dipendenze o modificate configurazioni globali/MCP. Determinismo verificato solo sulla stessa versione/build; nessuna promessa cross-platform.

Restano da misurare: release esportata, ripetizioni con controllo del pacing/focus e carico di sistema, sessioni più lunghe, MultiMesh e scenari più ampi. Prima di aggiungere gameplay: ridurre il costo di costruzione coppie e delle proiezioni nella congestione, mantenendo le regressioni fisiche e la frequenza a 30 Hz. Possibili esperimenti separati: celle attive anziché scansione dell'intera griglia, buffer distinti per repulsione e contatti, solver con convergenza controllata; ogni alternativa va confrontata sul medesimo workload. Nessun passaggio a C++ o riduzione nascosta della popolazione.
