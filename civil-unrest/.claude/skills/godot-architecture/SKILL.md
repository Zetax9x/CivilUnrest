---
name: godot-architecture
description: Definisce o evolve moduli, dati, tick di simulazione e rendering di CivilUnrest in Godot 4.7.2 Standard con GDScript tipizzato, per folle fino a 1000 personaggi.
---

# Architettura Godot del simulatore

## Ambito e ricognizione

Segui AGENTS.md e il rinvio contenuto in CLAUDE.md. Proponi o realizza solo la modifica architetturale richiesta; una richiesta di analisi non autorizza scaffolding o riscritture. Mantieni file e simboli in inglese, spiegazioni e UI in italiano.

1. Chiama `godot_status`, poi `godot_project_info`. Verifica progetto, Godot 4.7.2 Standard, renderer effettivo, scena principale, autoload e input; non ricavare dipendenze dalla sola struttura desiderata.
2. Cerca con `rg` i moduli, scene, documentazione e test coinvolti, controlla Git e leggi solo le sezioni utili. Usa `godot_scene_tree`, `godot_node_get`, `godot_code_symbols` o `godot_resource_deps` per chiarire dipendenze reali. Mantieni funzionanti le interfacce esistenti.
3. Verifica schemi con `godot_tools`. Per API o configurazione consulta Context7 secondo AGENTS.md e la documentazione locale con `godot_docs_search` / `godot_docs_class`; la documentazione dell'engine installato serve a verificare i dettagli 4.7.2. Non inventare proprietà o metodi.

## Decisioni da esplicitare

- **Dati di simulazione:** collezioni tipizzate o packed arrays coerenti con i dati, id stabili e mappatura id/indice esplicita. Definisci proprietà, creazione/rimozione e riuso degli slot; evita riferimenti a Node nel nucleo quando non necessari. Un migliaio di attori non richiede un migliaio di alberi complessi.
- **Tick:** frequenza configurabile iniziale 30 Hz e ordine dei sistemi dichiarato. Se usi accumulatore, definisci numero massimo di recuperi e trattamento del tempo residuo, senza perdere tempo di simulazione silenziosamente. Non modificare impostazioni globali di fisica per comodità senza valutarne i consumatori.
- **Presentazione:** snapshot precedente/corrente e interpolazione separati dalle decisioni AI; chiarisci come spawn, rimozioni e reset evitano interpolazioni spurie. La camera e la UI inviano comandi, non modificano direttamente gli array durante un aggiornamento.
- **Vicinato e navigazione:** griglia spaziale condivisa, interrogazioni locali e percorsi di gruppo. Documenta quando si aggiorna la griglia rispetto al movimento, come tratta confini e ostacoli e quale sistema risolve repulsione e stallo. Nessun all-to-all o avoidance costosa per ogni attore per default.
- **AI:** contratti fazione -> folla/squadra -> individuo con frequenze scaglionate. Rimanda a crowd-ai-design per transizioni e comportamento; non incorporare logiche di missione nella mappa di test.
- **Eventi:** coda di comandi con ordine stabile e momento di applicazione definito; eventi aggregati per UI e diagnostica. Evita migliaia di segnali per frame e autoload usati come contenitori universali.
- **Rendering:** confronta adapter Sprite2D/atlas e MultiMeshInstance2D con carico equivalente. Il culling del MultiMesh riguarda l'insieme, non ogni istanza; valuta partizioni spaziali. Verifica ordinamento, occlusione con edifici, animazioni e costi di aggiornamento, senza assumere batching o ordinamento individuale automatici.
- **Evoluzione:** mantieni GDScript tipizzato e Godot Standard; C++, GDExtension e C# richiedono prima un collo di bottiglia misurato e una decisione motivata. Non introdurre thread o plugin come scorciatoia non richiesta.

Per ogni interfaccia proposta scrivi dati in ingresso/uscita, proprietario, fase del tick, dipendenze consentite e invarianti. Adatta scripts/simulation, scripts/ai, scripts/navigation, scripts/rendering e scripts/ui all'organizzazione reale senza creare cartelle vuote solo per aderire al modello.

## Quando è richiesta implementazione

1. Dichiara criterio di accettazione e file attesi prima del piccolo intervento. Individua un unico writer; non avviare altri agenti automaticamente.
2. Modifica scene mediante strumenti scene/nodi MCP, mai riscrivendo a mano i .tscn; salva con `godot_scene_save` se lavori nell'editor. Modifica script con `godot_files_edit` / `godot_files_write` e verifica i file interessati con `godot_script_validate` o `godot_code_diagnostics`.
3. Esegui controlli CLI/headless pertinenti con l'eseguibile rilevato e argomenti verificati tramite il suo help. Usa test esistenti; `godot_test_run` richiede GUT o GdUnit4 rilevato, non installarlo automaticamente. Un parse corretto non prova la correttezza del contratto tra sistemi.
4. Esegui la scena interessata con `godot_run_start` in mode process, leggi `godot_run_output` con level error e verifica gli invarianti modificati. Se manca una scena eseguibile, segnala il limite senza creare un prototipo estraneo al compito.
5. Documenta e committa soltanto i cambiamenti del compito secondo AGENTS.md e le istruzioni correnti. Non modificare .godot, addon, project.godot o altri file estranei per far riuscire una verifica.

## Consegna e confini

Riporta responsabilità dei moduli, flusso dati/tick, scelta e alternativa scartata con motivazione concreta, file cambiati, controlli eseguiti e limiti. Esegui solo le verifiche proporzionate alla modifica. Per validazione dell'immagine usa godot-visual-qa; crowd-benchmark resta la fonte operativa per benchmark 100/300/500/1000 e prestazioni Windows esportate. 60 FPS è un obiettivo da misurare.
