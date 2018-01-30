#!/usr/bin/env bash

VIDEO_DIR=/mnt/video

fix_mp4() {
  if [ -n "$1" -a -f "$1" ]; then
    newfile="$1.new"
    if [ -f "${newfile}" ]; then
      echo "Output file already exists: ${newfile}"
    else
      AtomicParsley "$1" -T | awk "BEGIN {mdat=0; moov=0} /^Atom mdat / {if (mdat == 0) mdat = NR} /^Atom moov / {if (moov == 0) moov = NR} END {if (mdat == 0 || moov == 0) { ret = 2 } else { ret = moov > mdat ? 0 : 1 }; exit ret}"
      if [ $? -eq 0 ]; then
        output=$(MP4Box -add "$1" "${newfile}" 2>&1)
        # note: MP4Box does not have a usable return value
        #   The only way to tell if it has a problem (with the input file) is
        #   to look for the "Unknown input file type" string in it's output.
        if [ -f "${newfile}" ]; then
          if ! echo "${output}" | fgrep -qis "unknown" > /dev/null 2>&1; then
            if [ $(du -b "${newfile}" | cut -f1) -gt 0 ]; then
              cp "${newfile}" "$1"
            else
              echo "Zero length file: ${newfile}"
            fi
          else
            echo "Failed to process: ${newfile}"
          fi
          rm "${newfile}"
        else
          echo "Failed to process (no new file was created): $1"
        fi
      elif [ $? -eq 2 ]; then
        echo "The processed MP4 file has no moov or mdat atom: $1"
      fi
    fi
  else
    echo "Parameter is empty or not a file: $1"
  fi
}

IFS=$'\n'
# note: the "-mmin +5" option is there so we don't try to fix files that are
# still being written to disk (eg. they're still being uploaded to the server)
find "${VIDEO_DIR}" -type f -mmin +5 -iname "*.mp4" -print0 | sort -z | while IFS="" read -r -d "" file; do
  fix_mp4 "${file}"
done

