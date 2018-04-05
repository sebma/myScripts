alias memUsage="free -m | awk '/^Mem/{print 100*\$3/\$2}'"
alias processUsage="echo '  RSS  %MEM  %CPU COMMAND';\ps -e -o rssize,pmem,pcpu,args | sort -nr | cut -c-156 | head -500 | awk '{printf \"%9.3fMiB %4.1f%% %4.1f%% %s\n\", \$1/1024, \$2,\$3,\$4}'"
alias swapUsage="free -m | awk '/^Swap/{print 100*\$3/\$2}'"
alias cpuUsage="mpstat | tail -1 | awk '{print 100-\$(NF-1)}'"
