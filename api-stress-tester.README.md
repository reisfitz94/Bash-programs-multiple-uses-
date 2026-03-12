# API Stress Tester

## Overview
A professional-grade Bash script for stress testing APIs using curl and GNU parallel. Supports concurrent requests, custom HTTP methods, request bodies, and detailed logging.

---

## Prerequisites
- Bash 5+
- curl
- GNU parallel
- (Optional) jq for JSON output parsing

---

## Usage
```bash
./api-stress-tester.sh -u URL -n NUM -c CONCURRENCY [-M METHOD] [-b BODY_FILE] [-v]
```
- `-u URL` (required): API endpoint to test
- `-n NUM`: Number of requests (default: 1000)
- `-c CONCURRENCY`: Number of parallel jobs (default: number of CPU cores)
- `-M METHOD`: HTTP method (default: GET)
- `-b BODY_FILE`: File containing request body (for POST/PUT)
- `-v`: Verbose output
- `--help`: Show usage

---

## Example
```bash
# Stress test a POST endpoint with 1000 requests, 8 at a time
./api-stress-tester.sh -u https://api.example.com/endpoint -n 1000 -c 8 -M POST -b data.json -v
```

---

## Features
- Strict mode and robust error handling
- Timestamped logging to /var/log/api-stress-tester.log
- Supports GET, POST, PUT, DELETE, etc.
- Batch and single request modes
- Easy to extend for custom headers or authentication

---

## Troubleshooting
- Check /var/log/api-stress-tester.log for errors
- Ensure GNU parallel and curl are installed
- Use verbose mode for more output
