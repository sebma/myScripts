#!/usr/bin/perl

# $Id: netswitch.pl,v 1.1.1.1 2000/05/31 05:45:02 madebeer Exp $
# run 'netswitch.pl' and it will try to explain itself

# --------------------------------------------------------------------
# 0. Notes, Index

# Notes: 

#  A.  Please email madebeer@igc.apc.org if you have comments or
#  suggestions on netswitch.pl netswitch.pl tries to be careful,
#  however, see $Warnings (below)

#  B.  currently, netswitch.pl hardlinks files, (it does not copy
#  config files).  This means that if you edit config files in
#  $saved_base, it will affect the files in $target_base, and vice
#  versa.  I'm not sure what the right thing to do is.  Comments on
#  this behavior?

#  C.  /etc/rc.d/rc.inet1 is the network initialization script in
#  slackware.  It may be named differently on other distributions.
#  I'd welcome a patch that tests for different setup and behaves
#  correctly.

#  D.  I was reading /etc/dhclient-script, and it looks like with some
#  versions of linux, you need to bring the ethernet interface down
#  before you re-initialize it.  My laptop ( Linux 2.2.14 ) doesn't
#  need this, so this script doesn't do that yet.  I'd welcome a patch
#  that does this.

#  E.  Future plans are to 
#     * create more customizable scripts
#     * ensure compatibility with DHCP and PPP

# Index

# 0. Notes, Index
# 1. setup environment 
# 2. see what configuration sets have already been saved and are
#    available to switch to
# 3. create the Warnings and usage statements
# 4. parse options
# 5. define the locations of the network configuration files in global hashes
#
# 6. Action:
#    A) save the current configuration to a named set of files ... OR
#    B) replace the network config files with a named set of files
#       possibly invoke network-initialization script
#
# 7. define subs

# --------------------------------------------------------------------
# 1. setup environment 

use strict;
use Getopt::Std;
my $maintainer = 'madebeer@igc.apc.org';
my (@known_configs, $usage);
my $saved_base = '/usr/local/etc/netswitch';
-d $saved_base or mkdir ($saved_base, 0755) or die "cannot make $saved_base"; 

my $n = $0; $n =~ s|^.*/||; # remember minimal name of this script

# this is the warning netswitch will emit if
# it can't find the config files it expects

my $incompatible_msg = qq{ Your linux distrib is probably incompatible with netswitch.pl
  Read the 'Notes' ( note C ), in the source code for hints on this.
};

# --------------------------------------------------------------------
# 2. see what configuration sets have already been saved and are available to switch to

opendir(DIR, $saved_base) || die "can't opendir $saved_base: $!";
@known_configs = grep { ! /^\./ && -d "$saved_base/$_" } readdir(DIR);
closedir DIR;

# --------------------------------------------------------------------
# 3. create the warnings and usage statements

my $Warnings = qq{
  Copyright 2000 madebeer\@igc.apc.org, relased under the GPL 
    (see: http://www.gnu.org/)   Email patches to $maintainer
  Use at your own risk -- 
       it works for me on Slackware, and that is all I can say for it.
  $n may destroy your network configuration or otherwise behave badly.
};

$usage = qq{ 
######################################################
 $n [ -sS | -t test_base -e ] [ -q ] config 
######################################################
  Designed for laptop users who switch between non-DHCP networks.
  Switches between the network configs stored in $saved_base.

  -s saves the current network configuration as a new configuration set
  -S like -s, except it will overwrite an existing saved configuration set
  -t testing -- don't overwrite config files in /etc, use 'test_base' instead
  -e invoke the network setup script after overwriting configuration set
  -q quiet -- don't say what program is doing unless there is an error.

  unless using the -s or -S options, 
    currently available configs are ( @known_configs )
  $Warnings
  Examples of Switching to a new Config:

  $n budapest    # overwrites network config files with saved set called 'budapest'
  $n -e budapest # ditto, also invokes network setup script

  Examples of Saving/Creating a new Config:

  $n -s new      # saves current network config files to saved set called 'new'
  $n -S replace  # replaces saved set called 'replace' with current network config files
};

# --------------------------------------------------------------------
# 4. parse options

use vars qw/$opt_s $opt_S $opt_t $opt_q $opt_e/;
getopts('sSt:qe') or die "unknown option in $@ $usage";

my $arg = shift;
chomp($arg);
$arg or ( print "error: missing config" . $usage and exit) ;
die "config has illegal characters -- must be alphanumeric only" if $arg =~ m/\W/;

# figure out whether we would be replacing from/saving to test files or real files
# if we use opt_t, we won't use the real config files, rather use some files stashed in $opt_t

my ($target_base) = $opt_t ? $opt_t : '/etc' ;
my $quiet_f = $opt_q;

# --------------------------------------------------------------------
# 5. define the locations of the network configuration files in global hashes

# %target defines a set of files to overwrite (normally), or save from ( -s or -S)
# %saved  defines a set of files that will overwrite the target files ( normally )

my %target   = ( resolv   => "$target_base/resolv.conf", 
                 hosts    => "$target_base/hosts",
                 networks => "$target_base/networks",
                 inet     => "$target_base/rc.d/rc.inet1");

# this is the command that is run to re-initialize the network settings
my $net_cmd = $target{inet};

my $config_base = "$saved_base/$arg";
my %saved    = ( resolv   => "$config_base/resolv.conf", 
                 hosts    => "$config_base/hosts", 
                 networks => "$config_base/networks",
                 inet     => "$config_base/rc.inet1" );

# --------------------------------------------------------------------

#
# Action:
#

# --------------------------------------------------------------------
# 6. A) save the current configuration to a named set of files ... OR

if ($opt_s or $opt_S) {
  &checkpoint("attempting to save current config to named set: $arg");

  $opt_S or ( -d $config_base and die "$config_base already exists, use -S to overwrite" );

  # check to make sure we have all the files we need

  for ( values %target ) {
    &checkpoint("checking $_");
    -s $_ or die "file $_ missing or empty";
  };

  -d $config_base or 
      mkdir ($config_base, 0775) or 
	  die "cannot mkdir $config_base: [$!]";

  # overwrite orginal files with new config files from saved 

  for ( keys %target ) {
    &checkpoint("saving $target{ $_ } to $saved{ $_ }");
    link_overwrite ( $target{ $_ }, $saved{ $_ }) or 
       die "could not save to $saved{ $_ }";
  };
   
# --------------------------------------------------------------------
# 6. B) replace the network config files with a named set of files

} else {
  &checkpoint("attempting to switch to named set = $arg");

  # first, check to make sure we have all the files we need

  for ( values %saved ) {
    &checkpoint("checking $_");
    -s $_ or die "file $_ missing or empty";
  };

  # check to make sure the files we intend to overwrite already exist.
  # if they do not, it is likely the files are elsewhere (another linux distrib)

  for ( values %target ) {
    &checkpoint("checking $_");
    -s $_ or die "file $_ missing or empty -- $incompatible_msg";
  };
  
  # check to make sure this config has already been saved and is available

  grep {/^$arg$/} @known_configs 
      or die "unknown config [$arg]-- cannot switch to those config files $usage";

  # make a backup copy of all the files before we change the files

  for ( values %target ) {
    &checkpoint("backing up $_");
    link_overwrite ($_, "$_.backup") or die "could not backup file $_.backup";
  };

  # overwrite orginal files with new config files from saved 

  for ( keys %saved ) {
    &checkpoint("overwriting $target{$_} with $saved{$_}");
    link_overwrite ( $saved{ $_ } , $target{ $_ } ) or die "could not overwrite $target{ $_ }";
  };

  # invoke the new network configuration
  system($net_cmd) if $opt_e;

};

exit;

# --------------------------------------------------------------------
# 7. define subs

sub link_overwrite($$){
    my ($saved, $target) = @_;
    -f $target && unlink $target;
    link ($saved, $target) or return undef;
    return 1;
};

sub checkpoint($){
    print shift, "\n" unless $quiet_f;
}

__END__

# --------------------------------------------------------------------
# $Log: netswitch.pl,v $
# Revision 1.1.1.1  2000/05/31 05:45:02  madebeer
# First Checkin -- code works on Mike's slackware laptop.
#
