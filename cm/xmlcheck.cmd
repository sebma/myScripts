@echo off
::xmlstarlet validate --err %*
::xml validate --err %*
xmllint --noout %*
