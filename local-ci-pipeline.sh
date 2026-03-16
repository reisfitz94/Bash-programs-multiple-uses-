#!/bin/bash
################################################################################
# CI/CD Pipeline Local Runner
#
# Runs lints, unit tests, and security scans locally, mimicking a CI pipeline.
# Usage: ./local-ci-pipeline.sh
################################################################################

set -euo pipefail

# ========== CONFIGURATION ========== #
LINTERS=("shellcheck" "yamllint")
PYTHON_LINT="flake8"
PYTHON_TEST="pytest"
SECURITY_SCAN="bandit"

log() { echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*"; }
failures=0

run_linter() {
    local linter="$1"
    if ! command -v "$linter" &>/dev/null; then
        log "SKIP: $linter not installed."
        return
    fi
    log "Running $linter..."
    case "$linter" in
        shellcheck)
            find . -type f -name "*.sh" -exec shellcheck {} + || failures=1 ;;
        yamllint)
            find . -type f \( -name "*.yml" -o -name "*.yaml" \) -print0 | xargs -0 -r yamllint || failures=1 ;;
        flake8)
            find . -type f -name "*.py" -print0 | xargs -0 -r flake8 || failures=1 ;;
        bandit)
            find . -type f -name "*.py" -print0 | xargs -0 -r bandit -r -ll || failures=1 ;;
        *)
            "$linter" . || failures=1 ;;
    esac
}

run_tests() {
    if command -v $PYTHON_TEST &>/dev/null; then
        log "Running Python tests with $PYTHON_TEST..."
        $PYTHON_TEST || failures=1
    else
        log "SKIP: $PYTHON_TEST not installed."
    fi
}

main() {
    log "Starting local CI pipeline..."
    for linter in "${LINTERS[@]}" "$PYTHON_LINT"; do
        run_linter "$linter"
    done
    run_tests
    run_linter "$SECURITY_SCAN"
    if (( failures == 0 )); then
        log "✅ All checks passed! Ready to push."
        exit 0
    else
        log "❌ Some checks failed. Fix issues before pushing."
        exit 1
    fi
}

main "$@"
