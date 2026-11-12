---
name: godot-debugging
description: Riproduce e isola errori di script, stato e collegamento editor/runtime di CivilUnrest in Godot 4.7.2 tramite MCP, con correzioni mirate e regressioni proporzionate.
---

# Debugging Godot

## Classificazione e limiti

Segui AGENTS.md e il rinvio in CLAUDE.md. Una diagnosi richiesta in sola lettura non autorizza correzioni, avvio del gioco o modifiche alla configurazione. Non usare una difficoltà di connessione come motivo per reinstallare MCP, plugin o engine.

1. Chiama prima `godot_status`, poi `godot_project_info`. Registra versione esatta, percorso, addon installato, versione plugin/server, editor_connected, scena attiva e run esistenti. Distingui server MCP raggiungibile, editor connesso e runtime connesso: sono condizioni diverse.
2. Cerca con `rg` messaggio esatto, file e test pertinenti; leggi solo contesto utile. Salva mentalmente o nel rapporto la revisione Git, passaggi, seed, numero di agenti, scenario, tick e comportamento atteso/osservato.
3. Consulta `godot_tools` per schema e disponibilità; per difetti dipendenti da API consulta Context7 secondo AGENTS.md e verifica con `godot_docs_search` / `godot_docs_class` dell'engine 4.7.2. Non applicare sintassi Godot 3 o fix ricavati da altre versioni senza confronto.

## Connessione e prerequisiti

- Se il server non risponde, riporta l'errore di trasporto e distinguilo da un errore nel progetto. Ispeziona solo configurazioni e processi pertinenti in lettura se accessibili; non cambiare porte, percorsi, permessi o firewall.
- Se l'editor è scollegato, confronta percorso atteso/aperto, presenza e abilitazione dell'addon, versione eseguibile e processi. Usa `godot_editor_logs` se disponibile, con limit e livello pertinenti. Un log inaccessibile non prova che sia vuoto. Una possibile causa resta un'ipotesi finché non verificata.
- Se l'editor risponde ma i tool game falliscono, verifica un run effettivamente attivo e il relativo run_id. Non assumere che il bridge runtime sia operativo dalla sola connessione editor. Non abilitare eval o installare addon per aggirare un limite.
- Se manca la scena principale, usa un percorso di scena esistente per una riproduzione autorizzata; altrimenti segnala il prerequisito. Non creare una scena di gioco durante un semplice controllo di connessione.

## Riproduzione e isolamento

1. Per parse/type error usa `godot_script_validate` sul file o `godot_code_diagnostics` sui soli percorsi interessati; se il language server non risponde, dichiaralo e usa il controllo locale supportato. Distingui warning, errore compilazione ed errore runtime.
2. Per runtime avvia la scena esistente con `godot_run_start`, mode process, conservando il run_id. Per errori usa break_on_errors se utile; leggi `godot_run_output` con level error e, quando necessario, errors per backtrace. Leggi anche warning/output pertinenti: nessun errore stampato non dimostra correttezza.
3. Usa `godot_debug_breakpoints`, `godot_debug_state` e `godot_debug_control` per stack, variabili e step in un run process. Descrivi prima lo schema delle azioni; evita evaluate con effetti collaterali. Non confondere la pausa del debugger con lo stato di pausa di gameplay.
4. Usa `godot_game_tree` e `godot_game_get` per confrontare stato atteso e reale, senza presumere nodi per ogni personaggio: gli agenti possono essere array. Riproduci input con `godot_game_input` solo su azioni esistenti, tempi e ordine registrati. Non usare `godot_game_eval` per mascherare uno stato errato.
5. Isola un'ipotesi alla volta: comando/gruppo errato, ordine degli aggiornamenti, indice/id riusato, vicinato obsoleto, destinazione bloccata, valori non finiti o sincronizzazione rendering. Mantieni il caso originale a 1000 agenti se il problema dipende dalla densità; un caso ridotto aiuta l'isolamento ma non sostituisce la regressione originale.
6. Per scatti raccogli dati con `godot_game_perf`; il profiling script è disponibile nei run process e può alterare le prestazioni. Non dedurre una regressione prestazionale dal solo screenshot. Passa a crowd-benchmark quando occorre una misura comparabile o ottimizzazione.

## Correzione, se richiesta

Dichiara causa supportata dall'evidenza, criterio e file da cambiare. Applica il fix minimo; scene/nodi attraverso MCP e salvataggio editor, script attraverso strumenti file. Non disabilitare assertion, ridurre di nascosto gli agenti o sopprimere errori. Una riproduzione dedicata va creata solo se necessaria e nel perimetro autorizzato.

Verifica parser/import e test relativi al codice toccato, poi ripeti il percorso che falliva con gli stessi parametri e controlla i log. Usa `godot_test_run` soltanto se GUT/GdUnit4 è presente; non installare framework per completare la diagnosi. Per CLI/headless verifica argomenti nell'help locale. Ferma solo i run avviati per il compito con `godot_run_stop`; non interrompere quelli dell'utente e non cancellare i suoi breakpoint.

## Rapporto

Riporta riproduzione, evidenza, causa certa o ipotesi, fix/file, test realmente eseguiti, risultato e limite residuo; conserva log utili entro i percorsi autorizzati. Aggiorna progressi/commit secondo AGENTS.md solo per lavoro di modifica autorizzato. Nessuna review generale o scansione di sicurezza implicita. Un controllo headless non è una verifica visiva: usa godot-visual-qa per quella richiesta.
