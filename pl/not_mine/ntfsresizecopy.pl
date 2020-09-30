#!/usr/bin/perl
# ntfsresizecopy: Copy an NTFS filesystem from one block device to another,
# resizing it to the size of the destination device in the process.  (Uses
# ntfsprogs from http://linux-ntfs.org/doku.php?id=ntfsprogs .)  This is
# EXPERIMENTAL; after using this script, you should mount the destination
# read-only and check that everything looks intact.
#
# usage: ntfsresizecopy SRC DEST
#
# An expanding copy is just done with ntfsclone followed by ntfsresize.
# A shrinking copy is done by running ntfsclone and ntfsresize on devices
# specially crafted with the Linux device-mapper (requires dmsetup and losetup);
# you may save time by checking first that the shrinkage is possible with
# `ntfsresize -n -s SIZE SRC'.
#
# The special shrinking technique should be applicable to any filesystem type
# that has an in-place shrinking command that doesn't write outside the new
# size.  Just change the calls to ntfsclone and ntfsresize; ntfsclone can be
# replaced by a dd of the beginning of the source for filesystems that don't
# have a sparse clone command.
#
# Version 2008.06.01
# Maintained at http://mattmccutchen.net/utils/#ntfsresizecopy .
# -- Matt McCutchen <matt@mattmccutchen.net>

use strict;
use warnings;
use Fcntl qw(SEEK_SET SEEK_CUR SEEK_END);
use List::Util qw(min);
use filetest 'access';
$| = 1;

# These are not currently used but might be useful when modifying this script
# for a filesystem that doesn't have an ntfsclone analogue.
#my $shownProgress = ''; # cursor at its end
#sub showProgress($) {
#	my ($newProgress) = @_;
#	my $shrink = length($shownProgress) - length($newProgress);
#	print("\b" x length($shownProgress), $newProgress,
#		$shrink > 0 ? (" " x $shrink, "\b" x $shrink) : ());
#	$shownProgress = $newProgress;
#}
#sub dd(**$) {
#	my ($srcfh, $destfh, $len) = @_;
#	while ($len > 0) {
#		showProgress("$len bytes left");
#		my $chunkLen = min(1048576, $len);
#		sysread($srcfh, my $data, $chunkLen) == $chunkLen or die 'read error';
#		syswrite($destfh, $data, $chunkLen) == $chunkLen or die 'write error';
#		$len -= $chunkLen;
#	}
#	showProgress('');
#}

sub deviceSize(*) {
	# Determine the size of a device by seeking to its end.  The ioctl used
	# by `blockdev --getsize64' might be more official, but this one is
	# easy and perhaps more portable.
	my ($fh) = @_;
	my $origPos = sysseek($fh, 0, SEEK_CUR) or die;
	my $size = sysseek($fh, 0, SEEK_END) or die;
	sysseek($fh, $origPos, SEEK_SET) or die;
	return 0 + $size;
}
# Wrappers for dmsetup and losetup
sub dm_create($@) {
	my ($name, @table) = @_;
	open(my $toDms, '|-', 'dmsetup', 'create', $name) or die;
	print $toDms map(join(' ', @{$_}) . "\n", @table);
	close($toDms) or die "dmsetup create $name failed";
}
sub dm_remove($) {
	my ($name) = @_;
	system('dmsetup', 'remove', $name) and warn "dmsetup remove $name failed";
}
sub losetup($) {
	my ($file) = @_;
	open(my $fromLs, '-|', 'losetup', '-fs', $file);
	my $dev = <$fromLs>;
	close($fromLs) and defined($dev) or die "losetup -fs $file failed";
	chomp($dev);
	return $dev;
}
sub losetup_d($) {
	my ($dev) = @_;
	system('losetup', '-d', $dev) and warn "losetup -d $dev failed";
}

scalar(@ARGV) == 2 or die <<EOU;
usage: ntfsresizecopy SRC DEST
See the comment at the top of the script for more information.
EOU
my ($src, $dest) = @ARGV[0..1];

open(my $srcfh, '<', $src) or die "open($src) for reading failed: $!";
-b $srcfh or die "Source $src must be a block device.\n";
my $srcRdev = (stat(_))[6];
open(my $destfh, '+<', $dest) or die "open($dest) for reading/writing failed: $!";
-b $destfh or die "Destination $dest must be a block device.\n";
my $destRdev = (stat(_))[6];
$srcRdev == $destRdev and die "Source $src and destination $dest must not be "
	. "the same block device.\nUse ntfsresize for in-place resizing.\n";

my ($srcSize, $destSize) = (deviceSize($srcfh), deviceSize($destfh));
# Assume that, since src and dest are block devices, sizes are divisible by 512.
my ($srcBlocks, $destBlocks) = map($_ / 512, $srcSize, $destSize);
my $shrinkBlocks = $srcBlocks - $destBlocks;

print "Going to copy $src ($srcSize bytes) => $dest ($destSize bytes).\n";

if ($shrinkBlocks > 0) {

print "\nSTEP 1: ntfsclone the beginning of the src to the dest.\n";
# Really, clone the whole src to a magical dest consisting of the real dest
# followed by a zero target to make up the size difference.
# Writes outside the dest's size will be lost to the zero target, but that
# doesn't hurt anything.  And under the assumption that the shrinkage is
# possible, ntfsclone copies at most as much data as a simple dd of the
# beginning of the src to the dest would.
my $mdn = "ntfsresizecopy.$$.magicdest";
my $magicDest = "/dev/mapper/$mdn";
# If something in the "eval" fails, still clean up as much as possible.
eval {
	dm_create($mdn,
		[0, $destBlocks, 'linear', $dest, 0],
		[$destBlocks, $shrinkBlocks, 'zero']);
	system('ntfsclone', '--overwrite', $magicDest, $src) and die 'ntfsclone failed.';
};
dm_remove($mdn);
die $@ if $@;

print "\n", <<EOM;
STEP 2: ntfsresize the dest, bringing in the end of the src.
NOTE: Please ignore ntfsresize's remarks about data loss (the src isn't being
written so you haven't lost anything if this fails) and about shrinking the
device (the device is already smaller).
EOM
# Really, resize a magical dest consisting of the real one plus the end of the
# src.  This leaves a shrunken filesystem on the beginning of the magical dest,
# i.e., on the real dest.
# ntfsresize doesn't seem to write outside the new size, but we use a snapshot
# layer to be extra sure we don't mess up the src.  The snapshot layer needs a
# COW file that is at least one page in size, even though we expect no data to
# be written to it.
my $cowdev;
eval {
	open(my $cowfh, "+>", undef) or die 'failed to create temporary COW file';
	truncate($cowfh, 4096) or die 'failed to expand temporary COW file';
	$cowdev = losetup("/proc/$$/fd/" . fileno($cowfh));
	dm_create($mdn,
		[0, $destBlocks, 'linear', $dest, 0],
		[$destBlocks, $shrinkBlocks, 'snapshot', $src, $cowdev, 'N', 1]);
	open(my $toNr, '|-', 'ntfsresize', '-s', $destSize, $magicDest) or die 'ntfsresize failed.';
	print $toNr "y\n"; # Confirm automatically because we aren't endangering the src.
	close($toNr) or die 'ntfsresize failed.';
};
dm_remove($mdn);
losetup_d($cowdev) if defined($cowdev);
die $@ if $@;

} else {

print "\nSTEP 1: ntfsclone the src to the dest.\n";
system('ntfsclone', '--overwrite', $dest, $src) and die 'ntfsclone failed.';

print "\n", <<EOM;
STEP 2: ntfsresize the dest.
NOTE: Please ignore ntfsresize's remarks about data loss (the src isn't being
written so you haven't lost anything if this fails).
EOM
open(my $toNr, '|-', 'ntfsresize', '-s', $destSize, $dest) or die 'ntfsresize failed.';
print $toNr "y\n"; # Confirm automatically because we aren't endangering the src.
close($toNr) or die 'ntfsresize failed.';

}

print "\nFinished!\n";

