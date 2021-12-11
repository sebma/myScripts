#!/usr/bin/env bash

cpan="command cpan"
printf "o conf prerequisites_policy follow\no conf build_requires_install_policy yes\no conf commit" | $cpan
$cpan Sort::Naturally YAML Term::ShellUI File::KeePass Log::Log4perl
$cpan -f Term::ReadLine::Gnu Clone Crypt::Rijndael Term::ReadKey
