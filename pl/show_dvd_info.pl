#!C:\Program Files\TinyPerl\tinyperl.exe -w

$MPlayerCmd = "$ENV{ProgramFiles}\\MPlayer for Windows\\mplayer.exe";

$MPlayerArgs = "-vo null -ao null -frames 0 -identify -dvd-device l: dvd://";
@MPlayerOutput =`"$MPlayerCmd" $MPlayerArgs 2> nul`;

$I = 0;
$NbChapiters = 1;
$TitleNumber = 0;
foreach( @MPlayerOutput ) {
  #On recupere l'ID du titre qui a le plus grand nombre de chapitres
  if( /^ID_DVD_TITLE_\d+_CHAPTERS=\d+$/ ) {
		#Equivalent d'un "pipe" cut -d"=" -f1- => Recupere tous les champs
		@TMP1 = split( /=/ );
		if( $TMP1[1] > $NbChapiters ) { 
			#On recupere le 2eme champ apres le "=" <=> "| cut -d"=" -f2 (ATTENTION: Les tableaux Perl sont indexes a partir de 0, comme en C/C++ etc...)
			$NbChapiters = $TMP1[1];
			
			#On recupere le 4eme champ apres le "_" <=> "| cut -d"_" -f4 (ATTENTION: Les tableaux Perl sont indexes a partir de 0, comme en C/C++ etc...)
			@TMP2 = split( /_/ );		
			$TitleNumber = $TMP2[3];
		}
		print "=> Line[ " . $I . " ] = $_";
		#last;
  }
	print if /^ID_/;
  $I++;
}

#OU PLUS LISIBLEMENT
$I = 0;
$NbChapiters = 1;
$TitleNumber = 0;
foreach $Line ( @MPlayerOutput ) {
  #On recupere l'ID du titre qui a le plus grand nombre de chapitres
  if( /^ID_DVD_TITLE_\d+_CHAPTERS=\d+$/ ) {
		#Equivalent d'un "pipe" cut -d"=" -f1- => Recupere tous les champs
		@TMP1 = split( /=/, $Line );
		if( $TMP1[1] > $NbChapiters ) { 
			#On recupere le 2eme champ apres le "=" <=> "| cut -d"=" -f2 (ATTENTION: Les tableaux Perl sont indexes a partir de 0, comme en C/C++ etc...)
			$NbChapiters = $TMP1[1];

			#On recupere le 4eme champ apres le "_" <=> "| cut -d"_" -f4 (ATTENTION: Les tableaux Perl sont indexes a partir de 0, comme en C/C++ etc...)
			@TMP2 = split( /_/, $Line );		
			$TitleNumber = $TMP2[3];
		}
		print "=> Line[ " . $I . " ] = $Line";
		#last;
  }
	print $Line if $Line =~ /^ID_/;
  $I++;
}

#`pause`;
exit 0;

