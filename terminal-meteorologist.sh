#!/bin/bash
################################################################################
# Terminal Meteorologist: Weather CLI & ASCII Chart (Professional Grade)
#
# - Fetches real-time weather data from api.weather.gov
# - Parses with jq
# - Prints ASCII bar chart of last 24h temperature trend
# - Strict mode, getopts, and logging
################################################################################

set -euo pipefail

LOG_FILE="/var/log/terminal-meteorologist.log"
VERBOSE=0
LAT=""
LON=""

log() {
    local msg="$1"
    local ts
    ts=$(date '+%Y-%m-%d %H:%M:%S')
    echo "[$ts] $msg"
    echo "[$ts] $msg" >> "$LOG_FILE"
}

usage() {
    cat <<EOF
Usage: $0 -a LAT -o LON [-v]
  -a LAT    Latitude
  -o LON    Longitude
  -v        Verbose output
  --help    Show this help
EOF
}

while getopts ":a:o:v-:" opt; do
    case $opt in
        a) LAT="$OPTARG" ;;
        o) LON="$OPTARG" ;;
        v) VERBOSE=1 ;;
        -)
            case $OPTARG in
                help) usage; exit 0 ;;
                *) echo "Unknown option --$OPTARG"; usage; exit 1 ;;
            esac ;;
        *) echo "Unknown flag: -$OPTARG"; usage; exit 1 ;;
    esac
done

if [[ -z "$LAT" || -z "$LON" ]]; then
    usage; exit 1
fi

get_gridpoint_url() {
    curl -s "https://api.weather.gov/points/$LAT,$LON" | jq -r '.properties.forecastHourly'
}

fetch_temps() {
    local url="$1"
    curl -s "$url" | jq -r '.properties.periods[:24][] | [.startTime, .temperature] | @tsv'
}

draw_chart() {
    local -a temps
    local -a times
    local min=1000 max=-1000
    while IFS=$'\t' read -r time temp; do
        temps+=("$temp")
        times+=("${time:11:5}")
        (( temp < min )) && min=$temp
        (( temp > max )) && max=$temp
    done
    echo "Temperature (°F) for last 24 hours:"
    for i in "${!temps[@]}"; do
        t=${temps[$i]}
        bar=$(printf '%*s' $((t-min+1)) '' | tr ' ' '█')
        printf "%s %3d°F |%s\n" "${times[$i]}" "$t" "$bar"
    done
    echo "Min: $min°F, Max: $max°F"
}

main() {
    log "Fetching weather for $LAT,$LON"
    url=$(get_gridpoint_url)
    log "Forecast URL: $url"
    fetch_temps "$url" | draw_chart
}

main
