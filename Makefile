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

MANAGED_ENV = KICAD_CONFIG_HOME=$(KICAD_CONFIG_HOME) XDG_CACHE_HOME=$(XDG_CACHE_HOME) $(if $(ORB_WEAVER_KICAD_LIBS),ORB_WEAVER_KICAD_LIBS=$(ORB_WEAVER_KICAD_LIBS))
TLS_ENV = export SSL_CERT_FILE="$${GUIX_ENVIRONMENT}/etc/ssl/certs/ca-certificates.crt"; export GIT_SSL_CAINFO="$$SSL_CERT_FILE"; export CURL_CA_BUNDLE="$$SSL_CERT_FILE"; export SSL_CERT_DIR="$${GUIX_ENVIRONMENT}/etc/ssl/certs"; exec "$$@"
AGENT_MANAGED_SHELL = $(MANAGED_ENV) $(GUIX_SHELL_AGENT) -E "^KICAD_CONFIG_HOME$$" -E "^XDG_CACHE_HOME$$" -E "^ORB_WEAVER_KICAD_LIBS$$" -- sh -c '$(TLS_ENV)' sh
KICAD_MANAGED_SHELL = $(MANAGED_ENV) $(GUIX_SHELL_KICAD) -E "^KICAD_CONFIG_HOME$$" -E "^XDG_CACHE_HOME$$" -E "^ORB_WEAVER_KICAD_LIBS$$" -- sh -c '$(TLS_ENV)' sh
FREECAD_MANAGED_SHELL = $(MANAGED_ENV) $(GUIX_SHELL_FREECAD) -E "^KICAD_CONFIG_HOME$$" -E "^XDG_CACHE_HOME$$" -E "^ORB_WEAVER_KICAD_LIBS$$" -- sh -c '$(TLS_ENV)' sh
MANAGED_SHELL = $(AGENT_MANAGED_SHELL)

LIBS_WORKSPACE := $(if $(wildcard $(ORB_WEAVER_KICAD_LIBS_CHECKOUT)),$(ORB_WEAVER_KICAD_LIBS_CHECKOUT),$(ORB_WEAVER_KICAD_LIBS))
PCB_AGENT_EXTRA_DIRS ?= $(BOARD_INTERFACES_CHECKOUT) $(ORB_WEAVER_CONTEXT_CHECKOUT) $(GUIX_AGENT_TOOLS_CHECKOUT) $(MOUSE_JOYSTICK_PCB_CHECKOUT) $(LA5032_ADAPTER_CHECKOUT) $(JOYSTICK_RIG_CHECKOUT) $(PYCONTROL_H7_BREAKOUT_CHECKOUT) $(if $(LIBS_WORKSPACE),$(LIBS_WORKSPACE)) $(if $(wildcard $(AGENT_MEMORY_REPO_CHECKOUT)/AGENTS.md),$(AGENT_MEMORY_REPO_CHECKOUT))

.PHONY: docs docs-check help test prepare-kicad-config check-kicad-libs shell kicad-shell kicad-version agent-reflection codex claude agent-project agent-libs agent-both agent-edits kicad-edits freecad-edits validate-db fab export-dsn freeroute import-ses clearance-baseline clearance-check

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
