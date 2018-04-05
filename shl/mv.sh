function mv {
  local codeRet=0
  local lastArg="$(eval echo \$$#)"
  local isDirectory=$(file "$lastArg" | grep -q directory && echo true || echo false)
  alias cp="rsync -Pt"

  if `$isDirectory`
  then
    echo $(which mv) $(echo "$@" | sed "s/$lastArg//")/
  else
    for file
    do
    :
    #cp -p $file $destination
    done
  fi
}

