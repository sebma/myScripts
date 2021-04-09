#
# Copy junction points
#
# Usage: (Copy junction points from C: drive to F: drive:
#
# % dir /s /a:l c:\ | perl cplink.pl f: > mklinks.bat
# % @mklinks.bat
#
use strict;

die "Usage: cplink.pl <DESTINATION DRIVE LETTER>\n" unless $#ARGV > -1;

our $destdrive = shift;
$destdrive .= ":" unless $destdrive =~ /:$/;
our $dir = ".";
while (<>) {
    if (/Directory of (.*)\r/) {
	$dir = $1;
	$dir =~ s/^.:/$destdrive/;
    }
    if (/JUNCTION>\s+([^\[]*)\[(.*)\]/) {
	my $link = $1;
	my $target = $2;
	print "mklink /j \"$dir\\$link\" \"$target\"\n";
    }
}
