# Progressi CivilUnrest

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
