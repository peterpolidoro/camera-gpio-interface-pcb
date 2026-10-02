KICAD_CONFIG_HOME := $(CURDIR)/.guix/.config/kicad
KICAD_CONFIG_DIR := $(KICAD_CONFIG_HOME)/10.0
KICAD_COMMON_JSON := $(KICAD_CONFIG_DIR)/kicad_common.json
XDG_CACHE_HOME := /tmp/codex-kicad-cache
GUIX_TIME_MACHINE = guix time-machine -C .guix/channels.scm
GUIX_MANIFEST_AGENT ?= .guix/manifest-agent.scm
GUIX_MANIFEST_KICAD ?= .guix/manifest-kicad.scm
GUIX_MANIFEST_FREECAD ?= .guix/manifest-freecad.scm
GUIX_SHELL_EXTRA_OPTIONS ?=
GUIX_SHELL_AGENT = $(GUIX_TIME_MACHINE) -- shell $(GUIX_SHELL_EXTRA_OPTIONS) --pure -m $(GUIX_MANIFEST_AGENT)
GUIX_SHELL_KICAD = $(GUIX_TIME_MACHINE) -- shell $(GUIX_SHELL_EXTRA_OPTIONS) --pure -m $(GUIX_MANIFEST_KICAD)
GUIX_SHELL_FREECAD = $(GUIX_TIME_MACHINE) -- shell $(GUIX_SHELL_EXTRA_OPTIONS) --pure -m $(GUIX_MANIFEST_FREECAD)
GUIX_SHELL = $(GUIX_SHELL_AGENT)

ORB_WEAVER_KICAD_LIBS_CHECKOUT ?= $(firstword $(wildcard $(abspath ../kicad-libs) $(abspath ../orb-weaver-kicad-libs)))
ORB_WEAVER_KICAD_LIBS ?= $(if $(and $(ORB_WEAVER_KICAD_LIBS_CHECKOUT),$(wildcard $(ORB_WEAVER_KICAD_LIBS_CHECKOUT)/kicad/db-libraries/orb_weaver_internal.kicad_dbl)),$(ORB_WEAVER_KICAD_LIBS_CHECKOUT),)
ORB_WEAVER_KICAD_LIBS_AUTO_BUILD ?= 0
GUIX_AGENT_TOOLS_CHECKOUT ?= $(abspath ../guix-agent-tools)
CODEX_GUIX_SHELL ?= $(if $(wildcard $(GUIX_AGENT_TOOLS_CHECKOUT)/bin/codex-guix-shell),$(GUIX_AGENT_TOOLS_CHECKOUT)/bin/codex-guix-shell,codex-guix-shell)
CLAUDE_GUIX_SHELL ?= $(if $(wildcard $(GUIX_AGENT_TOOLS_CHECKOUT)/bin/claude-guix-shell),$(GUIX_AGENT_TOOLS_CHECKOUT)/bin/claude-guix-shell,claude-guix-shell)
BOARD_INTERFACES_CHECKOUT ?= $(abspath ../board-interfaces)
ORB_WEAVER_CONTEXT_CHECKOUT ?= $(abspath ../orb-weaver-context)
MOUSE_JOYSTICK_PCB_CHECKOUT ?= $(abspath ../mouse-joystick-pcb)
LA5032_ADAPTER_CHECKOUT ?= $(abspath ../la5032-instrument-port-adapter)
JOYSTICK_RIG_CHECKOUT ?= $(abspath ../../github/joystick-rig)
PYCONTROL_H7_BREAKOUT_CHECKOUT ?= $(abspath ../../github/pycontrol-h7-breakout)
AGENT_MEMORY_REPO_CHECKOUT ?= $(abspath ../agent-memory)
AGENT_MEMORY_ENV = $(if $(wildcard $(AGENT_MEMORY_REPO_CHECKOUT)/AGENTS.md),GUIX_AGENT_TOOLS_MEMORY_REPO=$(AGENT_MEMORY_REPO_CHECKOUT),)
AGENT_EXTRA_DIRS ?=
PROJECT ?= $(firstword $(wildcard kicad/*.kicad_pro *.kicad_pro examples/*/*.kicad_pro))
FAB_TOOL ?= $(if $(wildcard $(ORB_WEAVER_KICAD_LIBS_CHECKOUT)/bin/orb-weaver-kicad-fab),$(ORB_WEAVER_KICAD_LIBS_CHECKOUT)/bin/orb-weaver-kicad-fab,orb-weaver-kicad-fab)
FAB_OUTPUT_DIR ?= $(if $(PROJECT),fab/$(basename $(notdir $(PROJECT))),fab)
FAB_OPTIONS ?=
# Prefer an editable kicad-libs checkout, the way the library path already does.
# The packaged command only appears once .guix/channels.scm is bumped to a
# kicad-libs commit that carries it.
DOCS_TOOL ?= $(if $(wildcard $(ORB_WEAVER_KICAD_LIBS_CHECKOUT)/bin/orb-weaver-kicad-docs),$(ORB_WEAVER_KICAD_LIBS_CHECKOUT)/bin/orb-weaver-kicad-docs,orb-weaver-kicad-docs)
DOCS_OUTPUT_DIR ?= docs/generated
DOCS_OPTIONS ?=
# Routing helpers from kicad-libs (bin/orb-weaver-kicad-*). Like DOCS_TOOL they
# prefer the sibling checkout; the packaged commands appear once the channel pin
# carries a kicad-libs commit that ships them. See kicad-libs
# docs/freerouting-autorouting.md for the routing workflow.
EXPORT_DSN_TOOL ?= $(if $(wildcard $(ORB_WEAVER_KICAD_LIBS_CHECKOUT)/bin/orb-weaver-kicad-export-dsn),$(ORB_WEAVER_KICAD_LIBS_CHECKOUT)/bin/orb-weaver-kicad-export-dsn,orb-weaver-kicad-export-dsn)
IMPORT_SES_TOOL ?= $(if $(wildcard $(ORB_WEAVER_KICAD_LIBS_CHECKOUT)/bin/orb-weaver-kicad-import-ses),$(ORB_WEAVER_KICAD_LIBS_CHECKOUT)/bin/orb-weaver-kicad-import-ses,orb-weaver-kicad-import-ses)
CLEARANCE_CHECK_TOOL ?= $(if $(wildcard $(ORB_WEAVER_KICAD_LIBS_CHECKOUT)/bin/orb-weaver-kicad-clearance-check),$(ORB_WEAVER_KICAD_LIBS_CHECKOUT)/bin/orb-weaver-kicad-clearance-check,orb-weaver-kicad-clearance-check)
DSN ?= fab/autoroute/$(basename $(notdir $(PROJECT))).dsn
SES ?= fab/autoroute/$(basename $(notdir $(PROJECT))).ses
EXPORT_DSN_OPTIONS ?=
IMPORT_SES_OPTIONS ?=
CLEARANCE_CHECK_OPTIONS ?=

# Design-block tools from kicad-libs (bin/orb-weaver-kicad-*), preferring the sibling checkout like DOCS_TOOL.
MECHANICAL_DATUMS_TOOL ?= $(if $(wildcard $(ORB_WEAVER_KICAD_LIBS_CHECKOUT)/bin/orb-weaver-kicad-mechanical-datums),$(ORB_WEAVER_KICAD_LIBS_CHECKOUT)/bin/orb-weaver-kicad-mechanical-datums,orb-weaver-kicad-mechanical-datums)
MECHANICAL_DATUMS ?= docs/generated/mechanical-datums.json
MECHANICAL_DATUMS_OPTIONS ?=
PLACE_BLOCK_TOOL ?= $(if $(wildcard $(ORB_WEAVER_KICAD_LIBS_CHECKOUT)/bin/orb-weaver-kicad-place-block),$(ORB_WEAVER_KICAD_LIBS_CHECKOUT)/bin/orb-weaver-kicad-place-block,orb-weaver-kicad-place-block)
PLACE_BLOCK_OPTIONS ?=
BLOCK_SPACING_TOOL ?= $(if $(wildcard $(ORB_WEAVER_KICAD_LIBS_CHECKOUT)/bin/orb-weaver-kicad-block-spacing),$(ORB_WEAVER_KICAD_LIBS_CHECKOUT)/bin/orb-weaver-kicad-block-spacing,orb-weaver-kicad-block-spacing)
BLOCK_SPACING_OPTIONS ?=
SHEET_PINS_TOOL ?= $(if $(wildcard $(ORB_WEAVER_KICAD_LIBS_CHECKOUT)/bin/orb-weaver-kicad-sheet-pins),$(ORB_WEAVER_KICAD_LIBS_CHECKOUT)/bin/orb-weaver-kicad-sheet-pins,orb-weaver-kicad-sheet-pins)
SHEET_PINS_OPTIONS ?=
BOARD_MANIFEST_TOOL ?= $(if $(wildcard $(ORB_WEAVER_KICAD_LIBS_CHECKOUT)/bin/orb-weaver-kicad-board-manifest),$(ORB_WEAVER_KICAD_LIBS_CHECKOUT)/bin/orb-weaver-kicad-board-manifest,orb-weaver-kicad-board-manifest)
BOARD_MANIFEST ?= kicad/board-manifest.yaml
BOARD_MANIFEST_MAP ?= docs/interface-map.md
BOARD_MANIFEST_OPTIONS ?=
COMPOSE_TOOL ?= $(if $(wildcard $(ORB_WEAVER_KICAD_LIBS_CHECKOUT)/bin/orb-weaver-kicad-compose),$(ORB_WEAVER_KICAD_LIBS_CHECKOUT)/bin/orb-weaver-kicad-compose,orb-weaver-kicad-compose)
COMPOSE_OPTIONS ?=
BOARD_SOURCE_TOOL ?= $(if $(wildcard $(ORB_WEAVER_KICAD_LIBS_CHECKOUT)/bin/orb-weaver-kicad-board-source),$(ORB_WEAVER_KICAD_LIBS_CHECKOUT)/bin/orb-weaver-kicad-board-source,orb-weaver-kicad-board-source)
BOARD_SOURCE ?= kicad/board.yaml
BOARD_SOURCE_OPTIONS ?=
REFRESH_BLOCK_TOOL ?= $(if $(wildcard $(ORB_WEAVER_KICAD_LIBS_CHECKOUT)/bin/orb-weaver-kicad-refresh-block),$(ORB_WEAVER_KICAD_LIBS_CHECKOUT)/bin/orb-weaver-kicad-refresh-block,orb-weaver-kicad-refresh-block)
REFRESH_BLOCK_OPTIONS ?=

MANAGED_ENV = KICAD_CONFIG_HOME=$(KICAD_CONFIG_HOME) XDG_CACHE_HOME=$(XDG_CACHE_HOME) $(if $(ORB_WEAVER_KICAD_LIBS),ORB_WEAVER_KICAD_LIBS=$(ORB_WEAVER_KICAD_LIBS))
TLS_ENV = export SSL_CERT_FILE="$${GUIX_ENVIRONMENT}/etc/ssl/certs/ca-certificates.crt"; export GIT_SSL_CAINFO="$$SSL_CERT_FILE"; export CURL_CA_BUNDLE="$$SSL_CERT_FILE"; export SSL_CERT_DIR="$${GUIX_ENVIRONMENT}/etc/ssl/certs"; exec "$$@"
AGENT_MANAGED_SHELL = $(MANAGED_ENV) $(GUIX_SHELL_AGENT) -E "^KICAD_CONFIG_HOME$$" -E "^XDG_CACHE_HOME$$" -E "^ORB_WEAVER_KICAD_LIBS$$" -- sh -c '$(TLS_ENV)' sh
KICAD_MANAGED_SHELL = $(MANAGED_ENV) $(GUIX_SHELL_KICAD) -E "^KICAD_CONFIG_HOME$$" -E "^XDG_CACHE_HOME$$" -E "^ORB_WEAVER_KICAD_LIBS$$" -- sh -c '$(TLS_ENV)' sh
FREECAD_MANAGED_SHELL = $(MANAGED_ENV) $(GUIX_SHELL_FREECAD) -E "^KICAD_CONFIG_HOME$$" -E "^XDG_CACHE_HOME$$" -E "^ORB_WEAVER_KICAD_LIBS$$" -- sh -c '$(TLS_ENV)' sh
MANAGED_SHELL = $(AGENT_MANAGED_SHELL)

LIBS_WORKSPACE := $(if $(wildcard $(ORB_WEAVER_KICAD_LIBS_CHECKOUT)),$(ORB_WEAVER_KICAD_LIBS_CHECKOUT),$(ORB_WEAVER_KICAD_LIBS))
PCB_AGENT_EXTRA_DIRS ?= $(BOARD_INTERFACES_CHECKOUT) $(ORB_WEAVER_CONTEXT_CHECKOUT) $(GUIX_AGENT_TOOLS_CHECKOUT) $(MOUSE_JOYSTICK_PCB_CHECKOUT) $(LA5032_ADAPTER_CHECKOUT) $(JOYSTICK_RIG_CHECKOUT) $(PYCONTROL_H7_BREAKOUT_CHECKOUT) $(if $(LIBS_WORKSPACE),$(LIBS_WORKSPACE)) $(if $(wildcard $(AGENT_MEMORY_REPO_CHECKOUT)/AGENTS.md),$(AGENT_MEMORY_REPO_CHECKOUT))

.PHONY: mechanical-datums board-manifest-derive board-manifest-check board-manifest-render sheet-pins compose compose-check expand expand-check refresh-block place-block block-spacing docs docs-check help test prepare-kicad-config check-kicad-libs shell kicad-shell kicad-version agent-reflection codex claude agent-project agent-libs agent-both agent-edits kicad-edits freecad-edits validate-db fab export-dsn freeroute import-ses clearance-baseline clearance-check

help:
	@printf '%s\n' \
	  'make test              Check repository guidance and key planning docs exist' \
	  'make shell             Open a lightweight managed Guix shell' \
	  'make kicad-shell       Open a managed KiCad shell' \
	  'make kicad-version     Print the managed KiCad version' \
	  'make kicad-edits       Open PROJECT in KiCad using the configured library path' \
	  'make fab               Generate Gerber/drill fabrication files for PROJECT' \
	  'make docs             Generate published board documentation for PROJECT' \
	  'make docs-check       Report whether the generated documentation is stale' \
	  'make export-dsn        Export the PCB to Specctra DSN for Freerouting (corrected export)' \
	  'make freeroute         Export the DSN and open it in the Freerouting GUI' \
	  'make import-ses        Apply the Freerouting .ses to the PCB headlessly, with a backup' \
	  'make clearance-baseline Record the clearance fingerprint before routing' \
	  'make clearance-check   Compare clearance DRC on a copy against the baseline' \
	  'make agent-reflection  Print Codex and Claude dry-run Reflection records' \
	  'make codex             Start Codex with this board, libraries, interfaces, context, and memory' \
	  'make claude            Start Claude with this board, libraries, interfaces, context, and memory' \
	  'make freecad-edits     Launch FreeCAD for 3D model work' \
	  'make agent-project     Start Codex centered on this project repo only' \
	  'make agent-libs        Start Codex centered on the sibling kicad-libs checkout' \
	  'make agent-both        Start Codex in this repo with the library repo added as workspace' \
	  'make agent-edits       Alias for make agent-both' \
	  'make validate-db       Validate the Orb Weaver KiCad database library wiring' \
	  'make check-kicad-libs  Check ORB_WEAVER_KICAD_LIBS points at usable libraries' \
	  'make mechanical-datums Export connector mating datums and the block placement record (KiCad shell)' \
	  'make board-manifest-derive  Write the manifest from the schematic hierarchy and the placement record (keeps meanings and reasons)' \
	  'make board-manifest-check   Check kicad/board-manifest.yaml against the board, the library and the netclass patterns' \
	  'make board-manifest-render  Render the interface map from the manifest into docs/interface-map.md' \
	  'make sheet-pins        Arrange a placed block sheet pins as the library records them (SHEET=<name>, or SHEET_PINS_OPTIONS=--list)' \
	  'make compose           Make the project agree with the manifest: create the sheet instances, pin connections and PCB groups it lacks (KiCad shell)' \
	  'make compose-check     Report what compose would create and what differs; exit 1 when there is anything' \
	  'make expand            Write kicad/board-manifest.yaml from kicad/board.yaml and its subsystem recipes' \
	  'make expand-check      Compare the expansion of kicad/board.yaml with kicad/board-manifest.yaml; exit 1 on a difference' \
	  'make refresh-block     Bring one placed block up to its library block and report what changed (INSTANCE= [BLOCK=] [RENAME=OLD=NEW]; KiCad shell)' \
	  'make place-block       Move a placed block group so its anchor lands exactly on the grid (GROUP= X= Y= [ROTATION=] [GRID=])' \
	  'make block-spacing     Check the corridor between placed blocks against the nets that must cross it, before routing' \
	  '' \
	  'Variables:' \
	  '  PROJECT=/abs/path/to/project.kicad_pro' \
	  '  FAB_TOOL=orb-weaver-kicad-fab                              # fabrication helper command' \
	  '  FAB_OUTPUT_DIR=fab/project-name                                # fabrication output directory' \
	  '  FAB_OPTIONS="--skip-erc --skip-drc"                            # extra orb-weaver-kicad-fab options' \
	  '  DOCS_OUTPUT_DIR=docs/generated                                 # board documentation output directory' \
	  '  DOCS_OPTIONS="--skip-renders"                                  # extra orb-weaver-kicad-docs options' \
	  '  DSN=fab/autoroute/<board>.dsn  SES=fab/autoroute/<board>.ses  # routing exchange files' \
	  '  EXPORT_DSN_OPTIONS="--refill --protect-prerouted --power-layer In1.Cu"  # extra orb-weaver-kicad-export-dsn options' \
	  '  IMPORT_SES_OPTIONS="--dry-run"                                # extra orb-weaver-kicad-import-ses options' \
	  '  ORB_WEAVER_KICAD_LIBS=/path/to/orb-weaver-kicad-libs-root     # explicit override' \
	  '  ORB_WEAVER_KICAD_LIBS_CHECKOUT=/path/to/kicad-libs             # editable checkout, preferred when present' \
	  '  ORB_WEAVER_KICAD_LIBS_AUTO_BUILD=1                            # resolve packaged libraries during prepare-kicad-config' \
	  '  GUIX_AGENT_TOOLS_CHECKOUT=/path/to/guix-agent-tools           # optional local checkout'

test:
	test -f .agents/AGENTS.md
	test -f .agents/PLANS.md
	test -f kicad/camera-gpio-interface-pcb.kicad_pro
	test -f kicad/camera-gpio-interface-pcb.kicad_sch
	test -f kicad/camera-gpio-interface-pcb.kicad_pcb
	test -f kicad/camera-gpio-interface-pcb.kicad_dru
	test -f kicad/sym-lib-table
	test -f kicad/fp-lib-table
	test -f kicad/design-block-lib-table
	test -f docs/rev0-plan.md
	test -f docs/kicad-libs-handoff-2026-09-24.md

check-kicad-libs:
	@orb_libs="$(ORB_WEAVER_KICAD_LIBS)"; \
	if [ -z "$$orb_libs" ]; then \
	  echo "No editable Orb Weaver KiCad library checkout found; resolving packaged orb-weaver-kicad-libs..."; \
	  package_root="$$($(GUIX_TIME_MACHINE) -- build orb-weaver-kicad-libs)" || exit $$?; \
	  orb_libs="$$package_root/share/orb-weaver-kicad-libs"; \
	fi; \
	if [ ! -f "$$orb_libs/kicad/db-libraries/orb_weaver_internal.kicad_dbl" ]; then \
	  echo "Missing KiCad DB library: $$orb_libs/kicad/db-libraries/orb_weaver_internal.kicad_dbl"; \
	  exit 1; \
	fi; \
	if [ ! -f "$$orb_libs/db/build/orb_weaver_parts.sqlite" ]; then \
	  echo "Missing generated SQLite catalog: $$orb_libs/db/build/orb_weaver_parts.sqlite"; \
	  exit 1; \
	fi

prepare-kicad-config:
	mkdir -p $(KICAD_CONFIG_DIR) $(XDG_CACHE_HOME)
	printf '%s\n' '(sym_lib_table' '  (version 7)' ')' > "$(KICAD_CONFIG_DIR)/sym-lib-table"
	printf '%s\n' '(fp_lib_table' '  (version 7)' ')' > "$(KICAD_CONFIG_DIR)/fp-lib-table"
	@orb_libs="$(ORB_WEAVER_KICAD_LIBS)"; \
	if [ -z "$$orb_libs" ] && [ "$(ORB_WEAVER_KICAD_LIBS_AUTO_BUILD)" = "1" ]; then \
	  echo "Resolving packaged orb-weaver-kicad-libs..."; \
	  package_root="$$($(GUIX_TIME_MACHINE) -- build orb-weaver-kicad-libs)" || exit $$?; \
	  orb_libs="$$package_root/share/orb-weaver-kicad-libs"; \
	fi; \
	KICAD_COMMON_JSON="$(KICAD_COMMON_JSON)" ORB_WEAVER_KICAD_LIBS="$$orb_libs" python3 -c 'import json, os, pathlib; path = pathlib.Path(os.environ["KICAD_COMMON_JSON"]); data = json.loads(path.read_text()) if path.exists() else {}; env = data.setdefault("environment", {}); vars_map = env.get("vars"); vars_map = vars_map if isinstance(vars_map, dict) else {}; orb_libs = os.environ.get("ORB_WEAVER_KICAD_LIBS", ""); vars_map.pop("ORB_WEAVER_KICAD_LIBS", None) if not orb_libs else vars_map.__setitem__("ORB_WEAVER_KICAD_LIBS", orb_libs); env["vars"] = vars_map; data.setdefault("meta", {}).setdefault("version", 5); path.write_text(json.dumps(data, indent=2) + "\n")'

shell:
	$(MAKE) prepare-kicad-config
	$(AGENT_MANAGED_SHELL) bash

kicad-shell:
	$(MAKE) prepare-kicad-config
	$(KICAD_MANAGED_SHELL) bash

kicad-version:
	mkdir -p $(KICAD_CONFIG_HOME) $(XDG_CACHE_HOME)
	$(KICAD_MANAGED_SHELL) kicad-cli version

agent-reflection:
	$(AGENT_MEMORY_ENV) $(CODEX_GUIX_SHELL) --session-role agent --print-reflection "$(CURDIR)" $(PCB_AGENT_EXTRA_DIRS) $(AGENT_EXTRA_DIRS)
	$(AGENT_MEMORY_ENV) $(CLAUDE_GUIX_SHELL) --session-role agent --print-reflection "$(CURDIR)" $(PCB_AGENT_EXTRA_DIRS) $(AGENT_EXTRA_DIRS)

codex: agent-both

claude:
	$(MAKE) prepare-kicad-config
	$(AGENT_MEMORY_ENV) $(CLAUDE_GUIX_SHELL) --session-role agent "$(CURDIR)" $(PCB_AGENT_EXTRA_DIRS) $(AGENT_EXTRA_DIRS)

agent-project:
	$(MAKE) prepare-kicad-config
	$(AGENT_MEMORY_ENV) $(CODEX_GUIX_SHELL) --session-role agent "$(CURDIR)" "$(GUIX_AGENT_TOOLS_CHECKOUT)" $(if $(wildcard $(AGENT_MEMORY_REPO_CHECKOUT)/AGENTS.md),$(AGENT_MEMORY_REPO_CHECKOUT)) $(AGENT_EXTRA_DIRS)

agent-libs:
	@if [ ! -d "$(LIBS_WORKSPACE)" ]; then echo "ORB_WEAVER_KICAD_LIBS_CHECKOUT=/path/to/kicad-libs is required for agent-libs"; exit 1; fi
	$(MAKE) prepare-kicad-config
	$(AGENT_MEMORY_ENV) $(CODEX_GUIX_SHELL) --session-role agent "$(LIBS_WORKSPACE)" "$(CURDIR)" "$(BOARD_INTERFACES_CHECKOUT)" "$(ORB_WEAVER_CONTEXT_CHECKOUT)" "$(GUIX_AGENT_TOOLS_CHECKOUT)" $(if $(wildcard $(AGENT_MEMORY_REPO_CHECKOUT)/AGENTS.md),$(AGENT_MEMORY_REPO_CHECKOUT)) $(AGENT_EXTRA_DIRS)

agent-both:
	$(MAKE) prepare-kicad-config
	$(AGENT_MEMORY_ENV) $(CODEX_GUIX_SHELL) --session-role agent "$(CURDIR)" $(PCB_AGENT_EXTRA_DIRS) $(AGENT_EXTRA_DIRS)

agent-edits: agent-both

kicad-edits:
	@if [ -z "$(PROJECT)" ]; then echo "PROJECT=/path/to/project.kicad_pro is required"; exit 1; fi
	$(MAKE) prepare-kicad-config
	$(KICAD_MANAGED_SHELL) kicad "$(PROJECT)"

fab:
	@if [ -z "$(PROJECT)" ]; then echo "PROJECT=/path/to/project.kicad_pro is required"; exit 1; fi
	$(MAKE) prepare-kicad-config
	$(KICAD_MANAGED_SHELL) "$(FAB_TOOL)" --project "$(PROJECT)" --output-dir "$(FAB_OUTPUT_DIR)" $(FAB_OPTIONS)

docs:
	@if [ -z "$(PROJECT)" ]; then echo "PROJECT=/path/to/project.kicad_pro is required"; exit 1; fi
	$(MAKE) prepare-kicad-config
	$(KICAD_MANAGED_SHELL) "$(DOCS_TOOL)" --project "$(PROJECT)" --output-dir "$(DOCS_OUTPUT_DIR)" $(DOCS_OPTIONS)

docs-check:
	@if [ -z "$(PROJECT)" ]; then echo "PROJECT=/path/to/project.kicad_pro is required"; exit 1; fi
	$(KICAD_MANAGED_SHELL) "$(DOCS_TOOL)" --project "$(PROJECT)" --output-dir "$(DOCS_OUTPUT_DIR)" --check

freecad-edits:
	$(MAKE) prepare-kicad-config
	$(FREECAD_MANAGED_SHELL) freecad

validate-db:
	mkdir -p $(KICAD_CONFIG_HOME) $(XDG_CACHE_HOME)
	@orb_libs="$(ORB_WEAVER_KICAD_LIBS)"; \
	if [ -z "$$orb_libs" ]; then \
	  echo "No editable Orb Weaver KiCad library checkout found; resolving packaged orb-weaver-kicad-libs..."; \
	  package_root="$$($(GUIX_TIME_MACHINE) -- build orb-weaver-kicad-libs)" || exit $$?; \
	  orb_libs="$$package_root/share/orb-weaver-kicad-libs"; \
	fi; \
	if [ ! -f "$$orb_libs/kicad/db-libraries/orb_weaver_internal.kicad_dbl" ]; then \
	  echo "Missing KiCad DB library: $$orb_libs/kicad/db-libraries/orb_weaver_internal.kicad_dbl"; \
	  exit 1; \
	fi; \
	KICAD_CONFIG_HOME="$(KICAD_CONFIG_HOME)" XDG_CACHE_HOME="$(XDG_CACHE_HOME)" ORB_WEAVER_KICAD_LIBS="$$orb_libs" $(GUIX_SHELL_AGENT) -E "^KICAD_CONFIG_HOME$$" -E "^XDG_CACHE_HOME$$" -E "^ORB_WEAVER_KICAD_LIBS$$" -- kicad-agent inspect-db-library "$$orb_libs/kicad/db-libraries/orb_weaver_internal.kicad_dbl"; \
	KICAD_CONFIG_HOME="$(KICAD_CONFIG_HOME)" XDG_CACHE_HOME="$(XDG_CACHE_HOME)" ORB_WEAVER_KICAD_LIBS="$$orb_libs" $(GUIX_SHELL_AGENT) -E "^KICAD_CONFIG_HOME$$" -E "^XDG_CACHE_HOME$$" -E "^ORB_WEAVER_KICAD_LIBS$$" -- kicad-agent inspect-db-library "$$orb_libs/kicad/db-libraries/orb_weaver_catalog.kicad_dbl"

# Freerouting round trip. kicad-cli has no Specctra subcommand, so the DSN and
# SES go through KiCad's pcbnew Python bindings inside the KiCad shell. The DSN
# carries netclasses and existing copper but not the .kicad_dru rules, so run
# clearance-baseline before routing and clearance-check after importing.
export-dsn:
	@if [ -z "$(PROJECT)" ]; then echo "PROJECT=/path/to/project.kicad_pro is required"; exit 1; fi
	$(MAKE) prepare-kicad-config
	$(KICAD_MANAGED_SHELL) "$(EXPORT_DSN_TOOL)" --project "$(PROJECT)" --output "$(DSN)" $(EXPORT_DSN_OPTIONS)

# -di points the open/save dialogs at the DSN directory so the .ses lands there.
freeroute: export-dsn
	$(KICAD_MANAGED_SHELL) freerouting -de "$(DSN)" -di "$(dir $(DSN))"

import-ses:
	@if [ -z "$(PROJECT)" ]; then echo "PROJECT=/path/to/project.kicad_pro is required"; exit 1; fi
	$(MAKE) prepare-kicad-config
	$(KICAD_MANAGED_SHELL) "$(IMPORT_SES_TOOL)" --project "$(PROJECT)" --ses "$(SES)" $(IMPORT_SES_OPTIONS)

clearance-baseline:
	@if [ -z "$(PROJECT)" ]; then echo "PROJECT=/path/to/project.kicad_pro is required"; exit 1; fi
	$(MAKE) prepare-kicad-config
	$(KICAD_MANAGED_SHELL) "$(CLEARANCE_CHECK_TOOL)" --project "$(PROJECT)" --save-baseline $(CLEARANCE_CHECK_OPTIONS)

clearance-check:
	@if [ -z "$(PROJECT)" ]; then echo "PROJECT=/path/to/project.kicad_pro is required"; exit 1; fi
	$(MAKE) prepare-kicad-config
	$(KICAD_MANAGED_SHELL) "$(CLEARANCE_CHECK_TOOL)" --project "$(PROJECT)" $(CLEARANCE_CHECK_OPTIONS)

# Connector mating centres and directions and the placed-block record, in board
# coordinates relative to the board datum (aux axis origin when set), for the
# enclosure and the documentation. Writes JSON and CSV beside each other.
mechanical-datums:
	@if [ -z "$(PROJECT)" ]; then echo "PROJECT=/path/to/project.kicad_pro is required"; exit 1; fi
	$(MAKE) prepare-kicad-config
	mkdir -p "$(dir $(MECHANICAL_DATUMS))"
	$(KICAD_MANAGED_SHELL) "$(MECHANICAL_DATUMS_TOOL)" --project "$(PROJECT)" --output "$(MECHANICAL_DATUMS)" --csv "$(MECHANICAL_DATUMS:.json=.csv)" $(MECHANICAL_DATUMS_OPTIONS)

# The board manifest (kicad-libs PLANS 2026-09-30 D20): kicad/board-manifest.yaml
# names every placed block with its anchor, rotation and side, maps each port
# to the label it meets in its parent sheet (or `open` with a reason), lists
# the board-authored wrapper sheets and the netclass profiles, and gives every
# net its class. `board-manifest-derive` writes it from the schematic and the
# mechanical-datums record (run `make mechanical-datums` first; an existing
# manifest keeps its meanings, reasons and notes); `board-manifest-check`
# compares it with the board, the library and the project's netclass patterns,
# and fails on a port neither mapped nor open; `board-manifest-render` writes
# the generated block of docs/interface-map.md (BOARD_MANIFEST_MAP=). Pure
# Python, lightweight shell.
board-manifest-derive:
	@if [ -z "$(PROJECT)" ]; then echo "PROJECT=/path/to/project.kicad_pro is required"; exit 1; fi
	$(AGENT_MANAGED_SHELL) "$(BOARD_MANIFEST_TOOL)" derive --project "$(PROJECT)" --output "$(BOARD_MANIFEST)" $(if $(wildcard $(MECHANICAL_DATUMS)),--datums "$(MECHANICAL_DATUMS)") $(BOARD_MANIFEST_OPTIONS)

board-manifest-check:
	$(AGENT_MANAGED_SHELL) "$(BOARD_MANIFEST_TOOL)" check "$(BOARD_MANIFEST)" $(if $(wildcard $(MECHANICAL_DATUMS)),--datums "$(MECHANICAL_DATUMS)") $(BOARD_MANIFEST_OPTIONS)

board-manifest-render:
	$(AGENT_MANAGED_SHELL) "$(BOARD_MANIFEST_TOOL)" render "$(BOARD_MANIFEST)" --output "$(BOARD_MANIFEST_MAP)" $(BOARD_MANIFEST_OPTIONS)

# Arrange a placed block sheet's pins the way the library records them
# (kicad-libs design_blocks/sheet-layouts.json, PLANS 2026-09-30 D18): pins move
# by name, the sheet takes the recorded size, a wire that met a moved pin
# follows it (a stub with its label is re-placed, any other wire is stretched),
# nothing is deleted, the netlist is unchanged. Run after placing a sheet and
# before wiring it, or after a refresh. SHEET names the sheet (Sheetname,
# Sheetfile or block); SHEET_PINS_OPTIONS="--dry-run" previews, "--list" names
# the root's sheets and whether each matches. Pure Python, lightweight shell.
sheet-pins:
	@if [ -z "$(PROJECT)" ]; then echo "PROJECT=/path/to/project.kicad_pro is required"; exit 1; fi
	$(AGENT_MANAGED_SHELL) "$(SHEET_PINS_TOOL)" --project "$(PROJECT)" $(if $(SHEET),--sheet "$(SHEET)") $(if $(SHEET_LAYOUTS),--table "$(SHEET_LAYOUTS)") $(SHEET_PINS_OPTIONS)

# The composer (kicad-libs PLANS 2026-09-30 step 4, D28): `make compose` makes
# the project agree with kicad/board-manifest.yaml. A placement the board lacks
# gets its child sheet from the library block (designators in the sheet's page
# band), its sheet symbol with the recorded pin arrangement, a stub and label
# per mapped port, a no-connect per open port, and its PCB group with the
# block's copper at the recorded anchor and rotation; a subsystem sheet without
# a file gets the file with its hierarchical labels; a pin wired to nothing
# gets its stub. Nothing is moved, renamed or deleted: a difference is reported
# from the manifest check and fixed in the drawing or the manifest. Then run
# `make mechanical-datums` (the record keys groups by sheet UUID) and
# `make board-manifest-check`; `make place-block` puts a new group's anchor on
# the grid. `make compose-check` is the dry run (exit 1 when there is anything).
compose:
	$(MAKE) prepare-kicad-config
	$(KICAD_MANAGED_SHELL) "$(COMPOSE_TOOL)" compose "$(BOARD_MANIFEST)" $(if $(wildcard $(MECHANICAL_DATUMS)),--datums "$(MECHANICAL_DATUMS)") $(COMPOSE_OPTIONS)

compose-check:
	$(AGENT_MANAGED_SHELL) "$(COMPOSE_TOOL)" check "$(BOARD_MANIFEST)" $(if $(wildcard $(MECHANICAL_DATUMS)),--datums "$(MECHANICAL_DATUMS)") $(COMPOSE_OPTIONS)

# The board source (kicad-libs PLANS 2026-09-30 step 4d, D27): kicad/board.yaml
# instantiates subsystem recipes by reference (a kicad-libs recipe pinned by
# hash, or a board-local kicad/subsystems/<name>.subsystem.yaml), overrides and
# places the blocks per role and connects subsystem pins to root nets by name
# with only renames and opens written; the boards' own sheet-pin arrangements
# live in kicad/sheet-pins.yaml. `make expand` writes the record
# (kicad/board-manifest.yaml) from it; `make expand-check` compares the
# expansion with the record and fails on a difference. The record stays the
# checked file: after expand, `make board-manifest-check`, then `make compose`.
expand:
	$(AGENT_MANAGED_SHELL) "$(BOARD_SOURCE_TOOL)" expand "$(BOARD_SOURCE)" --write --output "$(BOARD_MANIFEST)" $(BOARD_SOURCE_OPTIONS)

expand-check:
	$(AGENT_MANAGED_SHELL) "$(BOARD_SOURCE_TOOL)" expand "$(BOARD_SOURCE)" --check --output "$(BOARD_MANIFEST)" $(BOARD_SOURCE_OPTIONS)

# The refresh (kicad-libs PLANS 2026-09-30 step 5, D22): `make refresh-block
# INSTANCE=<name> [BLOCK=<library:block>] [RENAME=OLD=NEW]` brings one placed
# block up to its library block: the child sheet replaced keeping the sheet's
# UUID, position and designators, pins restored by name (a new port's pin
# appended, a removed port's pin gone with its stub and label left and
# reported), the PCB group's copper replaced by identity where it stands; the
# board's own tracks, wires and labels are left alone. It prints the record
# lines to change; then edit kicad/board.yaml, `make expand`, `make compose`
# (wires the new pins), `make mechanical-datums`, `make board-manifest-check`.
refresh-block:
	@if [ -z "$(INSTANCE)" ]; then echo "INSTANCE=<placed block name> is required"; exit 1; fi
	$(MAKE) prepare-kicad-config
	$(KICAD_MANAGED_SHELL) "$(REFRESH_BLOCK_TOOL)" "$(BOARD_MANIFEST)" --instance "$(INSTANCE)" $(if $(BLOCK),--block "$(BLOCK)") $(if $(RENAME),--rename "$(RENAME)") $(if $(wildcard $(MECHANICAL_DATUMS)),--datums "$(MECHANICAL_DATUMS)") $(REFRESH_BLOCK_OPTIONS)

# Place a design-block instance: move and rotate its group rigidly about the
# block's declared anchor so the anchor lands exactly on the grid, with its
# copper, rule areas and User.1 boundary. ROTATION is relative to the library
# layout; GRID defaults to the block's (1 mm), 0 for none. Place before routing:
# copper that is not in the group does not move, and the tool warns when some
# ends on the group's pads. PLACE_BLOCK_OPTIONS="--list" names the groups,
# "--dry-run" previews without saving.
place-block:
	@if [ -z "$(PROJECT)" ]; then echo "PROJECT=/path/to/project.kicad_pro is required"; exit 1; fi
	$(MAKE) prepare-kicad-config
	$(KICAD_MANAGED_SHELL) "$(PLACE_BLOCK_TOOL)" --project "$(PROJECT)" $(if $(GROUP),--group "$(GROUP)") $(if $(X),--x $(X)) $(if $(Y),--y $(Y)) $(if $(ROTATION),--rotation $(ROTATION)) $(if $(GRID),--grid $(GRID)) $(PLACE_BLOCK_OPTIONS)

# Before routing: the corridor between every pair of placed blocks (and each
# block against a bare connector) against the nets that must cross it, from
# the board's ratsnest and netclasses. A pair fails below what its crossing
# tracks need (widths plus a clearance between and beside them) or below the
# 2 mm floor; BLOCK_SPACING_OPTIONS="--min-gap 1.5", "--allow" (report only),
# "--json docs/generated/block-spacing.json".
block-spacing:
	@if [ -z "$(PROJECT)" ]; then echo "PROJECT=/path/to/project.kicad_pro is required"; exit 1; fi
	$(MAKE) prepare-kicad-config
	$(KICAD_MANAGED_SHELL) "$(BLOCK_SPACING_TOOL)" --project "$(PROJECT)" $(BLOCK_SPACING_OPTIONS)
