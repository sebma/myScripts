#!/bin/sh

systemctl --no-block stop bluetooth.service;sleep 1;systemctl --no-block start bluetooth.service
