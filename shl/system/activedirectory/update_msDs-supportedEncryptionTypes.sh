#!/usr/bin/env bash

man msktutil | sed -n '/^\s*--dont-change-password/,/^$/ p;/^\s*--enctypes/,/0x10/ p'
test $(id -u) == 0 && sudo="" || sudo=$(type -P sudo)
$sudo msktutil update --dont-change-password --enctypes 0x18
