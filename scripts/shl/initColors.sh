#!/usr/bin/env bash
#VARIABLES GLOBALES

escapeChar=$'\e'
normal="$escapeChar[m"
declare -A color=( [bold]="$escapeChar[1m" [blink]="$escapeChar[5m" [red]="$escapeChar[31m" [green]="$escapeChar[32m" [blue]="$escapeChar[34m" [cyan]="$escapeChar[36m" [yellowOnRed]="$escapeChar[33;41m" [greenOnBlue]="$escapeChar[32;44m" [yellowOnBlue]="$escapeChar[33;44m" [cyanOnBlue]="$escapeChar[36;44m" [whiteOnBlue]="$escapeChar[37;44m" [redOnGrey]="$escapeChar[31;47m" [blueOnGrey]="$escapeChar[34;47m" )

function initColors {
	local escapeChar=$'\e'
	normal="$escapeChar[m";
	bold="$escapeChar[1m";
	blink="$escapeChar[5m";
	red="$escapeChar[31m";
	green="$escapeChar[32m";
	blue="$escapeChar[34m";
	cyan="$escapeChar[36m";
	yellowOnRed="$escapeChar[33;41m";
	greenOnBlue="$escapeChar[32;44m";
	yellowOnBlue="$escapeChar[33;44m";
	cyanOnBlue="$escapeChar[36;44m";
	whiteOnBlue="$escapeChar[37;44m";
	redOnGrey="$escapeChar[31;47m";
	blueOnGrey="$escapeChar[34;47m"
}
