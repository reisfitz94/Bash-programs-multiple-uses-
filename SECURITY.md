# Security Policy

## Supported Versions

Security fixes are applied to the `main` branch.

## Reporting a Vulnerability

If you discover a security issue, please report it privately:

- Open a GitHub private vulnerability report (preferred), or
- Contact the repository owner directly through GitHub.

Please include:

- A clear description of the issue
- Steps to reproduce
- Affected script/file paths
- Potential impact
- Any suggested remediation

## Response Process

- Acknowledgement target: within 7 days
- Triage and severity assessment after acknowledgement
- Fixes are developed and pushed to `main`
- Public disclosure is coordinated after a fix is available

## Scope

This repository contains Bash and Python automation scripts. Reports are in scope when they involve:

- Command injection
- Unsafe temp-file handling
- Credential/secret exposure
- Privilege escalation paths
- Unsafe network/download behavior

Out-of-scope examples:

- Best-practice suggestions without exploitable impact
- Issues requiring unrealistic local root compromise assumptions only

## Hardening Baseline

A current summary of implemented hardening measures is documented in `SECURITY_BASELINE.md`.
