# Test + lint targets for the dotfiles repo.
# Run `make install-dev` once on a new machine to get bats / shellcheck / gitleaks.

.PHONY: help install-dev lint test test-unit test-integration doctor

help:
	@echo "make targets:"
	@echo "  install-dev       install test/lint deps (bats-core, shellcheck, gitleaks)"
	@echo "  lint              shellcheck + bash -n + zsh -n on all scripts"
	@echo "  test              alias for test-unit + test-integration"
	@echo "  test-unit         run bats unit tests"
	@echo "  test-integration  run Docker-based Linux integration"
	@echo "  doctor            run install.sh --doctor (Stage 6)"

install-dev:
	brew bundle --file=Brewfile.dev

lint:
	@bash tests/lint.sh

test: test-unit test-integration

test-unit:
	@if ls tests/unit/*.bats >/dev/null 2>&1; then \
		bats tests/unit; \
	else \
		echo "no unit tests yet — Stage 2 adds them"; \
	fi

test-integration:
	@if [ -x tests/integration/run-linux.sh ]; then \
		bash tests/integration/run-linux.sh; \
	else \
		echo "no integration tests yet — Stage 3 adds them"; \
	fi

doctor:
	@bash install.sh --doctor
