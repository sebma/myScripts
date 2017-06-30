set -x
time mencoder -endpos $2 -mc 0 -noskip -of mpeg -ovc copy -oac copy "$1" -o "`./basename \"$1\" .ts`.mpg"
set +x
