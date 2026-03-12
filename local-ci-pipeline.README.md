# CI/CD Pipeline Local Runner

## Overview
A Bash script to run lints, unit tests, and security scans locally, mimicking a CI pipeline. Ensures your code is ready for production before pushing.

---

## Prerequisites
- Bash 5+
- shellcheck
- yamllint
- flake8
- pytest
- bandit

---

## Usage
```bash
./local-ci-pipeline.sh
```

---

## Features
- Runs all major linters and security scans
- Runs Python unit tests with pytest
- Logs results and failures
- Exits with nonzero code if any check fails

---

## Troubleshooting
- Ensure all required tools are installed
- Review output for failed checks
