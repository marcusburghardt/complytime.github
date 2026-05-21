# Ensure Go automatically downloads the toolchain version required by go.mod.
export GOTOOLCHAIN := auto

##@ Testing

test-unit: ## run unit tests with coverage
	go test -race -v -coverprofile=coverage.out ./...
.PHONY: test-unit

format: ## format Go source
	go fmt ./...
.PHONY: format

vet: ## run go vet
	go vet ./...
.PHONY: vet

lint: ## run yamllint on peribolos.yaml and safe-settings config
	yamllint peribolos.yaml
	yamllint safe-settings/
.PHONY: lint

sanity: vendor format vet lint ## ensure code is ready for commit
	git diff --exit-code
.PHONY: sanity

##@ Environment

vendor: ## go mod sync
	go mod tidy
	go mod verify
	go mod vendor
.PHONY: vendor

clean: ## remove generated files
	rm -f coverage.out
	rm -f /tmp/peribolos
.PHONY: clean

##@ Peribolos (local testing)

PERIBOLOS_BIN := /tmp/peribolos
PERIBOLOS_TOKEN_PATH ?= $(HOME)/.config/peribolos/token

ensure-peribolos: ## build peribolos binary if not present
	@if [ ! -f $(PERIBOLOS_BIN) ]; then \
		echo "Building peribolos..."; \
		TMPDIR=$$(mktemp -d); \
		git clone --depth 1 https://github.com/kubernetes-sigs/prow.git "$$TMPDIR/prow"; \
		cd "$$TMPDIR/prow/cmd/peribolos" && go mod tidy && go build -o $(PERIBOLOS_BIN) .; \
		rm -rf "$$TMPDIR"; \
		echo "Peribolos built at $(PERIBOLOS_BIN)"; \
	else \
		echo "Peribolos already at $(PERIBOLOS_BIN)"; \
	fi
.PHONY: ensure-peribolos

peribolos-dryrun: ensure-peribolos ## dry-run peribolos against the live org (no changes)
	@if [ ! -f $(PERIBOLOS_TOKEN_PATH) ]; then \
		echo "Token not found at $(PERIBOLOS_TOKEN_PATH)"; \
		echo "Create it with: mkdir -p ~/.config/peribolos && gh auth token > ~/.config/peribolos/token"; \
		exit 1; \
	fi
	$(PERIBOLOS_BIN) \
		--config-path peribolos.yaml \
		--fix-org \
		--fix-org-members \
		--fix-teams \
		--fix-team-members \
		--fix-repos \
		--fix-team-repos \
		--min-admins 2 \
		--require-self=false \
		--github-token-path $(PERIBOLOS_TOKEN_PATH) \
		2>&1 | jq -r '[.severity, .time, .msg] | join(" | ")'
.PHONY: peribolos-dryrun

peribolos-apply: ensure-peribolos ## apply peribolos config to the live org (DESTRUCTIVE)
	@if [ ! -f $(PERIBOLOS_TOKEN_PATH) ]; then \
		echo "Token not found at $(PERIBOLOS_TOKEN_PATH)"; \
		echo "Create it with: mkdir -p ~/.config/peribolos && gh auth token > ~/.config/peribolos/token"; \
		exit 1; \
	fi
	@echo "WARNING: This will modify the complytime GitHub org. Press Ctrl+C to abort."
	@sleep 3
	$(PERIBOLOS_BIN) \
		--config-path peribolos.yaml \
		--fix-org \
		--fix-org-members \
		--fix-teams \
		--fix-team-members \
		--fix-repos \
		--fix-team-repos \
		--min-admins 2 \
		--require-self=false \
		--confirm \
		--github-token-path $(PERIBOLOS_TOKEN_PATH) \
		2>&1 | jq -r '[.severity, .time, .msg] | join(" | ")'
.PHONY: peribolos-apply

##@ Safe-settings (local validation)

safe-settings-validate: ## validate safe-settings YAML syntax
	yamllint safe-settings/
.PHONY: safe-settings-validate

##@ CRAP Load Monitoring

GAZE_VERSION ?= latest
GAZE_BASELINE := .gaze/baseline.json
GAZE_COVERPROFILE := coverage.out
GAZE_NEW_FUNC_THRESHOLD ?= 30

ensure-gaze: ## install gaze if not present
	@command -v gaze >/dev/null 2>&1 || \
		(echo "Installing gaze..." && go install github.com/unbound-force/gaze/cmd/gaze@$(GAZE_VERSION))
.PHONY: ensure-gaze

crapload: ensure-gaze test-unit ## run CRAP and GazeCRAP analysis (human-readable)
	gaze crap --format=text --coverprofile=$(GAZE_COVERPROFILE) ./...
.PHONY: crapload

crapload-baseline: ensure-gaze test-unit ## generate baseline thresholds in .gaze/baseline.json
	@mkdir -p .gaze
	@REPO_ROOT=$$(pwd); \
	gaze crap --format=json --coverprofile=$(GAZE_COVERPROFILE) ./... | \
		jq --arg root "$$REPO_ROOT/" '(.scores // []) as $$s | .scores = [$$s[] | .file |= ltrimstr($$root)] | .summary.worst_crap = [(.summary.worst_crap // [])[] | .file |= ltrimstr($$root)] | .summary.worst_gaze_crap = [(.summary.worst_gaze_crap // [])[] | .file |= ltrimstr($$root)]' > $(GAZE_BASELINE)
	@echo "Baseline written to $(GAZE_BASELINE)"
.PHONY: crapload-baseline

crapload-check: ensure-gaze test-unit ## check for CRAP regressions against baseline
	@if [ ! -f $(GAZE_BASELINE) ]; then \
		echo "ERROR: Baseline file $(GAZE_BASELINE) not found. Run 'make crapload-baseline' first."; \
		exit 1; \
	fi
	@REPO_ROOT=$$(pwd); \
	gaze crap --format=json --coverprofile=$(GAZE_COVERPROFILE) ./... | \
		jq --arg root "$$REPO_ROOT/" '(.scores // []) as $$s | .scores = [$$s[] | .file |= ltrimstr($$root)] | .summary.worst_crap = [(.summary.worst_crap // [])[] | .file |= ltrimstr($$root)] | .summary.worst_gaze_crap = [(.summary.worst_gaze_crap // [])[] | .file |= ltrimstr($$root)]' > /tmp/crapload-current.json
	@echo "Comparing against baseline..."
	@jq -r '(.scores // [])[] | "\(.file):\(.function) \(.crap) \(.gaze_crap // 0)"' $(GAZE_BASELINE) | sort > /tmp/crapload-baseline.txt
	@jq -r '(.scores // [])[] | "\(.file):\(.function) \(.crap) \(.gaze_crap // 0)"' /tmp/crapload-current.json | sort > /tmp/crapload-current.txt
	@REGRESSIONS=0; \
	while IFS=' ' read -r func crap gaze_crap; do \
		baseline_crap=$$(grep -F "$$func " /tmp/crapload-baseline.txt | head -1 | awk '{print $$2}'); \
		baseline_gaze=$$(grep -F "$$func " /tmp/crapload-baseline.txt | head -1 | awk '{print $$3}'); \
		if [ -z "$$baseline_crap" ]; then \
			if [ "$$(echo "$$crap > $(GAZE_NEW_FUNC_THRESHOLD)" | bc -l)" = "1" ]; then \
				echo "NEW FUNCTION VIOLATION: $$func CRAP=$$crap (threshold=$(GAZE_NEW_FUNC_THRESHOLD))"; \
				REGRESSIONS=$$((REGRESSIONS + 1)); \
			fi; \
		else \
			if [ "$$(echo "$$crap > $$baseline_crap" | bc -l)" = "1" ]; then \
				echo "REGRESSION: $$func CRAP $$baseline_crap -> $$crap"; \
				REGRESSIONS=$$((REGRESSIONS + 1)); \
			fi; \
			if [ "$$(echo "$$gaze_crap > $$baseline_gaze" | bc -l)" = "1" ]; then \
				echo "REGRESSION: $$func GazeCRAP $$baseline_gaze -> $$gaze_crap"; \
				REGRESSIONS=$$((REGRESSIONS + 1)); \
			fi; \
		fi; \
	done < /tmp/crapload-current.txt; \
	if [ $$REGRESSIONS -gt 0 ]; then \
		echo "FAIL: $$REGRESSIONS regression(s) detected"; \
		exit 1; \
	else \
		echo "PASS: No regressions detected"; \
	fi
.PHONY: crapload-check

##@ Help

GREEN := \033[0;32m
TEAL := \033[0;36m
CLEAR := \033[0m

help: ## show this help
	@printf "Usage: make $(GREEN)<target>$(CLEAR)\n"
	@awk -v "green=${GREEN}" -v "teal=${TEAL}" -v "clear=${CLEAR}" -F ":.*## *" \
		'/^[a-zA-Z0-9_-]+:/{sub(/:.*/,"",$$1);printf "  %s%-20s%s %s\n", green, $$1, clear, $$2} /^##@/{printf "%s%s%s\n", teal, substr($$1,5), clear}' $(MAKEFILE_LIST)
.PHONY: help
