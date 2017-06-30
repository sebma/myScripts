#!/usr/bin/env ksh

alias ct=$CLEARCASE/bin/cleartool

pVobName=$(cleartool lsvob -short | awk '/pvob/')
vobName=$(cleartool lsvob -short | awk '!/pvob/')
alias lsstream="cleartool lsstream -invob $pVobName"
alias ctman="cleartool man"
alias siv="cleartool setview -login ${USER}_ELA_Integration "
alias srv="cleartool setview -login ${USER}_ELA_Livraison"
alias shv="cleartool setview -login ${USER}_ELA_HOMO_Liv"

setview() {
  test "$1" && cleartool setview -login "$1" || cleartool lsview -s
}

setact() {
  test "$1" && {
    cleartool setact "$1"
  } || cleartool lsact -s
}

alias lsview="cleartool lsview -s"
alias lsvob="cleartool lsvob -s"
alias lscomp="cleartool lscomp -s -invob $pVobName"
alias lsbl="cleartool lsbl -comp $(cleartool lscomp -s -invob $pVobName)@$pVobName"

getbaseline() {
  local pvobPath=/vobs/pvob_ela
  test $# = 0 && {
    cleartool lsstream -invob $pvobPath -s
    return 1
  }

  for stream
  do
    printf "=> stream = $stream, baseline = "
    cleartool lsstream -fmt "%[found_bls]p\n" $stream@$pvobPath
  done
}

env | grep -q CLEARCASE_ROOT && {
  alias lsvt='cleartool lsvt -a -s'
#  alias ctchmod='cleartool protect -chmod'
  alias lsact="cleartool lsact -s"
  alias lscact="cleartool lsact -cact"
  alias lsco="cleartool lsco -s"
  alias lsproject="cleartool lsproject -cview"
  alias baseline="cleartool lsstream -fmt %[found_bls]CXp | cut -d: -f2"
  alias cview="cleartool lsview -cview"
  alias cstream="cleartool lsstream -s"
  alias cact="cleartool lsact -cact"
  alias cbl='cleartool lsstream -fmt "%[found_bls]p\n"'
  alias ctdiff="cleartool diff -columns 176"
  alias setcs="cleartool setcs -stream"
  findact() {
    test $# -eq 0 && echo "=> Finds associated activities with each element querried, usage: $FUNCNAME [elements list]" >&2 && return 1
    for object
    do
      echo $object
      echo $object | grep -q "^(.*)" && continue
      test $object && cleartool desc $object | grep activity:.
    done
  }
  rebase() {
    local newBaseLine=$1
    test $newBaseLine && {
      cleartool rebase -baseline $newBaseLine -complete
#      exit
      } || cleartool lsbl -comp $(cleartool lscomp -s -invob $pVobName)@$pVobName -short
  }
  changeact() {
    local dstAct=$1
    test $# -gt 1 && {
      shift
      for elem
      do
        currAct=$(cleartool desc $elem | awk -F'"' '/activity:./{print$2}')
        #time cleartool lsact -l $currAct | grep $(cleartool lsvob -short | awk '!/pvob/') | \xargs -tl cleartool chact -fcset $currAct -tcset $dstAct
        echo cleartool chact -fcset "$currAct" -tcset $dstAct $elem ...
        cleartool chact -fcset "$currAct" -tcset $dstAct $elem
      done
    } || {
      echo "=> Moves all objects from their current activity to another, usage: $FUNCNAME <dstAct> [elements list]"
      echo "=> Please choose a destination activity among the following list:"
      cleartool lsact -short
      return 1
    } >&2
  }
}


