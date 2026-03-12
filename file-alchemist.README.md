# File Alchemist: Universal Format Converter

## Overview
A professional Bash script to convert between CSV, JSON, Markdown, HTML, PDF, and more. Supports batch mode, custom mapping/filtering, and robust logging.

---

## Prerequisites
- Bash 5+
- csvkit
- jq
- pandoc
- (Optional) pdfkit for PDF output

---

## Usage
```bash
./file-alchemist.sh -s SRC -t TO_FORMAT [-d DEST] [-b] [-v] [--map MAP] [--filter FILTER]
```
- `-s SRC`: Source file or directory
- `-t TO_FORMAT`: Target format (csv, json, md, html, pdf)
- `-d DEST`: Output file or directory (default: auto)
- `-b`: Batch mode (convert all files in directory)
- `-v`: Verbose output
- `--map MAP`: Custom jq/csvkit mapping (e.g., '.[] | {id, value}')
- `--filter FILTER`: Filter rows/records (e.g., 'value > 10')
- `--example`: Show detailed examples
- `--help`: Show usage

---

## Examples
```bash
# Convert a CSV to JSON with custom mapping
./file-alchemist.sh -s data.csv -t json --map '.[] | {id,score}'

# Batch convert all Markdown files to PDF in a directory
./file-alchemist.sh -s ./mds -t pdf -b

# Convert JSON to CSV, filtering for value > 10
./file-alchemist.sh -s data.json -t csv --filter 'value > 10'
```

---

## Features
- Converts between major data formats
- Batch and interactive modes
- Custom mapping/filtering with jq/csvkit
- Timestamped logging to /var/log/file-alchemist.log

---

## Troubleshooting
- Check /var/log/file-alchemist.log for errors
- Ensure all dependencies are installed
