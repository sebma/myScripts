#!/usr/bin/env sh

printf "o conf prerequisites_policy follow\no conf build_requires_install_policy yes\no conf commit" | $(which cpan)
$(which cpan) Sort::Naturally YAML Term::ShellUI File::KeePass Log::Log4perl
$(which cpan) -f Term::ReadLine::Gnu Clone Crypt::Rijndael Term::ReadKey
