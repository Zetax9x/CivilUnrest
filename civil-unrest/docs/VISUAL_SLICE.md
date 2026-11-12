# Prima vertical slice 3D isometrica — 2026-11-12

## Avvio e controlli

`scenes/main/Main.tscn` rimane l'ingresso configurato del progetto. `WorldHost` contiene un'istanza della scena riutilizzabile `scenes/urban/UrbanSquare.tscn`. Il vecchio messaggio provvisorio è conservato e nascosto. Test MCP e benchmark mantengono ingressi indipendenti.

- WASD: spostamento relativo alla telecamera; rotellina: zoom ortografico.
- Q/E: rotazione di 90°; HOME: ripristino della vista.
- 1/2: ripartenza dello scenario con 50/100 persone e seed 20261112.
- SPAZIO: pausa/ripresa della simulazione; la telecamera rimane utilizzabile.
- Parametri esportati: popolazione, seed, limite FPS; velocità, rettangolo di movimento, zoom minimo/massimo e orientamento iniziale della telecamera.

## Moduli e invarianti

| Modulo | Responsabilità |
| --- | --- |
| `scripts/presentation/crowd_session.gd` | Usa il core 2D esistente a 30 Hz; massimo quattro tick per fotogramma conservando il debito temporale. |
| `scripts/rendering/crowd_3d_adapter.gd` | Conversione reversibile X/Y → X/Z, scala 0,05 m/unità, altezza del suolo e orientamento. |
| `scripts/rendering/crowd_renderer_3d.gd` | Interpolazione in sola lettura; cinque MultiMesh condivisi per corpi, teste, gambe, facce e contatto a terra. |
| `scripts/camera/isometric_camera.gd` | Telecamera ortografica, inclinazione 45°, input e limiti; nessuna dipendenza dalla simulazione. |
| `scripts/world/urban_environment.gd` | Geometria statica originale raggruppata in MultiMesh, materiali e arredo. |
| `scripts/world/urban_slice.gd` | Composizione, HUD e snapshot diagnostici preparati dopo l'aggiornamento del fotogramma. |

Nessuna modifica a movimento, griglia, collisioni, precedenze o determinismo del core. Nessun nodo fisico, AI o processo individuale per personaggio. Il numero di nodi runtime misurato resta 39 sia con 50 sia con 100 persone, incluso il runtime MCP.

Il dominio pedonale resta quello disperso del core, 1600×900 unità → 80×45 m. Il diametro di collisione di 10 unità diventa 0,5 m. Edifici, veicoli e arredi solidi sono all'esterno del dominio, con margine controllato automaticamente; i marciapiedi hanno raccordi visivi. Non è stata aggiunta una seconda simulazione fisica 3D. La navigazione di una futura mappa urbana con ostacoli interni richiederà un'interfaccia di scenario dedicata: questa slice riutilizza ancora `benchmark_scenario.gd` come dati, senza istanziare la scena benchmark.

La piazza comprende asfalto, marciapiedi con giunti, attraversamento e parcheggi, tre edifici con finestre/cornici/insegne, lampioni, alberi, panchine, tre veicoli civili e un mezzo della polizia. Geometrie procedurali originali, primitive e font predefiniti del motore; nessun asset esterno scaricato. Luce direzionale con ombre, luce ambiente e materiali semplici. I personaggi sono segnaposto senza animazione articolata; il renderer costituisce il punto di sostituzione per futuri modelli animati/LOD, ancora non implementati.

## Verifiche effettivamente eseguite

- Parsing automatico MCP degli script e caricamento di Main da CLI: `Godot_v4.7.2-stable_win64_console.exe --headless --path . --scene res://scenes/main/Main.tscn --quit-after 5`, exit 0, nessun errore/warning. [Log](visual_slice/parse.log).
- Test grafico: `Godot_v4.7.2-stable_win64_console.exe --path . --script res://tests/presentation/vertical_slice_checks.gd`, exit 0, **49 controlli superati**. Coordinate, conteggi MultiMesh, renderer in sola lettura, separazione e limiti, pausa, recupero del debito, telecamera, ingombri statici e getter diagnostico privo di modifiche alla griglia. Per 50 e 100 persone, posizioni identiche al core di riferimento a ciascuno dei 120 tick. [Risultati](visual_slice/checks.json), [log](visual_slice/checks.log).
- Il test dei trasform MultiMesh richiede un renderer grafico: due tentativi iniziali headless hanno fallito quel controllo perché il backend Dummy restituiva trasformazioni nulle. Le asserzioni sono rimaste attive; il test finale è stato eseguito con OpenGL. Il controllo headless sopra verifica soltanto parsing/caricamento.
- Main avviato tramite MCP in modalità `process`; screenshot acquisiti e analizzati: [vista generale](visual_slice/overview_final.png), [rotazione/zoom](visual_slice/rotated_zoom.png), [personaggi ravvicinati](visual_slice/characters_close.png). Strada, attraversamento, facciate, veicolo della polizia e persone risultano distinguibili. La vista ravvicinata conferma sagoma e contatto con il suolo; non verifica animazioni assenti.
- Input MCP reali: tutte le direzioni WASD; E da 45° a 135°, Q di ritorno; rotellina, HOME, estremi zoom 24/100 e movimento bloccato ai limiti X=28/Z=-18. Quattro rotazioni complete sono inoltre verificate dal test automatico. [Evidenza](visual_slice/camera_input_checks.json).
- Pausa: tick 372 e prima posizione identici in due letture distanziate; ripresa: tick 392 e posizione cambiata. La correzione del getter diagnostico usa snapshot: la prima implementazione ricalcolava la diagnostica mutante durante le richieste MCP e si era verificato un blocco con timeout. Dopo la correzione il blocco non si è ripresentato nelle prove registrate. Nessuna modifica al server/addon.
- Test originale `tests/mcp/MCP_Test.tscn`, run `612a597f`: 20 agenti, coordinate finite; pausa al tick 588 stabile in due letture, ripresa al tick 602 con posizioni cambiate. Zero errori/warning.
- Benchmark 2D originale, run `f96f313b`: 1.000 agenti `chokepoint`, tick 36 → 361, transiti unici 6 → 328; zero sovrapposizioni oltre soglia, posizioni invalide e agenti bloccati nelle letture. Le letture diagnostiche sono state eseguite a scena in pausa. È un controllo funzionale, non una ripetizione della suite prestazionale. Zero errori/warning.
- Tutti i processi avviati sono stati arrestati. [Stati runtime](visual_slice/runtime_checks.json). Confronto SHA-256: **195 file protetti identici**, inclusi test MCP, benchmark/test 2D, algoritmi, `project.godot`, AGENTS/CLAUDE, skills e addon. [Verifica](visual_slice/preservation.json). Nessun commit.

## Prestazioni misurate della slice

PC: Intel Core i3-1115G4 3,00 GHz, Intel UHD Graphics (driver OpenGL 30.0.100.9805), 8.299.986.944 byte di RAM fisica, Windows 11 Home 10.0.26300. Godot 4.7.2.stable.official.ed1daf0bf Standard, Compatibility/OpenGL 3.3, processi debug separati con editor aperto.

Condizioni uguali: seed 20261112, scenario disperso, 1152×648, simulazione 30 Hz, limite 60 FPS, VSync disabilitato, MSAA 2×, camera ortografica size 74, yaw 45°/pitch −45°, posizione (−3,0,−9). Impostazioni applicate soltanto al processo della slice; `project.godot` invariato. Nuovo processo per popolazione, tasto 1/2 per reset, 4 secondi di riscaldamento, poi `godot_game_perf(sample_seconds=8, monitors=true)`. Nessun test CLI o secondo gioco eseguito durante la misura. Una prova per popolazione; non è uno stress test prolungato.

| Persone | FPS medi MCP | Frame medio / mediano | Frame p95 / massimo | Process medio MCP | Memoria statica iniziale | Draw call |
| ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| 50 | 60 | 16,666 / 16,666 ms | 16,718 / 17,096 ms | 2,480 ms | 88,89 MiB | 47 |
| 100 | 60 | 16,666 / 16,666 ms | 16,697 / 16,902 ms | 2,930 ms | 88,90 MiB | 47 |

Entrambe le acquisizioni: 481 fotogrammi in 8,016 s; zero spike sopra 33,332 ms e zero errori/warning runtime. Delta memoria statica +0,04 MiB per prova, nodi invariati; non dimostra assenza di crescita a lungo termine. `process_ms` è il monitor di processo del motore, non la CPU media del solo tick di simulazione. La memoria statica è quella delle allocazioni Godot, non il working set totale. Dati MCP originali e stati prima/dopo: [performance.json](visual_slice/performance.json).

## Limiti e prossimo passo

Le prove sostengono il mantenimento del limite 60 FPS durante queste brevi acquisizioni debug con 50/100 segnaposto. Non certificano una build release, una scena finale o 1.000 personaggi 3D. I benchmark 2D precedenti restano in `BENCHMARK.md` e non vanno confrontati direttamente con questa scena.

Mancano animazioni, LOD effettivi, selezione tattica e gestione delle occlusioni: nelle viste ruotate le facciate possono nascondere persone, e alcuni edifici vengono tagliati dall'inquadratura. Zoom e rotazione aiutano l'ispezione, ma non sostituiscono un futuro sistema di leggibilità tattica. La piazza è una presentazione del core disperso, senza gameplay, missioni, fazioni complete o combattimenti. Prossimo passo: definire scenario urbano navigabile e criteri di leggibilità/occlusione prima di aggiungere contenuti di gioco.
