#!/usr/bin/perl

use File::Spec

print File::Spec->abs2rel(@ARGV) . "\n"
