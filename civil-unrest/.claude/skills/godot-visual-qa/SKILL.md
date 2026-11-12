---
name: godot-visual-qa
description: Verifica dal vivo leggibilita tattica, camera, occlusioni e UI di CivilUnrest in Godot 4.7.2 con input e screenshot MCP, incluse folle dense fino a 1000 personaggi.
---

# Verifica visiva Godot

## Ambito e preparazione

Usa per una verifica visiva richiesta o necessaria a una modifica grafica/UI, non per una review automatica di ogni compito. Segui AGENTS.md e il rinvio in CLAUDE.md; un controllo visivo non autorizza redesign, nuova grafica o nuovi sistemi di gioco. Non copiare materiale identificabile di RIOT: Civil Unrest.

1. Chiama `godot_status`, poi `godot_project_info`: verifica Godot 4.7.2, progetto, renderer effettivo, scena eseguibile e input registrati. Cerca con `rg` camera, UI, adapter di rendering, scenari e parametri implementati; leggi solo ciò che serve.
2. Descrivi con `godot_tools` gli schemi di run, screenshot, input e tempo prima di costruire chiamate. Per API Godot consulta Context7 secondo AGENTS.md e verifica dettagli 4.7.2 con `godot_docs_search` / `godot_docs_class` locali.
3. Definisci criteri osservabili, scenario, seed, densità, risoluzione, zoom e momento di cattura. Non inventare selettori di scenario o azioni; se mancano, segnalali senza aggiungerli per completare una checklist.
4. Se manca una scena o un runtime connesso, dichiara che la verifica live è bloccata. Ispezione scene e parse/headless non sostituiscono immagini del gioco. Un editor collegato non dimostra il collegamento al runtime.

## Esecuzione ripetibile

1. Avvia soltanto la scena pertinente con `godot_run_start`, mode process e headless false, e annota run_id. Non interrompere giochi dell'utente. Verifica `godot_run_output` con level error; consulta warning e altri messaggi quando spiegano anomalie visive.
2. Usa `godot_game_tree` / `godot_game_get` per identificare camera, overlay e controlli reali. Non cercare 1000 nodi agente se la rappresentazione usa MultiMesh o array. Usa `godot_scene_tree` per confronto con la scena salvata senza scambiarla per stato runtime.
3. Riproduci pan, zoom e comandi disponibili con `godot_game_input`, ricavando action da inputActions o codice esistente. Registra sequenza, coordinate viewport e tempi; rilascia tasti mantenuti e annota lo stato finale. Non assumere WASD, rotella o selezione se non implementati.
4. Cattura con `godot_game_screenshot`, source game. source editor_2d documenta l'editor e va etichettato separatamente. Ispeziona davvero le immagini restituite: successo del tool non equivale a correttezza visiva.
5. Per confrontare lo stesso istante puoi usare `godot_game_time` per pausa/step, se il runtime lo supporta. La sua pausa sospende il gioco senza modificare SceneTree.paused: non usarla per certificare la pausa di gameplay. Registra tick o stato osservato e limiti di ripetibilità; non presumere che 60 frame corrispondano a 30 tick di simulazione.
6. Salva screenshot con save_to solo nei percorsi del repository autorizzati per il compito; altrimenti usa immagini restituite senza persistenza. Per confronti compare_to richiede una baseline approvata e stesse condizioni. Non sovrascrivere la baseline con il risultato difettoso; differenze pixel non sono da sole una prova di regressione semantica.

## Controlli mirati al simulatore

- **Leggibilità:** civili, manifestanti e polizia distinguibili con la rappresentazione attuale; gruppi e direzione del moto comprensibili a zoom tattico. Se sono placeholder, valuta i placeholder senza richiedere arte rifinita prima del benchmark.
- **Densità:** quando gli scenari esistono, osserva distribuzione dispersa e strettoia a 100/300/500/1000. Controlla passaggio, sovrapposizioni visive, corpi che appaiono attraverso ostacoli, ammassamenti e tremolio. Riporta quanti agenti sono simulati e quanta parte è inquadrata: un contatore non prova 1000 personaggi visibili.
- **Ordinamento:** passaggi davanti/dietro edifici e tra gruppi, continuità tra partizioni del rendering, visibilità ai bordi. Con MultiMesh verifica il culling dell'insieme e l'effetto delle partizioni; non presumere ordinamento individuale automatico o che ogni scomparsa sia un errore AI.
- **Camera:** pan e zoom entro i limiti definiti, coordinate di selezione corrette se esiste selezione, nessun salto al reset e overlay stabile. Confronta zoom minimo, usuale e massimo disponibili senza cambiare configurazioni globali.
- **Animazioni:** se implementate, controlla orientamento, arresto/ripartenza e transizioni; cerca scatti da disallineamento tra tick 30 Hz e presentazione. Non richiedere animazioni assenti.
- **UI italiana:** testo leggibile, nessun taglio o sovrapposizione nei formati supportati, contatori coerenti con lo stato osservabile, nessuna perdita di input causata da overlay. Non cambiare risoluzione o impostazioni di progetto per il test senza necessità autorizzata.

## Esito e confini

Riporta per ogni criterio verificato atteso, osservato, scenario/run, immagine e riproduzione, distinguendo fallimento, successo e non verificabile. Un'immagine ferma non prova fluidità; eventuali misure di `godot_game_perf` sono diagnostiche, non certificano il target release 60 FPS. Usa crowd-benchmark per misure riproducibili su build Windows esportata e godot-debugging per isolare i difetti trovati, senza applicare fix non richiesti.

Ferma con `godot_run_stop` solo i run creati per la verifica. Riporta file eventualmente prodotti, errori di log e blocchi residui. Non creare scene, test, asset o report fuori dal perimetro della richiesta solo per completare la QA.
