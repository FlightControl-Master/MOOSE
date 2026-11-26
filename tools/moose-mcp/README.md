# MOOSE MCP pilot

This local server exposes a curated API catalog for MOOSE 2.9.19
(`ba6091d028a7b9589e051bc59df0ced5739378b4`). It uses the official Python MCP SDK and serves
read-only tools for F10 Other menus, named trigger zones, and related group and message methods.
Each API result includes a link to the pinned MOOSE source.

## Start the server

From the MOOSE checkout on Windows, run these commands with Python 3.10 or newer.

```powershell
python -m venv tmp/moose-mcp-venv
& .\tmp\moose-mcp-venv\Scripts\python.exe -m pip install -r tools/moose-mcp/requirements.txt
& .\tmp\moose-mcp-venv\Scripts\python.exe -B tools/moose-mcp/server.py
```

The server listens at `http://127.0.0.1:8765/mcp`. Keep the process running while using the
HTTP connection. Use `--port` to select a different local port.

## Connect Codex

In Codex settings, add a Streamable HTTP MCP server named `moose` with that URL. The CLI
equivalent is below. Start a new Codex session after adding the server.

```powershell
codex mcp add moose --url http://127.0.0.1:8765/mcp
```

For a one-off test, pass the connection on the command line.

```powershell
codex exec -c "mcp_servers.moose.url='http://127.0.0.1:8765/mcp'" 'Call the MOOSE get_api tool for MENU_GROUP_COMMAND:New in version 2.9.19. Show the signature and pinned source link.'
```

To let an MCP client launch the process itself, configure its stdio command to use the
virtual environment's Python interpreter and pass the absolute path to `server.py` with
`--transport stdio`.

The `search_docs` tool searches by topic, `get_api` resolves an exact Lua method name,
and `find_example` returns the full Lua source and mission setup. Each accepts an optional
`version` argument, which selects the pilot release when omitted. An unsupported version
returns an error with the supported release.

## Try the example in DCS

1. Create a circular trigger zone named `LZ Alpha` and a group named `Training Flight`.
   Arrange for at least one group unit to cross the zone boundary during the mission.
2. Add a player slot. In a mission-start trigger, load the MOOSE 2.9.19 `Moose.lua` via
   **Do Script File**, followed by [f10-trigger-zone.lua](examples/f10-trigger-zone.lua)
   via another **Do Script File** action.
3. Enter the slot and select **F10 Other → Training → Check LZ Alpha**. The mission-wide
   message reports whether any unit of the named group is inside the zone. Check again
   when all units are outside. An unavailable group gets a separate message.
4. To exercise a setup error, rename the zone in the Mission Editor and start the mission
   again. MOOSE logs the missing zone and the script skips menu registration.

To retrieve the same script through MCP, ask Codex to call `find_example` with
`topic="f10-trigger-zone"` and `version="2.9.19"`.
