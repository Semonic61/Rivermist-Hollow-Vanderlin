"""Read-only navigation checks; --inventory prints static direct-include facts.

This is a lexical source audit, not DreamChecker, preprocessing, or a runtime test.
Run from the repository root: python -B ai_navigation/validate_navigation.py [--inventory]
"""
import argparse
import collections
import json
import pathlib
import re

MACROS = {
    "SUBSYSTEM_DEF": ("standard", ""),
    "PROCESSING_SUBSYSTEM_DEF": ("processing", "processing/"),
    "TIMER_SUBSYSTEM_DEF": ("timer", "timer/"),
    "MOVEMENT_SUBSYSTEM_DEF": ("movement", "movement/"),
    "AI_CONTROLLER_SUBSYSTEM_DEF": ("ai-controller", "ai_controllers/"),
    "VERB_MANAGER_SUBSYSTEM_DEF": ("verb-manager", "verb_manager/"),
}
MACRO_RE = re.compile(r"^(" + "|".join(MACROS) + r")\((\w+)\)", re.M)
BACKTICK = re.compile(r"`([^`\n]+)`")


def inventory(root):
    dme = (root / "vanderlin.dme").read_text(encoding="utf-8")
    includes = [p.replace("\\", "/") for p in re.findall(r'^#include\s+"([^"]+)"', dme, re.M)]
    sources = {p: (root / p).read_text(encoding="utf-8", errors="replace")
               for p in sorted(set(includes)) if p.endswith(".dm") and (root / p).is_file()}
    subsystems = []
    defines = collections.defaultdict(list)
    for path, text in sources.items():
        for match in MACRO_RE.finditer(text):
            macro, name = match.groups()
            kind, parent = MACROS[macro]
            subsystems.append({"name": name, "global": "SS" + name, "macro": macro,
                               "kind": kind, "type": "/datum/controller/subsystem/" + parent + name,
                               "file": path, "line": text[:match.start()].count("\n") + 1})
        for match in re.finditer(r"^[ \t]*#define[ \t]+(COMSIG_\w+)", text, re.M):
            defines[match[1]].append(path)
    call_counts = {symbol: sum(len(re.findall(r"\b" + symbol + r"\s*\(", text))
                              for text in sources.values())
                   for symbol in ("SEND_SIGNAL", "SEND_GLOBAL_SIGNAL", "RegisterSignal",
                                  "UnregisterSignal", "AddComponent", "apply_status_effect")}
    return {"include_count": len(includes), "direct_dm_files": len(sources),
            "missing_includes": [p for p in includes if not (root / p).is_file()],
            "subsystems": sorted(subsystems, key=lambda item: item["global"]),
            "macro_counts": dict(collections.Counter(s["macro"] for s in subsystems)),
            "signal_definitions": dict(sorted(defines.items())),
            "call_counts": call_counts,
            "modular_includes": {name: sum(p.startswith(name + "/") for p in includes)
                                for name in ("modular_alizeria", "modular_ratwood", "modular_rmh")}}, sources


def resolves(root, token):
    token = re.sub(r":[0-9]+(?:[-,:][0-9]+)*$", "", token.replace("\\", "/"))
    if any(c in token for c in "*?"):
        return any(root.glob(token))
    return (root / token).exists()


def source_paths(cell):
    for token in BACKTICK.findall(cell):
        if token.startswith(("ai_navigation/", "code/", "modular_", "_maps/", "tgui/", "interface/")):
            yield token


def validate(root, data):
    nav = root / "ai_navigation"
    errors = []
    links = 0
    for doc in list(nav.rglob("*.md")) + list((root / ".agents/skills/rivermist-hollow").rglob("*.md")):
        text = doc.read_text(encoding="utf-8")
        for link in re.findall(r"\[[^\]]+\]\(([^)]+)\)", text):
            if re.match(r"[a-z][a-z0-9+.-]*:", link, re.I) or link.startswith("#"):
                continue
            raw = link.split("#", 1)[0].split("?", 1)[0].strip("<>")
            target = (doc.parent / raw).resolve()
            if not target.is_relative_to(root) or not target.exists():
                errors.append(f"{doc.relative_to(root)}: missing link {link}")
            links += 1
    route_count = 0
    entry_count = 0
    for name, open_first in (("router.md", False), ("entrypoints.md", True)):
        for line in (nav / name).read_text(encoding="utf-8").splitlines():
            if not line.startswith("|"):
                continue
            cells = line.split("|")
            selected = cells[2] if open_first and len(cells) > 3 else line
            for token in source_paths(selected):
                if not resolves(root, token):
                    errors.append(f"{name}: missing route {token}")
                if open_first:
                    entry_count += 1
                else:
                    route_count += 1
    actual = {s["global"]: s for s in data["subsystems"]}
    documented = {}
    for line in (nav / "subsystem_map.md").read_text(encoding="utf-8").splitlines():
        cells = [cell.strip().strip("`") for cell in line.strip("|").split("|")]
        if len(cells) == 6 and cells[0] in actual:
            documented[cells[0]] = cells
        elif len(cells) == 6 and re.fullmatch(r"SS\w+", cells[0]):
            errors.append(f"subsystem_map.md: undeclared subsystem {cells[0]}")
    for name, source in actual.items():
        row = documented.get(name)
        if not row:
            errors.append(f"subsystem_map.md: missing {name}")
        elif row[1] != source["kind"] or row[3] != source["type"] or row[5] != source["file"]:
            errors.append(f"subsystem_map.md: wrong declaration mapping for {name}")
    for filename in ("architecture.md", "system_map.md", "entrypoints.md",
                     "runtime_flow.md", "system_dependencies.md"):
        content = (nav / filename).read_text(encoding="utf-8")
        for name in sorted(set(re.findall(r"\bSS[A-Za-z_]\w*", content))):
            if name not in actual and not name.startswith("SS_") and name != "SS13":
                errors.append(f"{filename}: undeclared owner {name}")
    known_defines = set(data["signal_definitions"])
    for name in ("signal_map.md", "combat_signal_map.md", "movement_signal_map.md", "spell_signal_map.md"):
        text = (nav / name).read_text(encoding="utf-8")
        for symbol in set(re.findall(r"\bCOMSIG_[A-Z0-9_]+", text)):
            if symbol.endswith("_"):
                continue
            if symbol not in known_defines:
                errors.append(f"{name}: unknown COMSIG definition {symbol}")
    return {"markdown_links_checked": links, "router_targets_checked": route_count,
            "entrypoint_open_first_checked": entry_count,
            "subsystem_declarations_checked": len(actual), "errors": sorted(set(errors))}


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--inventory", action="store_true")
    args = parser.parse_args()
    root = pathlib.Path(__file__).resolve().parents[1]
    data, unused_sources = inventory(root)
    if args.inventory:
        print(json.dumps(data, indent=2))
        return 0
    result = validate(root, data)
    result["errors"].extend("vanderlin.dme: missing include " + p for p in data["missing_includes"])
    print(json.dumps(result, indent=2))
    return bool(result["errors"])


if __name__ == "__main__":
    raise SystemExit(main())
