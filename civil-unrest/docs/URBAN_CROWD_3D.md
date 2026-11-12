# Folla urbana 3D integrata — 2026-11-12

## Scena e architettura

Scena indipendente: `res://scenes/benchmarks/UrbanCrowd3D.tscn`. Non viene caricata da Main e non introduce gameplay.

| Componente | Responsabilità |
| --- | --- |
| `scripts/benchmarks/urban_crowd_3d.gd` | Composizione, selezione dei casi, HUD, osservazione dei tick e registrazione delle misure. |
| `scripts/presentation/crowd_session.gd` | Core esistente a 30 Hz; aggiunti parametro opzionale dello scenario e segnale dopo ogni tick. Le chiamate precedenti a due argomenti rimangono valide. |
| `scripts/characters/character_simulation_adapter.gd` | Adattatore esistente in sola lettura: interpolazione 2D → X/Z, orientamento e velocità ottenuta dallo spostamento effettivo. |
| `scripts/characters/character_renderer.gd` | Renderer esistente, tre MultiMesh, pose condivise Idle/Walk/Run/Turn/Stop, varianti e LOD. Nessun nodo, AnimationTree o corpo fisico per individuo. |
| `scripts/world/urban_environment.gd` | Ambiente modulare esistente: edifici, strada, marciapiedi, segnaletica, arredi, vegetazione e veicoli. |
| `scripts/benchmarks/urban_crowd_obstacles.gd` | Rappresentazione visiva dei rettangoli di ostacolo forniti dal core; nessuna nuova collisione 3D. |
| `scripts/camera/isometric_camera.gd` | Telecamera ortografica esistente, indipendente dalla simulazione. |

Le associazioni gruppo/archetipo riutilizzano i tre gruppi del core: civile, manifestante, polizia; varianti deterministiche `i % 15`. Scala esistente: 0,05 m/unità. Il dominio 1600×900 corrisponde a 80×45 m. Il passaggio conserva gli ostacoli originali e l'apertura di 160 unità/8 m; il diametro simulato è 10 unità/0,5 m. Gli edifici sono fuori dal dominio attraversabile. La scena rappresenta i casi del benchmark originale, senza introdurre navigazione urbana aggiuntiva.

Comandi: **1/2/3/4/5** = 20/100/300/600/800 persone; **C** cambia scenario; **Spazio** congela/riprende simulazione e stato visivo; **B** esegue la matrice; **WASD**, rotella, **Q/E**, **Home** controllano la camera. Popolazione e scenario non cambiano durante una suite. Pan limitato a X ±40, Z ±25; zoom 12–110.

## Protocollo riproducibile

- Intel Core i3-1115G4, Intel UHD Graphics, Windows 11 build 26300, RAM fisica rilevata 7,73 GiB.
- Godot **4.7.2 Standard, debug standalone**, Compatibility/OpenGL 3.3. Nessuna build release misurata.
- 1152×648, MSAA 4×, limite 60 FPS, VSync disabilitato nel processo. Nessuna modifica a project.godot.
- Camera ortografica size 70, yaw 45°, pitch −45°, posizione (−3, 0, −9), LOD 2 in tutte le finestre numeriche. Luce, ambiente e ombre identici fra i casi; le barriere compaiono soltanto nello scenario congestionato.
- Seed **20261112**, core a **30 Hz**. Per ciascuna popolazione: disperso, poi passaggio stretto; reset completo, **4 s di warm-up + almeno 8 s reali di campione**. Una ripetizione per caso; non è una prova di stabilità prolungata.
- 800 viene eseguito dopo entrambi i casi da 600 se ciascuno mantiene almeno 29 tick/s, debito massimo ≤0,5 s e p95 ≤100 ms. Questi criteri verificano la possibilità di completare il test, non il raggiungimento di 60 FPS. I due casi da 600 li hanno rispettati.
- Nessun altro gioco, test headless, screenshot o profiler attivo durante le finestre misurate. L'editor MCP rimane aperto. QA e profiler eseguiti separatamente.

Il registratore originale misura intervalli reali tra frame, inclusa la limitazione FPS. CPU simulazione = durata strumentata del solo `step`, per tick. CPU renderer = adattatore + pose + invio delle trasformazioni alle MultiMesh, per frame; **non comprende tempo GPU, driver o rendering completo dell'ambiente**. I percentili dei componenti non si sommano.

Memoria = media di `OS.get_static_memory_usage()`, campionata ogni 30 frame; non è RSS del processo né memoria GPU. JSON include primo/ultimo campione, VRAM diagnostica, campioni grezzi, p99, componenti CPU, conteggi di nodi/parti e debito della simulazione. I picchi di memoria fra i campioni possono sfuggire; nessuna conclusione su perdite a lungo termine.

Bloccato conserva la definizione originale: spostamento inferiore a circa 0,0333 unità per tick per almeno 30 tick consecutivi. Sovrapposizione oltre soglia = penetrazione superiore a **0,1 unità 2D**, cioè 5 mm in scala. Diagnostica ogni 30 tick e a fine caso; i risultati non certificano ogni tick intermedio.

Esecuzione PowerShell dalla radice del progetto, usando il percorso locale dell'eseguibile:

```powershell
$godot = 'C:\Tools\Godot\Godot_v4.7.2-stable_win64_console.exe'
& $godot --path . --scene res://scenes/benchmarks/UrbanCrowd3D.tscn --resolution 1152x648 --max-fps 60 --disable-vsync --log-file docs/urban_crowd_3d/suite.log -- --suite --quit-on-complete --tag=integrated_debug
```

Per una nuova acquisizione usare un tag diverso: il file del tag è aggiornato dopo ogni caso come checkpoint. `--count=600` e `--scenario=chokepoint` permettono un caso singolo. La matrice completa usa sempre le stesse impostazioni.

## Risultati misurati

[JSON completo](urban_crowd_3d/integrated_debug.json), [log](urban_crowd_3d/suite.log). Tempi in ms, memoria in MiB; CPU indicate come medie. B/O = agenti bloccati/sovrapposizioni oltre soglia, sia al termine sia nei campioni diagnostici della finestra.

| Persone | Scenario | FPS medi | Frame mediano | Frame p95 | CPU sim/tick | CPU renderer/frame | Memoria | B/O |
| ---: | --- | ---: | ---: | ---: | ---: | ---: | ---: | --- |
| 20 | Disperso | 60,00 | 16,66 | 17,42 | 0,126 | 0,557 | 69,46 | 0/0 |
| 20 | Congestionato | 60,00 | 16,65 | 17,35 | 0,145 | 0,492 | 69,54 | 0/0 |
| 100 | Disperso | 60,00 | 16,63 | 19,16 | 0,422 | 1,974 | 70,93 | 0/0 |
| 100 | Congestionato | 60,00 | 16,68 | 19,77 | 0,605 | 2,103 | 70,99 | 0/0 |
| 300 | Disperso | 60,00 | 16,41 | 25,34 | 1,224 | 5,832 | 75,02 | 0/0 |
| 300 | Congestionato | 60,00 | 16,42 | 26,56 | 2,061 | 6,186 | 75,08 | 0/0 |
| 600 | Disperso | 59,82 | 13,84 | 35,48 | 3,092 | 12,967 | 81,12 | 0/0 |
| 600 | Congestionato | 55,12 | 15,72 | 35,86 | 5,519 | 13,585 | 81,18 | 0/0 |
| 800 | Disperso | 40,86 | 19,22 | 45,58 | 4,760 | 19,406 | 85,64 | 0/0 |
| 800 | Congestionato | 32,47 | 23,52 | 52,97 | 7,972 | 21,688 | 85,70 | 0/0 |

Frequenza effettiva: **29,94–30,10 tick/s**; piccole differenze dipendono dai tick interi ai bordi della finestra. Debito massimo inferiore a 0,034 s in ogni caso: nessuna perdita di tick né simulazione artificialmente rallentata per sostenere il rendering. Posizioni invalide e penetrazione massima oltre soglia: zero nelle letture diagnostiche. Nessun errore runtime nel log della suite.

**60 FPS stabili non confermati**, nemmeno dai casi con media 60: i p95 superano 16,67 ms. Il mediano sotto 16,67 ms in alcuni casi non contraddice il limite medio: i frame lunghi e il recupero del pacing producono intervalli non uniformi. Questi risultati non vanno confrontati direttamente con lo showcase da 10/20 personaggi: ambiente, traiettorie, core e livello LOD sono differenti.

## Costi osservati e limiti

A 800 congestionati, CPU renderer media **21,688 ms/frame**: adattatore **2,037 ms**, pose **7,968 ms**, invio delle parti **11,672 ms**. Le pose hanno mediana 0 e p95 **28,104 ms**: il renderer esistente ricampiona insieme gli individui a 10 Hz. Il costo delle trasformazioni rimane per frame anche al LOD lontano. Sono presenti **11.999 parti**, tre MultiMesh e 33 nodi complessivi nella lettura finale, non 800 scene individuali.

Il core costa 7,972 ms/tick a 30 Hz; i dati indicano come priorità l'invio delle parti e la distribuzione temporale delle pose, prima di riscrivere la simulazione. Non sono state applicate ottimizzazioni speculative né modificate le animazioni per migliorare il risultato. Il tempo GPU non è stato isolato, quindi non si esclude un ulteriore limite grafico.

Profilo MCP separato, 600 congestionati, 3,018 s: [dato grezzo](urban_crowd_3d/mcp_profile.json). **Limitazione del profiler:** `present.self_ms` riporta 57.976,934 ms, impossibili in quella finestra; quel valore non viene usato come misura. I tempi CPU della tabella provengono dagli span strumentati, non da questa statistica MCP. Il profilo con debugger ha carico e memoria diversi dalla suite standalone.

## Animazioni e verifica visiva

- Avvio tramite MCP, run finale `59a73dd2`, zero errori e warning; poi arrestato.
- Screenshot reali aperti e analizzati: [standard, 100/LOD 2](urban_crowd_3d/standard.png), [ravvicinato, 100/LOD 0](urban_crowd_3d/closeup.png), [fotogramma successivo](urban_crowd_3d/animation_next.png), [congestione, 600](urban_crowd_3d/congested_600.png). Modelli, caschi, zaini e pose sono presenti; la leggibilità degli abiti scuri sull'asfalto diminuisce alla distanza standard.
- Posizione, orientamento, fase e trasformazione della coscia variano fra due letture dello stesso individuo senza reset. Walk, Run e Stop sono entrati naturalmente durante la matrice; tutti i cinque stati e le transizioni sono verificati dal runner originale dei personaggi.
- **Idle e Turn non sono entrati naturalmente nei casi integrati da 12 s.** Il core non emette un obiettivo di orientamento a riposo: l'adattatore conserva l'orientamento visivo quando lo spostamento è nullo. Turn resta disponibile e verificato con input visivo controllato; non si dichiara una sua osservazione spontanea nel benchmark.
- Velocità di animazione basata sullo spostamento realmente ottenuto, non sulla velocità desiderata; avanzamento della fase proporzionale alla distanza. Test originale: arresto nonostante steering richiesto, Walk/Run/Stop/Idle/Turn, rotazione limitata, replay visivo e raccordi delle gambe. Massima distanza caviglia/piede nel test: **0,001618 m**. Questa misura non certifica assenza di scivolamento sul terreno.
- Zoom reale con rotella: size 70 → 25,17 seleziona LOD 2 → 0; ritorno intermedio seleziona LOD 1, 2.130 parti a 100 persone. Movimento radice e parti degli arti confermati nelle catture ravvicinate. Nessuna certificazione completa di assenza di scivolamenti durante collisioni, inversioni e blend: manca IK/appoggio vincolato al terreno.
- Pausa: tick **137 → 137**, posizioni e fasi identiche; ripresa fino al tick 180. Pan e rotazione reale: yaw **45° → 135°**, posizione camera cambiata; Home ripristina l'inquadratura. Nessuna modifica permanente delle scene durante QA.

[Evidenza MCP](urban_crowd_3d/visual_qa.json). Le catture non appartengono alle finestre numeriche del benchmark. LOD 0/1 funzionali ma non è stata eseguita l'intera matrice prestazionale a zoom ravvicinato; con più parti il costo può aumentare.

## Regressioni eseguite

| Verifica | Esito e prova |
| --- | --- |
| Import/parsing progetto | Headless editor import, exit 0: [log](urban_crowd_3d/import.log). I due warning UID della prima esecuzione, prima dell'import, sono scomparsi nelle esecuzioni finali. |
| Nuova integrazione | **4.816 controlli**, exit 0: confronto esatto con il core per 960 tick, bridge in sola lettura, interpolazione, pausa/reset, recupero debito senza perdita di tick, caricamento scena. [JSON](urban_crowd_3d/integration_checks.json), [log](urban_crowd_3d/integration_checks.log). |
| Personaggi esistenti | **6.314 controlli**, exit 0: [log](urban_crowd_3d/character_checks.log). |
| Core 2D originale | Runner `tests/crowd/crowd_checks.gd`: otto casi 100/300/500/1.000, due repliche per 300 tick; griglia, determinismo, confini, movimento, attraversamenti e separazione: PASS. [Log](urban_crowd_3d/regression_2d_checks.log). |
| Benchmark 2D originale | Scena invariata, esecuzione grafica debug a 1.000 nei due scenari, 4+8 s: 60 FPS medi, p95 disperso **24,183 ms**, congestionato **29,381 ms**, zero errori. [JSON](benchmark_results/urban_3d_regression.json), [log](urban_crowd_3d/regression_2d_benchmark.log). È una regressione funzionale/prestazionale separata, non un confronto a parità di rendering. |
| Main | Avvio MCP `89c48709`; WorldHost/UrbanSquare presente, 100 agenti, tick 19, nessuna posizione invalida o sovrapposizione nella lettura, zero errori/warning, arrestato. |
| ItalianStreet | Avvio MCP `670e66f6`, screenshot [aperto e analizzato](urban_crowd_3d/regression_italian_street.png), zero errori/warning, arrestato. |
| MCP_Test originale | Avvio MCP `cb3f22e7`, 20 agenti finiti, posizioni e tick cambiano fra due letture; zero errori/warning, arrestato. |

Nessuna modifica a Main, ItalianStreet, MCP_Test, algoritmi/core 2D, benchmark 2D, project.godot, skills, istruzioni, addon o configurazioni. Unico modulo preesistente modificato: `crowd_session.gd`, per composizione dello scenario e osservabilità. Confronto dei 269 file sorgente/configurazione protetti: **268 invariati**, una modifica autorizzata alla sessione. [Baseline](urban_crowd_3d/preservation_before.json), [verifica finale](urban_crowd_3d/preservation.json).

Nessun commit, asset esterno, dipendenza o gameplay. L'intervento allora proposto (pose distribuite, invio aggregato) è descritto nella sezione seguente.

## Ottimizzazione del renderer dei personaggi — 2026-11-12

Modificato soltanto `scripts/characters/character_renderer.gd`, con le stesse API pubbliche. Core 2D, adattatore, catalogo, pose, scene, asset e `project.godot` invariati: `git diff` vuoto su `scripts/simulation`, `scripts/presentation`, `scenes`, `project.godot`. In `urban_crowd_3d.gd`: tempo GPU del viewport, contatori opzionali del renderer e argomento `--camera-size=` per i LOD ravvicinati.

### Profilo prima delle modifiche

`tests/presentation/character_render_profile.gd` ricostruisce la pipeline originale dal catalogo e misura ogni fase sugli stessi dati: finestra grafica, 240 frame, LOD 2, congestionato. [800](urban_crowd_3d/render_profile_before_800.json), [300](urban_crowd_3d/render_profile_before_300.json). Medie a 800 (12.000 parti):

| Fase | ms/frame |
| --- | ---: |
| Pose interpolate, tutti gli agenti (un ricampionamento completo) | 20,572 |
| Pose: keyframe più vicino, tutti gli agenti | 0,382 |
| Preparazione `root * bone * local` con binding Dictionary | 10,951 |
| `set_instance_transform` per parte | 1,945 |
| Scrittura di 12 float per parte in un buffer GDScript | 10,059 |
| `multimesh_set_buffer`, tre chiamate | 0,393 |
| Scrittura dei soli 3 float d'origine per parte | 2,743 |
| Array letterale `[60,30,10][lod]` per agente (allocazione) | 0,221 |
| GPU viewport con / senza personaggi | 9,482 / 3,875 |

Conclusioni: il costo stava nella preparazione per frame di tutte le parti e nel ricampionamento concentrato nello stesso frame (orologi tutti a 1,0), non nella chiamata MultiMesh. Scrivere 12 float in GDScript costa più di `set_instance_transform`; il buffer conviene solo se quasi tutti i frame scrivono 3 float. Allocazione per frame individuata: l'array letterale per agente. Godot non espone un contatore di allocazioni; si riporta la memoria statica.

### Modifiche applicate

1. **Pose a frequenza per LOD, scaglionate**: 60/30/10 Hz invariati, fase iniziale distribuita per agente, niente picchi. LOD 2 sempre e LOD 1 fuori dalle transizioni: keyframe più vicino della banca condivisa (1/32 di ciclo), senza interpolazione per osso; LOD 2 mostra lo stato dominante durante i blend. LOD 0: interpolazione e blend originali.
2. **Buffer persistenti**: un `PackedFloat32Array` per batch (16 float/istanza; colori scritti solo al rebuild), un `multimesh_set_buffer` per batch e frame. Binding piatti in array tipizzati: niente Dictionary né array letterali per frame.
3. **Aggiornamenti ridondanti eliminati**: aggiornamento completo solo al tick di posa o se l'orientamento devia oltre la tolleranza (0 / 0,05 / 0,15 rad; errore laterale massimo calcolato 0,35 px al LOD 1 e 0,56 px al LOD 2, parte a 0,3 m dall'asse). Altrimenti si scrivono solo le origini, ogni frame, dalla posizione interpolata. Agenti fermi: nessuna scrittura. `bone * local` riutilizzato negli aggiornamenti di solo orientamento.
4. **Parti nascoste**: rimosse solo le parti interamente contenute in una scatola opaca dello stesso osso: 5 dettagli della polizia sotto il gilet, solo LOD 0 (1.000 parti a 600 persone). LOD 1/2 invariati. Nessuna rimozione di parti visibili ai LOD lontani: piedi e arti fanno parte della silhouette e la GPU resta sotto budget al LOD 2.
5. **Batching**: tre batch invariati; upload aggregato al posto di una chiamata per parte.
6. **Interpolazione visiva**: posizione interpolata ogni frame, nessuna riduzione della frequenza di traslazione.

Primo passaggio con tolleranza 0,03/0,05 rad: 800 congestionati a 51,14 FPS, con 589 aggiornamenti completi/frame causati dalla rotazione continua in congestione ([JSON](urban_crowd_3d/renderer_step1.json), [log](urban_crowd_3d/suite_step1.log)). Con 0,05/0,15 rad e cache `bone * local`: 173/frame.

### Prima e dopo, matrice standard

Protocollo della sezione principale: debug standalone, i3-1115G4/UHD, Compatibility, 1152×648, MSAA 4×, limite 60, VSync off, camera size 70, LOD 2, seed 20261112, 4 + 8 s, una ripetizione. Prima: [JSON](urban_crowd_3d/renderer_before.json), [log](urban_crowd_3d/suite_before.log). Dopo: [JSON](urban_crowd_3d/renderer_after.json), [log](urban_crowd_3d/suite_after.log). CPU renderer = adattatore + renderer per frame. GPU = `viewport_get_measured_render_time_gpu`, intero viewport. B/O = bloccati/sovrapposizioni oltre soglia, massimo fra lettura finale e campioni.

| Persone | Scenario | FPS medi | p95 ms | p99 ms | CPU sim ms/tick | CPU renderer ms | GPU ms | Memoria MiB | B/O |
| ---: | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| 100 | Disperso | 60,00 → 60,00 | 19,19 → 17,57 | 19,82 → 17,79 | 0,423 → 0,419 | 1,925 → **0,891** | 3,92 → 5,27 | 71,95 → 70,38 | 0/0 → 0/0 |
| 100 | Congestionato | 60,00 → 60,00 | 19,42 → 17,76 | 20,30 → 18,11 | 0,599 → 0,551 | 2,160 → **0,838** | 5,19 → 5,65 | 72,02 → 70,45 | 0/0 → 0/0 |
| 300 | Disperso | 60,00 → 60,00 | 25,54 → 18,91 | 28,76 → 19,80 | 1,260 → 1,400 | 5,918 → **2,644** | 6,70 → 8,14 | 76,04 → 72,99 | 0/0 → 0/0 |
| 300 | Congestionato | 60,00 → 60,00 | 26,69 → 20,09 | 29,68 → 21,03 | 2,036 → 2,023 | 6,004 → **2,407** | 6,86 → 7,24 | 76,11 → 73,06 | 0/0 → 0/0 |
| 600 | Disperso | 59,14 → **60,00** | 35,14 → 22,16 | 39,84 → 23,72 | 2,898 → 3,091 | 12,539 → **5,351** | 6,91 → 8,14 | 82,14 → 77,02 | 0/0 → 0/0 |
| 600 | Congestionato | 51,21 → **60,00** | 39,64 → 23,80 | 49,76 → 25,48 | 5,630 → 5,093 | 14,401 → **5,055** | 5,86 → 8,24 | 82,20 → 77,09 | 0/0 → 0/0 |
| 800 | Disperso | 43,69 → **60,00** | 44,04 → 23,90 | 47,70 → 25,12 | 4,585 → 5,190 | 18,171 → **7,638** | 6,86 → 9,54 | 86,67 → 80,27 | 0/0 → 0/0 |
| 800 | Congestionato | 35,95 → **59,26** | 50,59 → 26,52 | 57,96 → 29,42 | 7,582 → 9,207 | 19,791 → **8,171** | 7,79 → 9,20 | 86,72 → 80,94 | 0/0 → 0/0 |

800 congestionati, medie (p95): adattatore 1,898 → 2,343 (3,094); pose 6,908 (26,435) → **0,258 (0,388)**; preparazione 5,130 (6,676); upload 0,429 (0,817). Aggiornamenti completi 173/frame, traslazioni 618/frame. 30,07 tick/s, debito massimo 0,033 s; zero posizioni invalide e penetrazioni oltre soglia in tutti i casi.

**60 FPS stabili non confermati**: tutti i p95 restano sopra 16,67 ms (17,57–26,52). Le medie 60,00 sono limitate dal tetto di 60 FPS.

### LOD ravvicinati (solo congestionato)

Stessa suite con `--camera-size=25` (LOD 0) e `40` (LOD 1). Prima = renderer originale ripristinato temporaneamente da `48221f9`, poi rimesso il nuovo (verificato con diff). JSON: `urban_crowd_3d/lod_<legacy|optimized>_size<size>_<persone>.json`.

| Caso | FPS | p95 ms | CPU renderer ms | GPU ms |
| --- | --- | --- | --- | --- |
| LOD 0, 300 | 40,35 → 51,65 | 34,84 → 28,87 | 20,99 → 15,96 | 14,60 → 11,00 |
| LOD 0, 600 | 19,30 → 23,99 | 68,29 → 51,84 | 39,92 → 32,56 | 25,70 → 22,28 |
| LOD 1, 300 | 57,19 → **60,00** | 29,07 → 21,18 | 12,29 → 5,38 | 7,23 → 9,70 |
| LOD 1, 600 | 24,47 → **43,61** | 51,33 → 35,28 | 32,16 → 17,58 | 13,65 → 9,76 |

Le righe LOD 1 "dopo" usano la versione finale (keyframe al LOD 1, aggiunto dopo la matrice standard); il percorso LOD 2 non è cambiato in quel passo, quindi la matrice standard resta valida. A LOD 0 con 600 persone il limite è sia CPU (pose interpolate ~16,7 ms) sia GPU (~22 ms).

### Verifiche

| Verifica | Esito |
| --- | --- |
| Nuovo `tests/presentation/character_renderer_checks.gd` | **42.629 controlli**, PASS: buffer = composizione di riferimento `root * bone * local` ai tre LOD, deriva dell'orientamento entro tolleranza, pose scaglionate, conteggi parti/istanze/buffer, pausa senza scritture, colori. [Log](urban_crowd_3d/character_renderer_checks_after.log). |
| Personaggi esistenti | 6.314 controlli PASS (Idle/Walk/Run/Turn/Stop, transizioni). [Log](urban_crowd_3d/character_checks_after.log). |
| Integrazione | 4.816 controlli PASS, core identico per 960 tick, adattatore in sola lettura. [Log](urban_crowd_3d/urban_crowd_checks_after.log). |
| Core 2D | Runner originale, otto casi 100–1.000: PASS. [Log](urban_crowd_3d/regression_2d_checks_after.log). |
| MCP `60eda448` | 600 congestionati LOD 2; pausa: tick 825 fermo in due letture, 0 traslazioni; ripresa; zoom LOD 0 (16.120 parti) e LOD 1 (12.800); 100 persone LOD 0 con yaw 45° → 135°. Zero errori/warning. [600 LOD 2](urban_crowd_3d/after_congested_600.png), [LOD 0](urban_crowd_3d/after_lod0.png), [LOD 0 dettaglio](urban_crowd_3d/after_lod0_next.png), [LOD 1](urban_crowd_3d/after_lod1.png), [ruotata](urban_crowd_3d/after_rotated_100_lod0.png). |
| MCP `c1386f8e` | LOD 1 finale, 300 persone: [vista](urban_crowd_3d/after_lod1_keyframe_300.png), [dettaglio](urban_crowd_3d/after_lod1_keyframe_crop.png). Zero errori/warning. |
| MCP `ddaa8534` | CharacterShowcase, 240 frame, exit 0, zero errori. |

Negli screenshot civili, manifestanti con zaino e polizia con casco e divisa scura restano distinguibili; nessuna parte staccata. Idle e Turn non compaiono spontaneamente nel benchmark (limite preesistente del core); coperti dal test dei personaggi e dal nuovo test (agenti fermi in rotazione). L'HUD nelle sessioni MCP mostra FPS più bassi della suite: debugger e catture attivi.

### Costi residui e non verificato

- A 800 congestionati il frame con tick somma core (9,2 ms) e renderer (8,2 ms): p95 26,5 ms. Restano preparazione (5,1 ms) e adattatore (2,3 ms, `visual.submit` per agente).
- CPU sim per tick a 800 più alta nella run "dopo" (7,582 → 9,207 congestionato) con codice del core invariato e determinismo verificato. Causa non isolata; ipotesi: frequenza CPU e budget energetico condiviso con la GPU integrata a FPS più alti. Una sola ripetizione per caso.
- GPU viewport più alta a LOD 2 (7,79 → 9,20 ms a 800 congestionati) con le stesse parti; causa non isolata (stessa ipotesi, o upload completo dei buffer). Sotto 16,67 ms.
- Non misurati: build release, sessioni lunghe, picchi di memoria tra i campioni, numero di allocazioni, culling per visibilità ai LOD ravvicinati.
- Cambi visivi accettati: al LOD 2 keyframe senza interpolazione né blend fra stati; al LOD 1 keyframe fuori dalle transizioni; orientamento con ritardo sub-pixel fino al tick di posa successivo.
