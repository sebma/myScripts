#!/bin/sh

apt-get install perl
#yum install perl

#yum install perl-CPAN

perl -MO=Deparse -MCPAN -e "install +URI::URL"
perl -MO=Deparse -MCPAN -e "install +HTTP::Date"
perl -MCPAN -e 'install HTML::TagParser'
perl -MCPAN -e 'install HTML::LinkExtractor'
perl -MCPAN -e 'install HTTP::Cookies'
perl -MCPAN -e 'install HTTP::Status'
perl -MCPAN -e 'install URI'
perl -MCPAN -e 'install CSS'
perl -MCPAN -e 'install HTTP::Date'
perl -MCPAN -e 'install Getopt::Long'
#perl -MCPAN -e 'Log::Log4perl'
#perl -MCPAN -e 'Log::Log4perl::Appender'
#perl -MCPAN -e 'Log::Log4perl::Level'

#yum install log4j
apt-get install log4j

apt-get install curl libcurl3 libcurl3-dev
#yum install curl

apt-get install python
#yum install python


