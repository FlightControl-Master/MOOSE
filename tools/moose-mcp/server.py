"""Local MCP tools for the MOOSE 2.9.19 F10 and trigger-zone pilot."""

import argparse
import json
import re
from pathlib import Path
from typing import Annotated, Any
from urllib.parse import quote

from mcp.server.fastmcp import FastMCP
from mcp.server.fastmcp.exceptions import ToolError
from mcp.types import ToolAnnotations
from pydantic import Field


ROOT = Path(__file__).resolve().parent
Query = Annotated[str, Field(min_length=1, max_length=200)]
Version = Annotated[str | None, Field(max_length=40)]
READ_ONLY = ToolAnnotations(readOnlyHint=True)


def words(value: str) -> set[str]:
    return set(re.findall(r"[^\W_]+", value.casefold()))


def create_server(port: int = 8765) -> FastMCP:
    catalog = json.loads((ROOT / "catalog-2.9.19.json").read_text(encoding="utf-8"))
    provenance = {"version": catalog["version"], "commit": catalog["commit"]}
    source_base = f"https://github.com/FlightControl-Master/MOOSE/blob/{catalog['commit']}/"
    api = catalog["api"]
    example = catalog["example"]
    example_lua = (ROOT / "examples" / example["file"]).read_text(encoding="utf-8")

    server = FastMCP(
        "MOOSE",
        instructions=(
            "Use search_docs to find MOOSE APIs for F10 Other menus and named trigger zones. "
            "Use get_api for exact signatures and find_example for runnable mission Lua and setup. "
            "Pass the mission's MOOSE version when known. If no version is given, label suggestions "
            "as applying to the returned pilot release. Cite the returned source URLs."
        ),
        host="127.0.0.1",
        port=port,
        stateless_http=True,
        json_response=True,
    )

    def check_version(version: str | None) -> None:
        if version is not None and version.strip() != provenance["version"]:
            raise ToolError(
                f"Unsupported MOOSE version {version!r}. "
                f"The pilot covers {provenance['version']} only."
            )

    def api_summary(symbol: str) -> dict[str, str]:
        entry = api[symbol]
        source_path = quote(f"Moose Development/Moose/{entry['path']}")
        return {
            "symbol": symbol,
            "signature": entry["signature"],
            "summary": entry["summary"],
            "source_url": f"{source_base}{source_path}#L{entry['line']}",
        }

    @server.tool(annotations=READ_ONLY)
    def search_docs(query: Query, version: Version = None) -> dict[str, Any]:
        """Find F10 menu, trigger-zone, group, and message APIs by topic or Lua symbol.

        Pass the installed MOOSE release when known. Omit version to use the pilot release.
        """
        check_version(version)
        query_words = words(query)
        matches = []
        for symbol, entry in api.items():
            symbol_words = words(symbol)
            entry_words = symbol_words | words(f"{entry['summary']} {entry['keywords']}")
            match_count = len(query_words & entry_words)
            if match_count:
                exact = query.strip().casefold() == symbol.casefold()
                symbol_match_count = len(query_words & symbol_words)
                matches.append((not exact, -match_count, -symbol_match_count, symbol))
        matches.sort()

        examples = []
        if query_words & words(f"{example['id']} {example['keywords']}"):
            examples.append({"id": example["id"], "title": example["title"]})
        return {
            **provenance,
            "api": [api_summary(symbol) for _, _, _, symbol in matches[:8]],
            "examples": examples,
        }

    @server.tool(annotations=READ_ONLY)
    def get_api(symbol: Query, version: Version = None) -> dict[str, Any]:
        """Look up a Lua method by exact symbol, for example MENU_GROUP_COMMAND:New.

        The result includes the signature, parameters, return contract, and pinned source link.
        """
        check_version(version)
        symbol = symbol.strip()
        if symbol not in api:
            raise ToolError(f"API symbol {symbol!r} is outside the pilot catalog. Try search_docs.")
        entry = api[symbol]
        return {
            **provenance,
            **api_summary(symbol),
            "parameters": entry["parameters"],
            "returns": entry["returns"],
        }

    @server.tool(annotations=READ_ONLY)
    def find_example(topic: Query, version: Version = None) -> dict[str, Any]:
        """Get the F10 trigger-zone Lua script, Mission Editor setup, and expected results.

        Use f10-trigger-zone or describe the mission-wide group-status command.
        """
        check_version(version)
        if not words(topic) & words(f"{example['id']} {example['keywords']}"):
            raise ToolError("No pilot example matches this topic. Try f10-trigger-zone.")
        return {
            **provenance,
            "id": example["id"],
            "title": example["title"],
            "filename": example["file"],
            "lua": example_lua,
            "setup": example["setup"],
            "expected": example["expected"],
            "api": [api_summary(symbol) for symbol in example["api_symbols"]],
        }

    return server


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--port", type=int, default=8765, help="Loopback HTTP port")
    parser.add_argument(
        "--transport", choices=("streamable-http", "stdio"), default="streamable-http"
    )
    args = parser.parse_args()
    create_server(args.port).run(transport=args.transport)


if __name__ == "__main__":
    main()
