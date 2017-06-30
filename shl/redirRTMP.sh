#!/usr/bin/env sh

sudo iptables -t nat -A OUTPUT -p tcp --dport 1935 -j REDIRECT
