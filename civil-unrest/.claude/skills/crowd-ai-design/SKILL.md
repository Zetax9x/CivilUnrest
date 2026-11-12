---
name: crowd-ai-design
description: Progetta comportamenti sistemici, gerarchie e scenari deterministici delle folle di CivilUnrest in Godot 4.7.2, fino a 1000 personaggi. Usa per decisioni AI e relativi criteri di accettazione.
---

# Progettazione AI delle folle

## Ambito e avvio

Progetta solo i comportamenti richiesti. Una richiesta di design produce specifiche, non autorizza implementazione, combattimento o nuova grafica. Segui AGENTS.md; CLAUDE.md rimanda alle stesse regole. Mantieni spiegazioni e UI in italiano, simboli e file in inglese.

1. Cerca con `rg` gli stati, i sistemi AI, le configurazioni e i test esistenti; leggi solo le parti pertinenti. Distingui funzionalità implementate da proposte.
2. Chiama `godot_status`, poi `godot_project_info`: verifica versione 4.7.2 Standard, progetto, addon, editor e scena. Se manca una scena, limita l'analisi ai materiali disponibili.
3. Usa `godot_tools` per cercare operazioni e descriverne gli schemi prima di invocarle. Per API Godot consulta Context7 secondo AGENTS.md e confronta con `godot_docs_search` / `godot_docs_class` dell'engine installato; non presentare documentazione generica 4.7 come prova di una firma 4.7.2.

## Procedura di design

1. Esplicita obiettivo osservabile, input dello scenario, seed, numero di personaggi e condizioni di riuscita/fallimento. Non assumere che tre fazioni implichino tre comportamenti uniformi: distingui civili, manifestanti e polizia, gruppi e individui.
2. Dividi le decisioni su tre livelli: fazione assegna obiettivi e priorità; folla/squadra sceglie percorso condiviso, coesione e comando; individuo gestisce destinazione locale, separazione e reazioni. Per ogni livello specifica input, output, frequenza, proprietario dello stato e priorità tra ordini concorrenti.
3. Definisci solo gli stati necessari al compito. Descrivi per ciascuno condizioni di ingresso/uscita, timeout, isteresi e interruzioni. Esempi da valutare, non funzionalità già presenti: attesa, movimento, ricompattamento, fuga. Evita oscillazioni continue tra stati e decisioni casuali a ogni frame.
4. Specifica dati per indice/id stabile: gruppo, posizione, velocità, obiettivo, comportamento e, quando richiesti, morale, paura e fatica. Definisci intervalli, saturazione, unità e responsabilità degli aggiornamenti. Se proponi paura/panico, usa propagazione locale con soglie e recupero espliciti; non aggiungere questi sistemi prima del benchmark senza autorizzazione.
5. Pianifica simulazione iniziale a 30 Hz, separata dalla presentazione. Scagliona le decisioni individuali e aggiorna quelle di gruppo meno spesso; indica frequenze come ipotesi da misurare, non risultati acquisiti.
6. Usa interrogazioni di vicinato con griglia spaziale. Specifica raggio, dimensione celle, frequenza di ricostruzione e gestione della densità. Evita ricerca globale O(N²); segnala che celle molto affollate possono comunque degradare. Non troncare vicini in modo invisibile: esplicita eventuali limiti e loro effetti.
7. Separa scelta del percorso da steering e repulsione. Prevedi strettoie, obiettivo irraggiungibile, stallo e recupero senza teletrasporto. Non assegnare per default 1000 operazioni di avoidance di NavigationAgent2D; usa percorsi di gruppo o dati condivisi compatibili con la mappa esistente.
8. Per riproducibilità definisci sorgente casuale con seed, ordine stabile delle iterazioni e dei comandi, tick iniziale e parametri. Non promettere determinismo bit-per-bit tra piattaforme senza evidenza.

## Criteri verificabili

- Movimento: avanzamento verso obiettivi raggiungibili, valori finiti, velocità entro limiti e nessun attraversamento delle zone bloccate secondo la rappresentazione implementata.
- Densità: separazione e sovrapposizione quantificate con tolleranze dichiarate, transito nella strettoia e rilevamento degli stalli. Non promettere assenza assoluta di sovrapposizioni con semplice steering.
- Gerarchia: ordini di squadra coerenti, reazioni locali senza perdita permanente del gruppo e priorità esplicite per la fuga, se implementata.
- Regressione: stesso seed e sequenza comandi, confronto di invarianti ai tick stabiliti; test solo per i comportamenti toccati. Prevedi copertura futura 100/300/500/1000 in movimento disperso e strettoia senza avviare automaticamente una campagna prestazionale.

## Evidenza e confini

Per ispezionare un comportamento già esistente usa `godot_scene_tree` e, solo con runtime connesso, `godot_game_tree` / `godot_game_get`; i dati in array non corrispondono necessariamente a nodi individuali. `godot_game_input` può riprodurre comandi realmente esposti dal progetto: non inventare input o metodi.

Consegna modello di stati, contratti tra livelli, parametri proposti, rischi e criteri di accettazione. Per responsabilità dei moduli usa godot-architecture; per un difetto riproducibile godot-debugging; per misure e ottimizzazioni usa crowd-benchmark, senza duplicarne la metodologia. Non dichiarare 60 FPS raggiunti dal solo design.
