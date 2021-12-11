#!/usr/bin/env bash

sudo iptables -t nat -A OUTPUT -p tcp --dport 1935 -j REDIRECT
