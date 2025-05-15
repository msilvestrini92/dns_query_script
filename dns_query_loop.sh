#!/bin/bash

DOMAIN_FILE="domains.txt"
DNS_SERVERS=("X.X.X.X" "Y.Y.Y.Y")
DURATION=60  # in seconds
INTERFACE="eth1"

# Generate timestamp and file names
START_TIMESTAMP=$(date "+%Y-%m-%dT%H:%M:%S")
PCAP_FILE="dns_capture_${START_TIMESTAMP//[:]/-}.pcap"  # Replace : with - for filename safety"
LOG_FILE="dns_query_log_${START_TIMESTAMP}.csv"

# Ask for sudo access up front
sudo -v || { echo "Sudo authentication failed"; exit 1; }

# Start tcpdump in background
echo "Starting tcpdump..."
sudo tcpdump -i "$INTERFACE" port 53 -w "$PCAP_FILE" > /dev/null 2>&1 &
TCPDUMP_PID=$!

# Trap to ensure tcpdump is stopped if script is interrupted
trap 'echo "Stopping tcpdump..."; sudo kill $TCPDUMP_PID; exit' INT TERM

# Write CSV header
echo '"timestamp","domain","nameserver","query_time_ms"' > "$LOG_FILE"

# DNS query loop
echo "Starting DNS loop for $DURATION seconds..."
END=$((SECONDS + DURATION))
while [ $SECONDS -lt $END ]; do
  while IFS= read -r domain; do
    for dns in "${DNS_SERVERS[@]}"; do

      # Get current timestamp in RFC 3399 format
      timestamp=$(date "+%Y-%m-%dT%H:%M:%S.%N%z")
      timestamp="${timestamp:0:-2}:${timestamp: -2}"

      # Capture dig output
      output=$(dig @"$dns" "$domain" +time=1 +tries=1)

      # Extract query time
      query_time=$(echo "$output" | awk '/Query time:/ { print $4 }')

      # Write log to file
      echo "\"$timestamp\",\"$domain\",\"$dns\",\"$query_time\"" >> "$LOG_FILE"
    done
  done < "$DOMAIN_FILE"
done

# Stop tcpdump after queries finish
echo "Stopping tcpdump..."
sudo kill "$TCPDUMP_PID"
wait "$TCPDUMP_PID" 2>/dev/null
echo "Capture saved to $PCAP_FILE"

# Print top 10 slowest queries
echo -e "\nTop 10 slowest DNS queries:"
{
  head -n 1 "$LOG_FILE"
  tail -n +2 "$LOG_FILE" | \
    sed 's/^"\(.*\)","\(.*\)","\(.*\)","\(.*\)"$/\1,\2,\3,\4/' | \
    sort -t, -k4,4nr | \
    head -n 10 | \
    awk -F, '{printf "\"%s\",\"%s\",\"%s\",\"%s\"\n", $1, $2, $3, $4}'
}
