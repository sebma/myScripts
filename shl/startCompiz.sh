#!/bin/sh -x
pgrep compiz || { 
  #compiz.real --debug --ignore-desktop-hints --replace --replace move resize place decoration animation ccp &
  compiz&
}
