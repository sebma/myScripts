#!/usr/bin/env bash

time echo "- - -" | sudo tee /sys/class/scsi_host/host*/scan >/dev/null
