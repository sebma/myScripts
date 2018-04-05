$NUMREQ = @ARGV[0];
$SFN = @ARGV[1];
$DIRECTION = @ARGV[2];
$SPN = @ARGV[3];
$DSN = @ARGV[4];
$TRC = @ARGV[5];
$PRC = @ARGV[6];

$DSN =~ s/\\/\//g;
$PRC =~ s/0/2/;

exec ("toto_1.cmd critical $component $envir \"$NUMREQ | $SFN | $SPN | $DSN | $DIRECTION | 000 | $TRC | $PRC\"");
