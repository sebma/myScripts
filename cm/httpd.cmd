@echo off
if not defined port set port=1234
start /b python -m SimpleHTTPServer %port%
