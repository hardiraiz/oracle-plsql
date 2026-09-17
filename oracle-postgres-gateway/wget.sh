#!/bin/sh

#
# Generated on Wed Aug 26 07:40:22 GMT 2026

# Start of user configurable variables
#
LANG=C
export LANG

# Path to wget command
WGET=/usr/bin/wget

# Log directory, log file and output directory
LOGDIR=.
OUTPUT_DIR=.
LOGFILE=$LOGDIR/wgetlog-$(date +%m-%d-%y-%H:%M).log

# End of user configurable variable
#
# Logging functions
log_info() {
   echo "[INFO] [$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOGFILE" 
}

log_error() {
   echo "[ERROR] [$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOGFILE" >&2 
}

# Ask user for access token
echo "Please paste your access token and press Enter:"
ACCESS_TOKEN=""

while IFS= read -r -s -n1 char; do
   [ -z "$char" ] && break
   ACCESS_TOKEN+="$char"
done

echo $ACCESS_TOKEN

# download function
download_file() {
   FILE="$1"
   URL="$2"
   log_info "Download initiated (background) for: $FILE"
   {
      if "$WGET" --header="Authorization: Bearer $ACCESS_TOKEN" -nv --show-progress "$URL" -O "$OUTPUT_DIR/$FILE" >> "$LOGFILE" 2>&1; then
         log_info "Download completed: $FILE (saved to: $OUTPUT_DIR/$FILE)"
      else
         log_info "Download failed (invalid or expired URL): $FILE"
      fi
   } &
}

# Start of script
log_info "==== Script Started ===="

# Check if wget exists
if [ ! -x "$WGET" ]; then
   log_error "wget not found at $WGET"
   exit 1
fi

# Print wget version info to log file 
echo "Wget version info: 
------------------------------
$($WGET -V) 
------------------------------" > "$LOGFILE" 2>&1 

# Start downloads in parallel

download_file "V1054595-01.zip" "https://edelivery.oracle.com/osdc/softwareDownload?fileName=V1054595-01.zip&token=YmlycVhBTTlBNnhQd0VEbTF6YmIwZyE6OiFmaWxlSWQ9MTI1OTI3MzUxJmZpbGVTZXRDaWQ9MTIxMzMwNiZyZWxlYXNlQ2lkcz0xMjEzMDUyJnBsYXRmb3JtQ2lkcz0zNSZkb3dubG9hZFR5cGU9OTU3NjQmYWdyZWVtZW50SWQ9MTI5OTM4MjcmZW1haWxBZGRyZXNzPW11aGFtbWFkLnJhaXpAbWlpLmNvLmlkJnVzZXJOYW1lPUVQRC1NVUhBTU1BRC5SQUlaQE1JSS5DTy5JRCZpcEFkZHJlc3M9MTQ0LjEyNS41Ni4yMjQmdXNlckFnZW50PU1vemlsbGEvNS4wIChYMTE7IFVidW50dTsgTGludXggeDg2XzY0OyBydjoxNTMuMCkgR2Vja28vMjAxMDAxMDEgRmlyZWZveC8xNTMuMCZjb3VudHJ5Q29kZT1JRCZkbHBDaWRzPTEyMTM0MDk"

log_info "All download(s) initiated in background."
echo "Please check logfile for more details: $LOGFILE" 

# Wait for all background downloads to finish
wait

# End of script
log_info "==== Script Finished ===="
