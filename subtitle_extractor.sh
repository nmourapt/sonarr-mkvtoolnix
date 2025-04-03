#!/bin/bash

# Function for regular output (stdout)
log_info() {
    echo "$1"
}

# Function for error messages (stderr)
log_error() {
    echo "$1" >&2
}

# Check if this is a Sonarr test event
if [ "$sonarr_eventtype" = "Test" ]; then
    log_info "Sonarr test event detected. Script is functioning correctly."
    exit 0
fi

# Determine the input file path
input_file=""
if [ $# -gt 0 ]; then
    input_file="$1"
    log_info "Using command line argument path: $input_file"
elif [ ! -z "$sonarr_episodefile_paths" ]; then
    input_file="$sonarr_episodefile_paths"
    log_info "Using sonarr_episodefile_paths: $input_file"
else
    log_error "Error: No input file provided. Either pass as argument or set sonarr_episodefile_paths environment variable."
    exit 1
fi

# Check if the file exists
if [ ! -f "$input_file" ]; then
    log_error "Error: File not found: $input_file"
    exit 1
fi

# Get the directory and filename without extension
dir_path=$(dirname "$input_file")
file_name=$(basename "$input_file" .mkv)
output_file="${dir_path}/${file_name}.pt.srt"

log_info "Scanning for European Portuguese subtitles in: $input_file"

# Run mkvinfo and capture the output
mkvinfo_output=$(mkvinfo "$input_file" 2>&1)
if [ $? -ne 0 ]; then
    log_error "Error running mkvinfo: $mkvinfo_output"
    exit 1
fi

# Initialize variables
pt_pt_track_id=""
found_pt_pt=false

# Process the mkvinfo output to find European Portuguese subtitles
while IFS= read -r line; do
    # When we find a new track, reset the tracking variables but keep the track number
    if [[ "$line" =~ "Track number:" ]]; then
        # Extract track ID for mkvmerge & mkvextract from the line
        track_id=$(echo "$line" | grep -oP 'track ID for mkvmerge & mkvextract: \K[0-9]+')
        is_subtitle=false
        is_portuguese=false
        is_european=false
    fi
    
    # Check if it's a subtitle track
    if [[ "$line" =~ "Track type: subtitles" ]]; then
        is_subtitle=true
    fi
    
    # Check if language is Portuguese
    if [[ "$line" =~ "Language: por" ]]; then
        is_portuguese=true
    fi
    
    # Check for European Portuguese (pt-PT)
    if [[ "$line" =~ "Language (IETF BCP 47): pt-PT" ]] || [[ "$line" =~ "Name: Portuguese (Portugal)" ]]; then
        is_european=true
    fi
    
    # If we have all three conditions and we haven't found a track yet, save the track ID
    if [[ "$is_subtitle" == true && "$is_portuguese" == true && "$is_european" == true && "$found_pt_pt" == false ]]; then
        pt_pt_track_id="$track_id"
        found_pt_pt=true
        log_info "Found European Portuguese subtitle track with ID: $pt_pt_track_id"
    fi
done <<< "$mkvinfo_output"

# If we found an European Portuguese subtitle track, extract it
if [[ "$found_pt_pt" == true ]]; then
    log_info "Extracting European Portuguese subtitles to: $output_file"
    
    # Run mkvextract
    extraction_output=$(mkvextract "$input_file" tracks "${pt_pt_track_id}:${output_file}" 2>&1)
    exit_code=$?
    
    # Log the extraction output
    log_info "$extraction_output"
    
    # Check if extraction was successful
    if [ $exit_code -eq 0 ]; then
        log_info "Subtitle extraction completed successfully."
    else
        log_error "Failed to extract subtitles. Exit code: $exit_code"
        exit 1
    fi
else
    log_error "No European Portuguese subtitles found in the file."
    exit 0
fi