#!/bin/sh

systemctl stop bluetooth.service;sleep 1;systemctl --no-block start bluetooth.service
