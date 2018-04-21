#!sh

test $REP_SHARE && alias liv=$REP_SHARE/bin/Main.ksh && alias cdl="cd $REP_SHARE/bin"

type sqlplus >/dev/null 2>&1 && mysqlplus() {
	schema=onln
	pw=bancs
	test $ORACLE_SID && {
		echo "=> sqlplus $schema@$ORACLE_SID $@ ..."
		cd && sqlplus $schema/$pw@$ORACLE_SID $@
	} || {
		echo "=> ERROR: The variable <ORACLE_SID> is not defined." >&2
		return 1
	}
}

alias sudo="\sudo "
alias umask="\umask -S"
alias topd10="\du -xsm */ .??*/ 2>/dev/null | sort -n | tail -10"
alias topd5="\du -xsm */ .??*/ 2>/dev/null | sort -n | tail -5"
alias topd="\du -xsm */ .??*/ 2>/dev/null | sort -n | tail -n"
alias od="\od -ctx1"
alias dos2unix='\perl -pi -e "s/\r//g"'
alias unix2dos='\perl -pi -e "s/\n/\r\n/g"'
alias restore_my_stty="\stty erase ^?"
alias env="\env | sort"
alias lastfiles="\find . -type f -cmin -5 -ls"
type vim >/dev/null 2>&1 && alias view="vim -R"
alias dig="\dig +search +short"
#alias ssh="$(which ssh) -qAY"
ssh () { $(which bash) -c ": < /dev/tcp/$1/ssh" && $(which ssh) -qAY $@; }

isLinux=$(uname -s | grep -q Linux && echo true || echo false)
if $isLinux
then
  alias rm="\rm -iv"
  alias psu="\pgrep -lfu \$USER"
  alias pgrep="\pgrep -lf"
  alias ll="LANG=C ls -lF --color=tty --time-style=+'%Y-%m-%d %X'"
  alias llm="ll --block-size=1M"
  alias cp="\cp -uv"
  alias diff='\diff --suppress-common-lines'
  alias sdiff='\sdiff -Ww $(tput cols)'
  alias mv="\mv -v"
  alias df="\df -h"
  alias grep="\grep --color"
  alias egrep="\egrep --color"
  alias rgrep="\egrep --color -r --exclude=*.log --exclude=mbox"
  alias less="\less -r"
  alias findloops='\find . -follow -printf "" 2>&1 | grep -v "Permission denied"'
  test $REP_APPLICATIF && alias version='basename $(readlink $REP_APPLICATIF/${ENVIRONNEMENT}adm/version)'
  alias memUsage="free -m | awk '/^Mem/{print 100*\$3/\$2}'"
  alias processUsage="echo '  RSS  %MEM  %CPU COMMAND';\ps -e -o rssize,pmem,pcpu,args | sort -nr | cut -c-156 | head -500 | awk '{printf \"%9.3fMiB %4.1f%% %4.1f%% %s\n\", \$1/1024, \$2,\$3,\$4}'"
  alias swapUsage="free -m | awk '/^Swap/{print 100*\$3/\$2}'"
 	if [ $(mpstat -V 2>&1 | awk '/version/{print$NF}' | cut -d. -f1) -gt 7 ]
  then
    alias cpuUsage="mpstat | tail -1 | awk '{print 100-\$NF}'" 
  else
    alias cpuUsage="mpstat | tail -1 | awk '{print 100-\$(NF-1)}'"
  fi
else
  uname -s | grep -q AIX && alias stat=istat
  alias rm="\rm -i"
  alias psu="\ps -fu \$USER"
  alias ls="ls -F"
  alias ll="ls -lF"
  alias sdiff='\sdiff -w $(tput cols)'
  alias rgrep="\grep -r"
  getIP() { ip -4 addr show $@ | awk '/inet/{print$2}' ; }
  function readlink() {
    for file
    do
      test -h $file && {
        \ls -l $file | awk '{print$NF}'
      }
    done
  }
  function pgrep() {
    processName=$1
    echo "     PID     PPID     TT     USER  STARTED        TIME COMMAND" >&2
    \ps -eo pid,ppid,tty,user,start,time,args | egrep -wv "egrep|cut" | egrep "$processName" | cut -c1-$(tput cols)
  }
fi

build_in_HOME() {
  test -s configure || {
   test -x bootstrap.sh && time ./bootstrap.sh
   test -x autogen.sh && time ./autogen.sh --prefix=$HOME/gnu $@
  }
  test -s Makefile || time ./configure --prefix=$HOME/gnu $@
  test -s Makefile && time make && make install
}

httpserver() {
  mkdir -p ~/log
  fqdn=$(host $(hostname) | awk '/address/{print$1}')
  test $1 && port=$1 || port=1234
  test $port -lt 1024 && {
    echo "=> ERROR: Only root can bind to a tcp port lower than 1024." >&2
    return 1
  }

  \ps -fu $USER | grep -v grep | grep -q SimpleHTTPServer && echo "=> SimpleHTTPServer is already running on $fqdn:$(\ps -fu $USER | grep -v awk | awk '/SimpleHTTPServer/{print$NF}')/" || {
    logfilePrefix=SimpleHTTPServer_$(date +%Y%m%d)
    nohup python -m SimpleHTTPServer $port >~/log/${logfilePrefix}.log 2>&1 &
    test $? = 0 && {
      echo "=> SimpleHTTPServer started on $fqdn:$port/"
      echo "=> logFile = ~/log/${logfilePrefix}.log"
    }
  }
}

alias pkill >/dev/null 2>&1 && unalias pkill
pkill() {
  test "$1" && {
    echo "=> Before :" && pgrep -lf "$1" && $(which pkill) -f "$1"
    echo "=> After :" && pgrep -lf "$1"
  }
}

find_ip_aliases() {
  server=$1
  test $server || {
    echo "=> Usage: $FUNC_NAME <server name or IP>." >&2
    return 1
  }

  case $(uname -s) in
    AIX)   ifconfig=/usr/sbin/ifconfig;;
    Linux) ifconfig=/sbin/ifconfig;;
    SunOS) ifconfig=/usr/sbin/ifconfig;;
    *)
  esac
  case $server in
  127.0.0.1|localhost) $ifconfig | grep -B1 'inet addr' | awk -F' *|:' '/inet addr/{print$4}' | egrep -v '^127.0.0.1|^172\.' | while read ip; do echo ip=$ip hostname=$(host $ip | awk '{print$NF}'); done
  ;;
  *) ssh $server "/sbin/ifconfig | grep -B1 'inet addr' | awk -F' *|:' '/inet addr/{print\$4}' | egrep -v '^127.0.0.1|^172\.' | while read ip; do echo ip=\$ip hostname=\$(host \$ip | awk '{print\$NF}'); done" 2>/dev/null
  ;;
  esac
}

type finger >/dev/null 2>&1 || finger() {
  test $1 && argList=$* || argList=$(who | awk '{print$1}')
  for user in $argList
  do
    awk -F":|," /$user/'{print$1":"$5}' /etc/passwd
  done
}

if $isLinux
then
  function topf5() { find . -xdev -type f -size +10M $@ -printf "%M %n %u %g %k %AY-%Am-%Ad %AX %p\n" 2>/dev/null | sort -nk5 | tail -5|awk '{size=$5/1024;sub($5,size"M");print}'|column -t;}
  function topf10(){ find . -xdev -type f -size +10M $@ -printf "%M %n %u %g %k %AY-%Am-%Ad %AX %p\n" 2>/dev/null | sort -nk5 | tail |  awk '{size=$5/1024;sub($5,size"M");print}'|column -t;}
  function topf () {
    nbLines=$1
    test $nbLines && {
      shift
      find . -xdev -type f -size +10M $@ -printf "%M %n %u %g %k %AY-%Am-%Ad %AX %p\n" 2>/dev/null | sort -nk5 | tail -n $nbLines | awk '{size=$5/1024;sub($5,size"M");print}' | column -t
    }
  }
  function compressBigTextFiles() {
    find . -xdev -type f -size +10M $@ -exec ls -l {} \; 2>/dev/null | sort -nk5 | tail | awk '{print$NF}' | while read file
    do
      echo "=> file = $file" >&2
			file $file | grep -q text && {
				test -w $(dirname $file) && time gzip $file || echo "=> ERROR: You dont have write access to the directory $(dirname $file)." >&2
			}
    done
  }
else
  function topf5 (){ find . -xdev -type f -size +20480 $@ -exec ls -l {} \; 2>/dev/null | sort -nk5 | tail -5 | awk '{size=$5/2^20;sub($5,size"M");print}';}
  function topf10(){ find . -xdev -type f -size +20480 $@ -exec ls -l {} \; 2>/dev/null | sort -nk5 | tail | awk '{size=$5/2^20;sub($5,size"M");print}'; }
  function topf () {
    nbLines=$1
    test $nbLines && {
      shift
      find . -xdev -type f -size +20480 $@ -exec ls -l {} \; 2>/dev/null | sort -nk5 | tail -n $nbLines | awk '{size=$5/2^20;sub($5,size"M");print}'
    }
  }
fi

stelnet() {
  test $# != 2 && {
    echo "=> Usage: $FUNC_NAME <server name or IP> <port number>" >&2
    return 1
  }

#  if echo $1 | grep -qi [a-z]
#  then
#    host $1 >/dev/null || {
#      echo "Host $1 not found: 3(NXDOMAIN)" >&2
#      return 1
#    }
#  fi

#  message=$(echo quit | openssl s_client -connect $1:$2 2>&1)
#  codeRet=$?
#  echo "$message" | \egrep --color "CONNECTED|refused|connect:"

	$(which bash) -c ": < /dev/tcp/$1/$2" && echo "=> The route to <$1:$2/tcp> is OK."

  return $codeRet
}

lstgz() {
  for archive
  do
	  file "$archive" | grep -q gzip && {
      echo "=> file = $archive"
      echo
			gunzip -c "$archive" | tar -tvf-
		} && echo "=> Error: <$archive> is not a GZ format file." >&2
  done
}

tarfind() {
  test $# -lt 2 && {
    echo "=> Usage: tarfind <searched filename extended regular expression> <TAR archive filename(s) globbing pattern>" >&2
    return 1
  }

  pattern=$1
  shift
  for tarFile
  do
    tar -tf $tarFile | egrep $pattern && echo "=> Found in <$tarFile>" && break
  done
}

gzfind() {
  test $# -lt 2 && {
    echo "=> Usage: gzfind <searched filename extended regular expression> <TARGZ archive filename(s) globbing pattern>" >&2
    return 1
  }

  pattern=$1
  shift
  for targzFile
  do
    \gunzip -c $targzFile | tar -tf- | egrep $pattern && echo "=> Found in <$targzFile>" && break
  done
}

testTCPRoute() {
  test $# != 2 && return 1
  remoteServer=$1
  remotePort=$2
  uname -s | grep -q Linux && grepOption="--color"
  echo "=> Testing the route to <$remoteServer> on $remotePort/tcp ..."
  connectionTestTool=$(type nc telnet openssl 2>/dev/null | awk 'NR==1{print$1}')
  case $connectionTestTool in
    nc) connectionTestCmd="nc -vz $remoteServer $remotePort 2>&1 | grep $grepOption succeeded" ;;
    telnet) connectionTestCmd="echo | telnet $remoteServer $remotePort | grep $grepOption Connected" ;;
    openssl) connectionTestCmd="echo quit | openssl s_client -connect $remoteServer:$remotePort | grep $grepOption CONNECTED" ;;
    *) connectionTestCmd=false ;;
  esac
  eval $connectionTestCmd && echo "=> The route to <$remoteServer> on $remotePort/tcp is open." || echo "=> The route to <$remoteServer> on $remotePort/tcp is closed." >&2
}

function scp() {
	#scpCommand="$(which rsync) -Pt -uv --rsh=$(which ssh) -qt"
	scpCommand="$(which rsync) -Pt -v"
	$scpCommand -e "$(which ssh) -qt" $@
	test $? = 127 && {
		$scpCommand -e "$(which ssh) -qt" --rsync-path=/usr/local/bin/rsync $@ || $(which scp) $@
	}
}

isOwner () {
	test $# = 1 && test -O "$1" && true || false
}

if $isLinux
then
  lsgroup() {
    for group
    do
      awk -F: /^$group/'{gsub(",","\n");print$4}' /etc/group | while read user
      do
        awk -F":|," /$user/'{print$1":\""$5"\""}' /etc/passwd
      done
    done
  }
fi
