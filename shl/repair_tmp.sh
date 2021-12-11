#!/usr/bin/env bash

test -w /tmp || sudo chmod -v 1777 /tmp
test -w /var/tmp || sudo chmod -v 1777 /var/tmp
