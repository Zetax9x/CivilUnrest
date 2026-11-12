# Godot AI starter — setup notes

1. Install Godot 4.7.2 Standard (not .NET), Node.js 22+, Git, Codex CLI, Claude Code on Windows.
2. Make a Godot project and put AGENTS.md and CLAUDE.md next to project.godot.
3. Copy the two hidden skill folders too (`.agents` and `.claude`).
4. Run from the project directory:
   npx -y @shin2344234/godot-mcp init --agents claude-code,codex --dry-run
5. Review the proposed changes. Then run:
   npx -y @shin2344234/godot-mcp init --agents claude-code,codex
6. Verify that Godot has the addon enabled and open the project. Restart agent sessions.
7. In Codex: `codex mcp list` and ask to call `godot_status`.
8. In Claude Code: `claude mcp list`, `/mcp`, then ask to call `godot_status`.
9. If `GODOT_PATH` detection fails, point configs to the main Godot .exe, not the `_console.exe` launcher.
10. This pack is NOT a full game; it contains project rules and a benchmark skill.

WARNING: `init` may modify AGENTS.md/CLAUDE.md; keep the supplied files and inspect the diff after setup. Do not run the installer again with different project folder paths without reviewing configs.
