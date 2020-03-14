#!/bin/sh

systemctl --no-block stop bluetooth;sleep 1;systemctl --no-block start bluetooth
