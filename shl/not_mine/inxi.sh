#!/usr/bin/env bash
########################################################################
SELF_NAME='inxi' 
# don't quote the following, parsers grab these too
SELF_VERSION=2.3.40
SELF_DATE=2017-09-21
SELF_PATCH=00
########################################################################
####  SPECIAL THANKS
########################################################################
####  Special thanks to all those in #lsc and #smxi for their tireless 
####  dedication helping test inxi modules.
########################################################################
####  ABOUT INXI
########################################################################
####  inxi is a fork of infobash 3.02, the original bash sys info tool by locsmif
####  As time permits functionality improvements and recoding will occur.
####
####  inxi, the universal, portable, system information tool for irc.
####  Tested with Irssi, Xchat, Konversation, BitchX, KSirc, ircII,
####  Gaim/Pidgin, Weechat, KVIrc and Kopete.
####  Original infobash author and copyright holder:
####  Copyright (C) 2005-2007  Michiel de Boer a.k.a. locsmif
####  inxi version: Copyright (C) 2008-2017 Harald Hope
####                Additional features (C) Scott Rogers - kde, cpu info
####  Further fixes (listed as known): Horst Tritremmel <hjt at sidux.com>
####  Steven Barrett (aka: damentz) - usb audio patch; swap percent used patch
####  Jarett.Stevens - dmidecde -M patch for older systems with the /sys 
####
####  Current script home page/wiki/git: https://github.com/smxi/inxi 
####  Documentation/wiki pages will move to https://smxi.org soon.
####  Script forums: http://techpatterns.com/forums/forum-33.html
####  IRC support: irc.oftc.net channel #smxi
####  Version control:
####   * https://github.com/smxi/inxi
####   * git: git pull https://github.com/smxi/inxi master
####   * source checkout url: https://github.com/smxi/inxi
####
####  This program is free software; you can redistribute it and/or modify
####  it under the terms of the GNU General Public License as published by
####  the Free Software Foundation; either version 3 of the License, or
####  (at your option) any later version.
####
####  This program is distributed in the hope that it will be useful,
####  but WITHOUT ANY WARRANTY; without even the implied warranty of
####  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
####  GNU General Public License for more details.
####
####  You should have received a copy of the GNU General Public License
####  along with this program.  If not, see <http://www.gnu.org/licenses/>.
####
####  If you don't understand what Free Software is, please read (or reread)
####  this page: http://www.gnu.org/philosophy/free-sw.html
########################################################################
####
#### PACKAGE NAME NOTES
####  * Package names in (...) are the Debian Squeeze package name. Check your 
####    distro for proper package name by doing this: which <application> 
####    then find what package owns that application file. Or run --recommends
####    which shows package names for Debian/Ubuntu, Arch, and Fedora/Redhat/Suse
####
####  DEPENDENCIES
####  * bash >=3.0 (bash); df, readlink, stty, tr, uname, wc (coreutils);
####    gawk (gawk); grep (grep); lspci (pciutils);
####    ps, find (findutils)
####  * Also the proc filesystem should be present and mounted for Linux
####  * Some features, like -M and -d will not work, or will work incompletely,
####    if /sys is missing
####
####	Apparently unpatched bash 3.0 has arrays broken; bug reports:
####	http://ftp.gnu.org/gnu/bash/bash-3.0-patches/bash30-008
####	http://lists.gnu.org/archive/html/bug-bash/2004-08/msg00144.html
####  Bash 3.1 for proper array use
####
####	Arrays work in bash 2.05b, but "grep -Em" does not
####
####  RECOMMENDS (Needed to run certain features, listed by option)
####  -A - for output of usb audio information: lsusb (usbutils)
####  -Ax -Nx - for audio/network module version: modinfo (module-init-tools)
####  -Dx - for hdd temp output (root only default): hddtemp (hddtemp)
####       For user level hdd temp output: sudo (sudo)
####       Note: requires user action for this feature to run as user (edit /etc/sudoers file)
####  -G - full graphics output requires:  glxinfo (mesa-utils); xdpyinfo (X11-utils);
####       xrandr (x11-xserver-utils)
####  -i - IP information, local/wan - ip (iproute) legacy, not used if ip present: ifconfig (net-tools)
####  -I - uptime (procps, check Debian if changed)
####  -Ix - view current runlevel while not in X window system (or with -x): runlevel (sysvinit)
####  -m - all systems, dmidecode, unless someone can find a better way.
####  -M - for older systems whose kernel does not have /sys data for machine, dmidecode (dmidecode)
####  -o - for unmounted file system information in unmounted drives (root only default): file (file)
####       Note: requires user action for this feature to run as user (edit /etc/sudoers file)
####       For user level unmounted file system type output: sudo (sudo)
####  -s   For any sensors output, fan, temp, etc: sensors (lm-sensors)
####       Note: requires setup of lm-sensors (sensors-detect and adding modules/modprobe/reboot,
####       and ideally, pwmconfig) prior to full output being available. 
####  -S   For desktop environment, user must be in X and have xprop installed (in X11-utils)
########################################################################
####  BSD Adjustments
####  * sed -i '' form supported by using SED_I="-i ''".
####  * Note: New BSD sed supports using -r instead of -E for compatibility with gnu sed
####    However, older, like FreeBSD 7.x, does not have -r so using SED_RX='-E' for this.
####  * Gnu grep options can be used if the function component is only run in linux
####    These are the options that bsd grep does not support that inxi uses: -m <number> -o 
####    so make sure if you use those to have them in gnu/linux only sections.
####    It appears that freebsd uses gnu grep but openbsd uses bsd grep, however.
####  * BSD ps does not support --without-headers option, and also does not support --sort <option>
####    Tests show that -m fails to sort memory as expected, but -r does sort cpu percentage.
####  * BSD_TYPE is set with values null, debian-bsd (debian gnu/kfreebsd), bsd (all other bsds)
####  * Subshell and array closing ) must not be on their own line unless you use an explicit \ 
####    to indicate that logic continues to next line where closing ) or )) are located.
########################################################################
####  CONVENTIONS:
####  * Character Encoding: UTF-8 - this file contains special characters that must be opened and saved as UTF8
####  * Indentation: TABS
####  * Do not use `....` (back quotes), those are totally non-reabable, use $(....).
####  * Do not use one liner flow controls. 
####    The ONLY time you should use ';' (semi-colon) is in this single case: if [[ condition ]];then.
####    Never use compound 'if': ie, if [[ condition ]] && statement.
####  * Note: [[ -n $something ]] - double brackets does not require quotes for variables: ie, "$something".
####  * Always use quotes, double or single, for all string values.
####  * All new code/methods must be in a function.

####  * For all boolean tests, use 'true' / 'false'.
####    !! Do NOT use 0 or 1 unless it's a function return. 
####  * Avoid complicated tests in the if condition itself.
####  * To 'return' a value in a function, use 'echo <var>'.
####  * For gawk: use always if ( num_of_cores > 1 ) { hanging { starter for all blocks
####    This lets us use one method for all gawk structures, including BEGIN/END, if, for, etc
####  * Using ${VAR} is about 30% slower than $VAR because bash has to check the stuff for actions
####  SUBSHELLS ARE EXPENSIVE! - run these two if you do not believe me.
####  time for (( i=0; i<1000; i++ )) do ff='/usr/local/bin/foo.pid';ff=${ff##*/};ff=${ff%.*};done;echo $ff
####  time for (( i=0; i<1000; i++ )) do ff='/usr/local/bin/foo.pid';ff=$( basename $ff | cut -d '.' -f 1 );done;echo $ff
####
####  VARIABLE/FUNCTION NAMING:
####  * All functions should follow standard naming--verb adjective noun. 
####	  ie, get_cpu_data
####  * All variables MUST be initialized / declared explicitly, either top of file, for Globals, or using local
####  * All variables should clearly explain what they are, except counters like i, j.
####  * Each word of Bash variable must be separated by '_' (underscore) (camel form), like: cpu_data
####  * Each word of Gawk variable must be like this (first word lower, following start with upper): cpuData
####  * Global variables are 'UPPER CASE', at top of this file.
####	  ie, SOME_VARIABLE=''
####  * Local variables are 'lower case' and declared at the top of the function using local, always.
####	  ie: local some_variable=''
####  * Locals that will be inherited by child functions have first char capitalized (so you know they are inherited).
####	  ie, Some_Variable 
####  * Booleans should start with b_ (local) or B_ (global) and state clearly what is being tested.
####  * Arrays should start with a_ (local) or A_ (global).
####
####  SPECIAL NOTES:
####  * The color variable ${C2} must always be followed by a space unless you know what
####    character is going to be next for certain. Otherwise irc color codes can be accidentally
####    activated or altered.
####  * For native script konversation support (check distro for correct konvi scripts path):
####    ln -s <path to inxi> /usr/share/apps/konversation/scripts/inxi
####    DCOP doesn't like \n, so avoid using it for most output unless required, as in error messages.
####  * print_screen_output " " # requires space, not null, to avoid error in for example in irssi
####  * For logging of array data, array must be placed into the a_temp, otherwise only the first key logs
####  * In gawk search patterns, . is a wildcard EXCEPT in [0-9.] type containers, then it's a literal
####    So outside of bracketed items, it must be escaped, \. but inside, no need. Outside of gawk it should 
####    be escaped in search patterns if you are using it as a literal.
####  
####  PACKAGE MANAGER DATA (note, while inxi tries to avoid using package managers to get data, sometimes 
####  it's the only way to get some data):
####  * dpkg options: http://www.cyberciti.biz/howto/question/linux/dpkg-cheat-sheet.php
####  * pacman options: https://wiki.archlinux.org/index.php/Pacman_Rosetta
####
####  As with all 'rules' there are acceptions, these are noted where used.
###################################################################################
####	KDE Konversation information.  Moving from dcop(qt3/KDE3) to dbus(qt4/KDE4)
###################################################################################
####  * dcop and dbus	-- these talk back to Konversation from this program
####  * Scripting info	-- http://konversation.berlios.de/docs/scripting.html
####    -- http://www.kde.org.uk/apps/konversation/
####  * dbus info	-- http://dbus.freedesktop.org/doc/dbus-tutorial.html
####    view dbus info	-- https://fedorahosted.org/d-feet/
####    -- or run qdbus
####  * Konvi dbus/usage-- qdbus org.kde.konversation /irc say <server> <target-channel> <output>
####  * Python usage	-- http://wiki.python.org/moin/DbusExamples  (just in case)
####
####	Because webpages come and go, the above information needs to be moved to inxi's wiki
########################################################################
####  Valuable Resources
####  CPU flags: http://unix.stackexchange.com/questions/43539/what-do-the-flags-in-proc-cpuinfo-mean
####  Advanced Bash: http://wiki.bash-hackers.org/syntax/pe
####  gawk arrays: http://www.math.utah.edu/docs/info/gawk_12.html
####  raid mdstat: http://www-01.ibm.com/support/docview.wss?uid=isg3T1011259
####               http://www.howtoforge.com/replacing_hard_disks_in_a_raid1_array
####               https://raid.wiki.kernel.org/index.php/Mdstat
####  dmi data: http://www.dmtf.org/sites/default/files/standards/documents/DSP0134_2.7.0.pdf
########################################################################
####  TESTING FLAGS
####  inxi supports advanced testing triggers to do various things, using -! <arg>
####  -! 1  - triggers default B_TESTING_1='true' to trigger some test or other
####  -! 2  - triggers default B_TESTING_2='true' to trigger some test or other
####  -! 3  - triggers B_TESTING_1='true' and B_TESTING_2='true'
####  -! 10 - triggers an update from the primary dev download server instead of source
####  -! 11 - triggers an update from source branch one - if present, of course
####  -! 12 - triggers an update from source branch two - if present, of course
####  -! 13 - triggers an update from source branch three - if present, of course
####  -! 14 - triggers an update from source branch four - if present, of course
####  -! <http://......> - Triggers an update from whatever server you list.
####  LOG FLAGS (logs to $HOME/.inxi/inxi.log with rotate 3 total)
####  -@ 8  - Basic data logging of generated data / array values
####  -@ 9  - Full logging of all data used, including cat of files and system data
####  -@ 10 - Basic data logging plus color code logging
########################################################################
#### VARIABLES
########################################################################

## NOTE: we can use hwinfo if it's available in all systems, or most, to get
## a lot more data and verbosity levels going

### DISTRO MAINTAINER FLAGS ###
# flag to allow distro maintainers to turn off update features. If false, turns off
# -U and -! testing/advanced update options, as well as removing the -U help menu item
# NOTE: Usually you want to create these in /etc/inxi.conf to avoid having to update each time
B_ALLOW_UPDATE='true'
B_ALLOW_WEATHER='true'

### USER CONFIGS: SET IN inxi.conf file see wiki for directions ###
# http://code.google.com/p/inxi/wiki/script_configuration_files
# override in user config if desired, seems like less than .3 doesn't work as reliably
CPU_SLEEP='0.3' 
FILTER_STRING='<filter>'

# for features like help/version will fit to terminal / console screen width. Console
# widths will be dynamically set in main() based on cols in term/console
COLS_MAX_CONSOLE='115'
COLS_MAX_IRC='105'
# note, this is console out of x/display server, will also be set dynamically
# not used currently, but maybe in future
COLS_MAX_NO_DISPLAY='140'
PS_COUNT=5
# change to less, or more if you have very slow connection
DL_TIMEOUT=8
### END USER CONFIGS ###

### LOCALIZATION - DO NOT CHANGE! ###
# set to default LANG to avoid locales errors with , or .
LANG=C
# Make sure every program speaks English.
LC_ALL="C"
export LC_ALL

### ARRAYS ###
## Prep
# Clear nullglob, because it creates unpredictable situations with IFS=$'\n' ARR=($VAR) IFS="$ORIGINAL_IFS"
# type constructs. Stuff like [rev a1] is now seen as a glob expansion pattern, and fails, and
# therefore results in nothing.
shopt -u nullglob
## info on bash built in: $IFS - http://tldp.org/LDP/abs/html/internalvariables.html
# Backup the current Internal Field Separator
ORIGINAL_IFS="$IFS"

## Initialize
A_ALSA_DATA=''
A_AUDIO_DATA=''
A_BATTERY_DATA=''
A_CMDL=''
A_CPU_CORE_DATA=''
A_CPU_DATA=''
A_CPU_TYPE_PCNT_CCNT=''
A_DEBUG_BUFFER=''
A_GCC_VERSIONS=''
A_GLX_DATA=''
A_GRAPHICS_CARD_DATA=''
A_GRAPHIC_DRIVERS=''
A_HDD_DATA=''
A_INIT_DATA=''
A_INTERFACES_DATA=''
A_MACHINE_DATA=''
A_MEMORY_DATA=''
A_NETWORK_DATA=''
A_OPTICAL_DRIVE_DATA=''
A_PARTITION_DATA=''
A_PCICONF_DATA=''
A_PS_DATA=''
A_RAID_DATA=''
A_SENSORS_DATA=''
A_UNMOUNTED_PARTITION_DATA=''
A_WEATHER_DATA=''
A_DISPLAY_SERVER_DATA=''

### BOOLEANS ###
## standard boolean flags ##
B_BSD_DISK_SET='false'
B_BSD_RAID='false'
B_COLOR_SCHEME_SET='false'
B_CONSOLE_IRC='false'
# triggers full display of cpu flags
B_CPU_FLAGS_FULL='false'
# test for dbus irc client
B_DBUS_CLIENT='false'
# kde dcop
B_DCOP='false'
# Debug flood override: make 'true' to allow long debug output
B_DEBUG_FLOOD='false'
# for special -i debugging cases
B_DEBUG_I='false'
B_DMIDECODE_SET='false'
# show extra output data
B_EXTRA_DATA='false'
# triggered by -xx
B_EXTRA_EXTRA_DATA='false'
B_FORCE_DMIDECODE='false'
B_ID_SET='false'
# override certain errors due to currupted data
B_HANDLE_CORRUPT_DATA='false'
B_LABEL_SET='false'
B_LSPCI='false'
B_LOG_COLORS='false'
B_LOG_FULL_DATA='false'
B_MAPPER_SET='false'
B_OUTPUT_FILTER='false'
B_OVERRIDE_FILTER='false'
B_PCICONF='false'
B_PCICONF_SET='false'
# kde qdbus
B_QDBUS='false'
B_POSSIBLE_PORTABLE='false'
B_RAID_SET='false'
B_ROOT='false'
B_RUN_COLOR_SELECTOR='false'
B_RUNNING_IN_DISPLAY='false' # in x type display server
if tty >/dev/null;then
	B_IRC='false'
else
	B_IRC='true'
fi
# this sets the debug buffer
B_SCRIPT_UP='false'
B_SHOW_ADVANCED_NETWORK='false'
# Show sound card data
B_SHOW_AUDIO='false'
B_SHOW_BASIC_RAID='false'
B_SHOW_BASIC_CPU='false'
B_SHOW_BASIC_DISK='false'
B_SHOW_BASIC_OPTICAL='false'
B_SHOW_BATTERY='false'
B_SHOW_BATTERY_FORCED='false'
B_SHOW_CPU='false'
B_SHOW_DISPLAY_DATA='false'
B_SHOW_DISK_TOTAL='false'
B_SHOW_DISK='false'
# Show full hard disk output
B_SHOW_FULL_HDD='false'
B_SHOW_FULL_OPTICAL='false'
B_SHOW_GRAPHICS='false'
# Set this to 'false' to avoid printing the hostname, can be set false now
B_SHOW_HOST='true'
B_SHOW_INFO='false'
B_SHOW_IP='false'
B_SHOW_LABELS='false'
B_SHOW_MACHINE='false'
B_SHOW_MEMORY='false'
B_SHOW_NETWORK='false'
# either -v > 3 or -P will show partitions
B_SHOW_PARTITIONS='false'
B_SHOW_PARTITIONS_FULL='false'
B_SHOW_PS_CPU_DATA='false'
B_SHOW_PS_MEM_DATA='false'
B_SHOW_RAID='false'
# because many systems have no mdstat file, -b/-F should not show error if no raid file found
B_SHOW_RAID_R='false' 
B_SHOW_REPOS='false'
B_SHOW_SENSORS='false'
# triggers only short inxi output
B_SHOW_SHORT_OUTPUT='false'
B_SHOW_SYSTEM='false'
B_SHOW_UNMOUNTED_PARTITIONS='false'
B_SHOW_UUIDS='false'
B_SHOW_WEATHER='false'
B_SYSCTL='false'
# triggers various debugging and new option testing
B_TESTING_1='false'
B_TESTING_2='false'
B_UPLOAD_DEBUG_DATA='false'
B_USB_NETWORKING='false'
# set to true here for debug logging from script start
B_USE_LOGGING='false'
B_UUID_SET='false'
B_XORG_LOG='false'

## Directory/file exist flags; test as [[ $(boolean) ]] not [[ $boolean ]]
B_ASOUND_DEVICE_FILE='false'
B_ASOUND_VERSION_FILE='false'
B_BASH_ARRAY='false'
B_CPUINFO_FILE='false'
B_DMESG_BOOT_FILE='false' # bsd only
B_LSB_FILE='false'
B_MDSTAT_FILE='false'
B_MEMINFO_FILE='false'
B_MODULES_FILE='false' #
B_MOUNTS_FILE='false'
B_OS_RELEASE_FILE='false' # new default distro id file? will this one work where lsb-release didn't?
B_PARTITIONS_FILE='false' #
B_PROC_DIR='false'
B_SCSI_FILE='false'

## app tested for and present, to avoid repeat tests
B_FILE_TESTED='false'
B_HDDTEMP_TESTED='false'
B_MODINFO_TESTED='false'
B_SUDO_TESTED='false'

# cpu 64 bit able or not. Does not tell you actual kernel/OS installed
# if ((1<<32)); then
#   BITS=64
# else
#   BITS=32
# fi
# echo $BITS

### CONSTANTS/INITIALIZE - SOME MAY BE RESET LATER ###
BASH=${BASH_VERSION%%[^0-9]*} # some bash 4 things can be used but only if tested
DCOPOBJ="default"
DEBUG=0 # Set debug levels from 1-10 (8-10 trigger logging levels)
# Debug Buffer Index, index into a debug buffer storing debug messages until inxi is 'all up'
DEBUG_BUFFER_INDEX=0
DISPLAY_OPT='' # for console switches
## note: the debugger rerouting to /dev/null has been moved to the end of the get_parameters function
## so -@[number] debug levels can be set if there is a failure, otherwise you can't even see the errors
SED_I='-i' # for gnu sed, will be set to -i '' for bsd sed
SED_RX='-r' # for gnu sed, will be set to -E for bsd sed for backward compatibility

# default to false, no konversation found, 1 is native konvi (qt3/KDE3) script mode, 2 is /cmd inxi start,
##	3 is Konversation > 1.2 (qt4/KDE4) 
KONVI=0
NO_SSL=''
NO_SSL_OPT=''
# NO_CPU_COUNT=0	# Whether or not the string "dual" or similar is found in cpuinfo output. If so, avoid dups.
# This is a variable that controls how many parameters inxi will parse in a /proc/<pid>/cmdline file before stopping.
PARAMETER_LIMIT=30
SCHEME=0 # set default scheme - do not change this, it's set dynamically
# this is set in user prefs file, to override dynamic temp1/temp2 determination of sensors output in case
# cpu runs colder than mobo
SENSORS_CPU_NO=''
# SHOW_IRC=1 to avoid showing the irc client version number, or SHOW_IRC=0 to disable client information completely.
SHOW_IRC=2
# Verbosity level defaults to 0, this can also be set with -v0, -v2, -v3, etc as a parameter.
VERBOSITY_LEVEL=0
# Supported number of verbosity levels, including 0
VERBOSITY_LEVELS=7

### LOGGING ###
## logging eval variables, start and end function: Insert to LOGFS LOGFE when debug level >= 8
LOGFS_STRING='log_function_data fs $FUNCNAME "$( echo $@ )"'
LOGFE_STRING='log_function_data fe $FUNCNAME'
LOGFS=''
LOGFE=''
# uncomment for debugging from script start
# LOGFS=$LOGFS_STRING
# LOGFE=$LOGFE_STRING

### FILE NAMES/PATHS/URLS - must be non root writable ###
# File's used when present
FILE_ASOUND_DEVICE='/proc/asound/cards'
FILE_ASOUND_MODULES='/proc/asound/modules' # not used but maybe for -A?
FILE_ASOUND_VERSION='/proc/asound/version'
FILE_CPUINFO='/proc/cpuinfo'
FILE_DMESG_BOOT='/var/run/dmesg.boot'
FILE_LSB_RELEASE='/etc/lsb-release'
FILE_MDSTAT='/proc/mdstat'
FILE_MEMINFO='/proc/meminfo'
FILE_MODULES='/proc/modules'
FILE_MOUNTS='/proc/mounts'
FILE_OS_RELEASE='/etc/os-release'
FILE_PARTITIONS='/proc/partitions'
FILE_SCSI='/proc/scsi/scsi'
FILE_XORG_LOG='/var/log/Xorg.0.log' # if not found, search and replace with actual location

FILE_PATH=''
HDDTEMP_PATH=''
MODINFO_PATH=''
SUDO_PATH=''

ALTERNATE_FTP='' # for data uploads
ALTERNATE_WEATHER_LOCATION='' # weather alternate location
SELF_CONFIG_DIR=''
SELF_DATA_DIR=''
LOG_FILE='inxi.log'
LOG_FILE_1='inxi.1.log'
LOG_FILE_2='inxi.2.log'
MAN_FILE_DOWNLOAD='https://github.com/smxi/inxi/raw/master/inxi.1.gz'
SELF_PATH='' # filled-in in Main
SELF_DOWNLOAD='https://github.com/smxi/inxi/raw/master/'
SELF_DOWNLOAD_BRANCH_1='https://github.com/smxi/inxi/raw/one/'
SELF_DOWNLOAD_BRANCH_2='https://github.com/smxi/inxi/raw/two/'
SELF_DOWNLOAD_BRANCH_3='https://github.com/smxi/inxi/raw/three/'
SELF_DOWNLOAD_BRANCH_4='https://github.com/smxi/inxi/raw/four/'
SELF_DOWNLOAD_BRANCH_BSD='https://github.com/smxi/inxi/raw/bsd/'
SELF_DOWNLOAD_BRANCH_GNUBSD='https://github.com/smxi/inxi/raw/gnubsd/'
SELF_DOWNLOAD_DEV='https://smxi.org/test/'
# note, you can use any ip url here as long as it's the only line on the output page.
# Also the ip address must be the last thing on that line. If you abuse this ip tool 
# you will be banned from further access. Most > 24x daily automated queries to it are abuse.
WAN_IP_URL='https://smxi.org/opt/ip.php'
KONVI_CFG="konversation/scripts/$SELF_NAME.conf" # relative path to $(kde-config --path data)

### INITIALIZE VARIABLES NULL ###
ARCH='' # cpu microarchitecture
BSD_TYPE=''
BSD_VERSION=
CMDL_MAX=''
CPU_COUNT_ALPHA=''
CURRENT_KERNEL=''
DEV_DISK_ID=''
DEV_DISK_LABEL=''
DEV_DISK_MAPPER=''
DEV_DISK_UUID=''
DMIDECODE_DATA=''
DMESG_BOOT_DATA=''
DNSTOOL=''
DOWNLOADER='wget'
IRC_CLIENT=''
IRC_CLIENT_VERSION=''
LINE_LENGTH=0
LSPCI_V_DATA=''
LSPCI_N_DATA=''
MEMORY=''
PS_THROTTLED=''
REPO_DATA=''
SYSCTL_A_DATA=''
UP_TIME=''

### LAYOUT ###
# These two determine separators in single line output, to force irc clients not to break off sections
SEP1='~'
SEP2=' '
# these will assign a separator to non irc states. Important! Using ':' can trigger stupid emoticon
# behaviors in output on IRC, so do not use those.
SEP3_IRC=''
SEP3_CONSOLE=':'
SEP3='' # do not set, will be set dynamically
LINE1='---------------------------------------------------------------------------'
LINE2='- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -'

# Default indentation level. NOTE: actual indent is 1 greater to allow for spacing
INDENT=10

### COLUMN WIDTHS ###
COLS_INNER='' ## for width minus INDENT
COLS_MAX=''

# these will be set dynamically in main()
TERM_COLUMNS=80
TERM_LINES=100

# Only for legacy user config files se we can test and convert the var name
LINE_MAX_CONSOLE=''
LINE_MAX_IRC=''

### COLORS ###
# Defaults to 2, make this 1 for normal, 0 for no colorcodes at all. Use following variables in config 
# files to change defaults for each type, or global
# Same as runtime parameter.
DEFAULT_COLOR_SCHEME=2
## color variables - set dynamically
COLOR_SCHEME=''
C1=''
C2=''
CN=''
## Always leave these blank, these are only going to be set in inxi.conf files, that makes testing
## for user changes easier after sourcing the files
ESC='\x1b'
GLOBAL_COLOR_SCHEME=''
IRC_COLOR_SCHEME=''
IRC_CONS_COLOR_SCHEME=''
IRC_X_TERM_COLOR_SCHEME=''
CONSOLE_COLOR_SCHEME=''
VIRT_TERM_COLOR_SCHEME=''

## Output colors
# A more elegant way to have a scheme that doesn't print color codes (neither ANSI nor mIRC) at all. See below.
unset EMPTY
#             DGREY   BLACK   RED     DRED    GREEN   DGREEN  YELLOW  DYELLOW
ANSI_COLORS="[1;30m [0;30m [1;31m [0;31m [1;32m [0;32m [1;33m [0;33m"
IRC_COLORS="  \x0314  \x0301  \x0304  \x0305  \x0309  \x0303  \x0308  \x0307"
#                          BLUE    DBLUE   MAGENTA DMAGENTA CYAN   DCYAN   WHITE   GREY    NORMAL
ANSI_COLORS="$ANSI_COLORS [1;34m [0;34m [1;35m [0;35m [1;36m [0;36m [1;37m [0;37m [0;37m"
IRC_COLORS=" $IRC_COLORS    \x0312 \x0302  \x0313  \x0306  \x0311  \x0310  \x0300  \x0315  \x03"

#ANSI_COLORS=($ANSI_COLORS); IRC_COLORS=($IRC_COLORS)
A_COLORS_AVAILABLE=( DGREY BLACK RED DRED GREEN DGREEN YELLOW DYELLOW BLUE DBLUE MAGENTA DMAGENTA CYAN DCYAN WHITE GREY NORMAL )

# See above for notes on EMPTY
## note: group 1: 0, 1 are null/normal
## Following: group 2: generic, light/dark or dark/light; group 3: dark on light; group 4 light on dark; 
# this is the count of the first two groups, starting at zero
SAFE_COLOR_COUNT=12
A_COLOR_SCHEMES=( 
EMPTY,EMPTY,EMPTY 
NORMAL,NORMAL,NORMAL 

BLUE,NORMAL,NORMAL
BLUE,RED,NORMAL 
CYAN,BLUE,NORMAL 
DCYAN,NORMAL,NORMAL
DCYAN,BLUE,NORMAL 
DGREEN,NORMAL,NORMAL 
DYELLOW,NORMAL,NORMAL 
GREEN,DGREEN,NORMAL 
GREEN,NORMAL,NORMAL 
MAGENTA,NORMAL,NORMAL
RED,NORMAL,NORMAL

BLACK,DGREY,NORMAL
DBLUE,DGREY,NORMAL 
DBLUE,DMAGENTA,NORMAL
DBLUE,DRED,NORMAL 
DBLUE,BLACK,NORMAL
DGREEN,DYELLOW,NORMAL 
DYELLOW,BLACK,NORMAL
DMAGENTA,BLACK,NORMAL
DCYAN,DBLUE,NORMAL

WHITE,GREY,NORMAL
GREY,WHITE,NORMAL
CYAN,GREY,NORMAL 
GREEN,WHITE,NORMAL 
GREEN,YELLOW,NORMAL 
YELLOW,WHITE,NORMAL 
MAGENTA,CYAN,NORMAL 
MAGENTA,YELLOW,NORMAL
RED,CYAN,NORMAL
RED,WHITE,NORMAL 
BLUE,WHITE,NORMAL

RED,BLUE,NORMAL 
RED,DBLUE,NORMAL
BLACK,BLUE,NORMAL
BLACK,DBLUE,NORMAL
NORMAL,BLUE,NORMAL
BLUE,MAGENTA,NORMAL
DBLUE,MAGENTA,NORMAL
BLACK,MAGENTA,NORMAL
MAGENTA,BLUE,NORMAL
MAGENTA,DBLUE,NORMAL
)

#echo ${#A_COLOR_SCHEMES[@]};exit

# WARNING: In the main part below (search for 'KONVI')
# there's a check for Konversation-specific config files.
# Any one of these can override the above if inxi is run
# from Konversation!

## DISTRO DATA/ID ##
# In cases of derived distros where the version file of the base distro can also be found under /etc,
# the derived distro's version file should go first. (Such as with Sabayon / Gentoo)
DISTROS_DERIVED="antix-version aptosid-version kanotix-version knoppix-version mandrake-release mx-version pardus-release porteus-version sabayon-release siduction-version sidux-version slitaz-release solusos-release turbolinux-release zenwalk-version"
# debian_version excluded from DISTROS_PRIMARY so Debian can fall through to /etc/issue detection. Same goes for Ubuntu.
DISTROS_EXCLUDE_LIST="debian_version devuan_version ubuntu_version"
DISTROS_PRIMARY="arch-release gentoo-release redhat-release slackware-version SuSE-release"
DISTROS_LSB_GOOD="mandrake-release mandriva-release mandrakelinux-release"
# this is being used both by core distros and derived distros now, eg, solusos 1 uses it for solusos id, while
# debian, solusos base, uses it as well, so we have to know which it is.
DISTROS_OS_RELEASE_GOOD="arch-release SuSE-release "
## Distros with known problems
# DSL (Bash 2.05b: grep -m doesn't work; arrays won't work) --> unusable output
# Puppy Linux 4.1.2 (Bash 3.0: arrays won't work) --> works partially

## OUTPUT FILTERS/SEARCH ##
# Note that \<ltd\> bans only words, not parts of strings; in \<corp\> you can't use punctuation characters like . or ,
# we're saving about 10+% of the total script exec time by hand building the ban lists here, using hard quotes.

BAN_LIST_NORMAL='chipset|components|computing|computer|corporation|communications|electronics|electrical|electric|gmbh|group|incorporation|industrial|international|nee|revision|semiconductor|software|technologies|technology|ltd\.|\<ltd\>|inc\.|\<inc\>|intl\.|co\.|\<co\>|corp\.|\<corp\>|\(tm\)|\(r\)|®|\(rev ..\)'
BAN_LIST_CPU='@||cpu |cpu deca|dual core|dual-core|tri core|tri-core|quad core|quad-core|ennea|genuine|hepta|hexa|multi|octa|penta|processor|single|triple|[0-9\.]+ *[MmGg][Hh][Zz]'
# See github issue 75 for more details on value: *, triggers weird behaviors if present in value
# /sys/devices/virtual/dmi/id/product_name:['*']
# this is for bash arrays AND avoiding * in arrays: ( fred * greg ) expands to the contents of the directory
BAN_LIST_ARRAY=',|\*'

SENSORS_GPU_SEARCH='amdgpu|intel|radeon|nouveau'

### USB networking search string data, because some brands can have other products than
### wifi/nic cards, they need further identifiers, with wildcards.
### putting the most common and likely first, then the less common, then some specifics
USB_NETWORK_SEARCH="Wi-Fi.*Adapter|Wireless.*Adapter|Ethernet.*Adapter|WLAN.*Adapter|Network.*Adapter|802\.11|Atheros|Atmel|D-Link.*Adapter|D-Link.*Wireless|Linksys|Netgea|Ralink|Realtek.*Network|Realtek.*Wireless|Realtek.*WLAN|Belkin.*Wireless|Belkin.*WLAN|Belkin.*Network"
USB_NETWORK_SEARCH="$USB_NETWORK_SEARCH|Actiontec.*Wireless|Actiontec.*Network|AirLink.*Wireless|Asus.*Network|Asus.*Wireless|Buffalo.*Wireless|Davicom|DWA-.*RangeBooster|DWA-.*Wireless|ENUWI-.*Wireless|LG.*Wi-Fi|Rosewill.*Wireless|RNX-.*Wireless|Samsung.*LinkStick|Samsung.*Wireless|Sony.*Wireless|TEW-.*Wireless|TP-Link.*Wireless|WG[0-9][0-9][0-9].*Wireless|WNA[0-9][0-9][0-9]|WNDA[0-9][0-9][0-9]|Zonet.*ZEW.*Wireless|54 Mbps" 
# then a few known hard to ID ones added 
# belkin=050d; d-link=07d1; netgear=0846; ralink=148f; realtek=0bda; 
USB_NETWORK_SEARCH="$USB_NETWORK_SEARCH|050d:935b|0bda:8189|0bda:8197"

########################################################################
#### MAIN: Where it all begins
########################################################################
main()
{
	# This must be set first so log paths are present when logging starts.
	set_user_paths
	
	eval $LOGFS
	
	local color_scheme='' kde_config_app=''
	# this will be used by all functions following, lower case for bash parameter expansion
	local Ps_aux_Data="$( ps aux | tr '[:upper:]' '[:lower:]' )"

	# This function just initializes variables
	initialize_data
	
	# Source global config overrides, needs to be here because some things
	# can be reset that were set in initialize, but check_required_apps needs
	if [[ -s /etc/$SELF_NAME.conf ]];then
		source /etc/$SELF_NAME.conf
	fi
	# Source user config variables override /etc/inxi.conf variables
	if [[ -s $SELF_CONFIG_DIR/$SELF_NAME.conf ]];then
		source $SELF_CONFIG_DIR/$SELF_NAME.conf
	fi
	
	set_display_width 'live' # can be reset with -y
	
	# echo SCHEME $SCHEME
	# echo B_IRC $B_IRC
	# echo sep3: $SEP3
	# Check for dependencies BEFORE running ANYTHING else except above functions
	# Not all distro's have these depends installed by default. Don't want to run
	# this if the user is requesting to see this information in the first place
	# Only continue if required apps tests ok
	if [[ $1 != '--recommends' ]];then
		check_required_apps
		check_recommended_apps
	fi
	# previous source location, check for bugs

	## this needs to run before the KONVI stuff is set below
	## Konversation 1.2 apparently does not like the $PPID test in get_start_client
	## So far there is no known way to detect if qt4_konvi is the parent process
	## this method will infer qt4_konvi as parent
	get_start_client

	# note: this only works if it's run from inside konversation as a script builtin or something
	# only do this if inxi has been started as a konversation script, otherwise bypass this	
	#	KONVI=3 ## for testing puroses
	if [[ $KONVI -eq 1 || $KONVI -eq 3 ]];then
		if [[ $KONVI -eq 1 ]]; then ## dcop Konversation (ie 1.x < 1.2(qt3))	
			DCPORT="$1"
			DCSERVER="$2"
			DCTARGET="$3"
			shift 3
		elif [[ $KONVI -eq 3 ]]; then ## dbus Konversation (> 1.2 (qt4))
			DCSERVER="$1" ##dbus testing
			DCTARGET="$2" ##dbus testing
			shift 2
		fi
		# always have the current stable kde version tested first, 
		# then use fallbacks and future proofing
		if type -p kde4-config &>/dev/null;then
			kde_config_app='kde4-config'
		elif type -p kde5-config &>/dev/null;then
			kde_config_app='kde5-config'
		elif type -p kde-config &>/dev/null;then
			kde_config_app='kde-config'
		fi
		# The section below is on request of Argonel from the Konversation developer team:
		# it sources config files like $HOME/.kde/share/apps/konversation/scripts/inxi.conf
		if [[ -n $kde_config_app ]];then
			IFS=":"
			for kde_config in $( $kde_config_app --path data )
			do
				if [[ -r $kde_config$KONVI_CFG ]];then
					source "$kde_config$KONVI_CFG"
					break
				fi
			done
			IFS="$ORIGINAL_IFS"
		fi
	fi

	## leave this for debugging dcop stuff if we get that working
	# 	print_screen_output "DCPORT: $DCPORT"
	# 	print_screen_output "DCSERVER: $DCSERVER"
	# 	print_screen_output "DCTARGET: $DCTARGET"
	
	# first init function must be set first for colors etc. Remember, no debugger
	# stuff works on this function unless you set the debugging flag manually.
	# Debugging flag -@ [number] will not work until get_parameters runs.
	
	# "$@" passes every parameter separately quoted, "$*" passes all parameters as one quoted parameter.
	# must be here to allow debugger and other flags to be set.
	get_parameters "$@"

	# If no colorscheme was set in the parameter handling routine, then set the default scheme
	if [[ $B_COLOR_SCHEME_SET != 'true' ]];then
		# This let's user pick their color scheme. For IRC, only shows the color schemes, no interactive
		# The override value only will be placed in user config files. /etc/inxi.conf can also override
		if [[ $B_RUN_COLOR_SELECTOR == 'true' ]];then 
			select_default_color_scheme
		else
			# set the default, then override as required
			color_scheme=$DEFAULT_COLOR_SCHEME
			if [[ -n $GLOBAL_COLOR_SCHEME ]];then
				color_scheme=$GLOBAL_COLOR_SCHEME
			else
				if [[ $B_IRC == 'false' ]];then
					if [[ -n $CONSOLE_COLOR_SCHEME && -z $DISPLAY ]];then
						color_scheme=$CONSOLE_COLOR_SCHEME
					elif [[ -n $VIRT_TERM_COLOR_SCHEME ]];then
						color_scheme=$VIRT_TERM_COLOR_SCHEME
					fi
				else
					if [[ -n $IRC_X_TERM_COLOR_SCHEME && $B_CONSOLE_IRC == 'true' && -n $B_RUNNING_IN_DISPLAY ]];then
						color_scheme=$IRC_X_TERM_COLOR_SCHEME
					elif [[ -n $IRC_CONS_COLOR_SCHEME && -z $DISPLAY ]];then
						color_scheme=$IRC_CONS_COLOR_SCHEME
					elif [[ -n $IRC_COLOR_SCHEME ]];then
						color_scheme=$IRC_COLOR_SCHEME
					fi
				fi
			fi
			set_color_scheme $color_scheme
		fi
	fi
	if [[ $B_IRC == 'false' ]];then
		SEP3=$SEP3_CONSOLE
	else
		# too hard to read if no colors, so force that for users on irc
		if [[ $SCHEME == 0 ]];then
			SEP3=$SEP3_CONSOLE
		else
			SEP3=$SEP3_IRC
		fi
	fi
	
	# all the pre-start stuff is in place now
	B_SCRIPT_UP='true'
	script_debugger "Debugger: $SELF_NAME is up and running..."
	
	# then create the output
	print_it_out

	eval $LOGFE
	# weechat's executor plugin forced me to do this, and rightfully so, because else the exit code
	# from the last command is taken..
	exit 0
}

set_user_paths()
{
	local b_conf='false' b_data='false'
	
	if [[ -n $XDG_CONFIG_HOME ]];then
		SELF_CONFIG_DIR=$XDG_CONFIG_HOME
		b_conf=true
	elif [[ -d $HOME/.config ]];then
		SELF_CONFIG_DIR=$HOME/.config
		b_conf=true
	else 
		SELF_CONFIG_DIR="$HOME/.$SELF_NAME"
	fi
	if [[ -n $XDG_DATA_HOME ]];then
		SELF_DATA_DIR=$XDG_DATA_HOME/$SELF_NAME
		b_data=true
	elif [[ -d $HOME/.local/share ]];then
		SELF_DATA_DIR=$HOME/.local/share/$SELF_NAME
		b_data=true
	else 
		SELF_DATA_DIR="$HOME/.$SELF_NAME"
	fi
	# note, this used to be created/checked in specific instance, but we'll just do it
	# universally so it's done at script start.
	if [[ ! -d $SELF_DATA_DIR ]];then
		mkdir $SELF_DATA_DIR
	fi
	
	if [[ $b_conf == 'true' && -f $HOME/.$SELF_NAME/$SELF_NAME.conf ]];then
		mv -f $HOME/.$SELF_NAME/$SELF_NAME.conf $SELF_CONFIG_DIR
		echo "Moved $SELF_NAME.conf from $HOME/.$SELF_NAME to $SELF_CONFIG_DIR"
	fi
	if [[ $b_data == 'true' && -d $HOME/.$SELF_NAME ]];then
		mv -f $HOME/.$SELF_NAME/* $SELF_DATA_DIR
		rm -Rf $HOME/.$SELF_NAME
		echo "Moved data dir $HOME/.$SELF_NAME to $SELF_DATA_DIR"
	fi
	
	LOG_FILE=$SELF_DATA_DIR/$LOG_FILE
	LOG_FILE_1=$SELF_DATA_DIR/$LOG_FILE_1
	LOG_FILE_2=$SELF_DATA_DIR/$LOG_FILE_2
}

#### -------------------------------------------------------------------
#### basic tests: set script data, booleans, PATH, version numbers
#### -------------------------------------------------------------------

# Set PATH data so we can access all programs as user. Set BAN lists.
# initialize some boleans, these directories are used throughout the script
# some apps are used for extended functions any directory used, should be
# checked here first.
# No args taken.
initialize_data()
{
	eval $LOGFS
	BSD_VERSION=$( uname -s 2>/dev/null | tr '[A-Z]' '[a-z]' )
	# note: archbsd says they are a freebsd distro, so assuming it's the same as freebsd
	if [[ -z ${BSD_VERSION/*bsd*/} || -z ${BSD_VERSION/*dragonfly*/} || -z ${BSD_VERSION/*darwin*/} ]];then
		if [[ -z ${BSD_VERSION/*openbsd*/} ]];then
			BSD_VERSION='openbsd'
		elif [[ -z ${BSD_VERSION/*darwin*/} ]];then
			BSD_VERSION='darwin'
		fi
		# GNU/kfreebsd will by definition have GNU tools like sed/grep
		if [[ -z ${BSD_VERSION/*kfreebsd*/} ]];then
			BSD_TYPE='debian-bsd' # debian gnu bsd
		else
			BSD_TYPE='bsd' # all other bsds
			SED_I="-i ''"
			SED_RX='-E'
			ESC=$(echo | tr '\n' '\033')
		fi
	fi
	# now set the script BOOLEANS for files required to run features
	# note that freebsd has /proc but it's empty
	if [[ -d "/proc/" && -z $BSD_TYPE ]];then
		B_PROC_DIR='true'
	elif [[ -n $BSD_TYPE ]];then
		B_PROC_DIR='false'
	else
		error_handler 6
	fi
	
	initialize_paths
	
	if type -p dig &>/dev/null;then
		DNSTOOL='dig'
	fi
	# set downloaders. 
	if ! type -p wget &>/dev/null;then
		# first check for bsd stuff
		if type -p fetch &>/dev/null;then
			DOWNLOADER='fetch'
			NO_SSL=' --no-verify-peer'
		elif type -p curl &>/dev/null;then
			DOWNLOADER='curl'
			NO_SSL=' --insecure'
		elif [[ $BSD_VERSION == 'openbsd' ]] && type -p ftp &>/dev/null;then
			DOWNLOADER='ftp'
		else
			DOWNLOADER='no-downloader'
		fi
	else
		NO_SSL=' --no-check-certificate'
	fi
	
	if [[ -n $BSD_TYPE ]];then
		if [[ -e $FILE_DMESG_BOOT ]];then
			B_DMESG_BOOT_FILE='true'
		fi
	else
		# found a case of battery existing but having nothing in it on desktop mobo
		# not all laptops show the first. /proc/acpi/battery is deprecated.
		if [[ -n $( ls /proc/acpi/battery 2>/dev/null ) || -n $( ls /sys/class/power_supply/ 2>/dev/null )  ]];then
			B_POSSIBLE_PORTABLE='true'
		fi
	fi
	if [[ -e $FILE_CPUINFO ]]; then
		B_CPUINFO_FILE='true'
	fi
	if [[ -e $FILE_MEMINFO ]];then
		B_MEMINFO_FILE='true'
	fi
	if [[ -e $FILE_ASOUND_DEVICE ]];then
		B_ASOUND_DEVICE_FILE='true'
	fi
	if [[ -e $FILE_ASOUND_VERSION ]];then
		B_ASOUND_VERSION_FILE='true'
	fi
	if [[ -f $FILE_LSB_RELEASE ]];then
		B_LSB_FILE='true'
	fi
	if [[ -f $FILE_OS_RELEASE ]];then
		B_OS_RELEASE_FILE='true'
	fi
	if [[ -e $FILE_SCSI ]];then
		B_SCSI_FILE='true'
	fi
	if [[ -n $DISPLAY ]];then
		B_SHOW_DISPLAY_DATA='true'
		B_RUNNING_IN_DISPLAY='true'
	fi
	if [[ -e $FILE_MDSTAT ]];then
		B_MDSTAT_FILE='true'
	fi
	if [[ -e $FILE_MODULES ]];then
		B_MODULES_FILE='true'
	fi
	if [[ -e $FILE_MOUNTS ]];then
		B_MOUNTS_FILE='true'
	fi
	if [[ -e $FILE_PARTITIONS ]];then
		B_PARTITIONS_FILE='true'
	fi
	# default to the normal location, then search for it
	if [[ -e $FILE_XORG_LOG ]];then
		B_XORG_LOG='true'
	else
		# Detect location of the Xorg log file
		if type -p xset &>/dev/null; then
			FILE_XORG_LOG=$( xset q 2>/dev/null | grep -i 'Log file' | gawk '{print $3}')
			if [[ -e $FILE_XORG_LOG ]];then
				B_XORG_LOG='true'
			fi
		fi
	fi
	# gfx output will require this flag
	if [[ $( whoami ) == 'root' ]];then
		B_ROOT='true'
	fi
	eval $LOGFE
}

# args: $1 - default OR override default cols max integer count
set_display_width()
{
	local cols_max_override=$1
	
	if [[ $cols_max_override == 'live' ]];then
		## sometimes tput will trigger an error (mageia) if irc client
		if [[ $B_IRC == 'false' ]];then
			if type -p tput &>/dev/null;then
				TERM_COLUMNS=$(tput cols)
				TERM_LINES=$(tput lines)
			fi
			# double check, just in case it's missing functionality or whatever
			if [[ -z $TERM_COLUMNS || -n ${TERM_COLUMNS//[0-9]/} ]];then
				TERM_COLUMNS=80
				TERM_LINES=100
			fi
		fi
		# Convert to new variable names if set in config files, legacy test
		if [[ -n $LINE_MAX_CONSOLE ]];then
			COLS_MAX_CONSOLE=$LINE_MAX_CONSOLE
		fi
		if [[ -n $LINE_MAX_IRC ]];then
			COLS_MAX_IRC=$LINE_MAX_IRC
		fi
		# this lets you set different widths for in or out of display server
	# 	if [[ $B_RUNNING_IN_DISPLAY == 'false' && -n $COLS_MAX_NO_DISPLAY ]];then
	# 		COLS_MAX_CONSOLE=$COLS_MAX_NO_DISPLAY
	# 	fi
		# TERM_COLUMNS is set in top globals, using tput cols
		# echo tc: $TERM_COLUMNS cmc: $COLS_MAX_CONSOLE
		if [[ $TERM_COLUMNS -lt $COLS_MAX_CONSOLE ]];then
			COLS_MAX_CONSOLE=$TERM_COLUMNS
		fi
		# adjust, some terminals will wrap if output cols == term cols
		COLS_MAX_CONSOLE=$(( $COLS_MAX_CONSOLE - 2 ))
		# echo cmc: $COLS_MAX_CONSOLE
		# comes after source for user set stuff
		if [[ $B_IRC == 'false' ]];then
			COLS_MAX=$COLS_MAX_CONSOLE
		else
			COLS_MAX=$COLS_MAX_IRC
		fi
	else
		COLS_MAX=$cols_max_override
	fi
	COLS_INNER=$(( $COLS_MAX - $INDENT - 1 ))
	# echo cm: $COLS_MAX ci: $COLS_INNER
}

# arg: $1 - version number: main/patch/date
parse_version_data()
{
	# note, this is only now used for self updater function
	case $1 in
		date)
			SELF_DATE=$( gawk -F '=' '
			/^SELF_DATE/ {
				print $NF
				exit
			}' "$SELF_PATH/$SELF_NAME" )
			;;
		main)
			SELF_VERSION=$( gawk -F '=' '
			/^SELF_VERSION/ {
				print $NF
				exit
			}' "$SELF_PATH/$SELF_NAME" )
			;;
		patch)
			SELF_PATCH=$( gawk -F '=' '
			/^SELF_PATCH/ {
				print $NF
				exit
			}' "$SELF_PATH/$SELF_NAME" )
			;;
	esac
}

initialize_paths()
{
	local path='' added_path='' b_path_found='' sys_path=''
	# Extra path variable to make execute failures less likely, merged below
	local extra_paths="/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin:/opt/local/bin"
	
	# this needs to be set here because various options call the parent initialize function directly.
	SELF_PATH=$( dirname "$0" )
	# Fallback paths put into $extra_paths; This might, among others, help on gentoo.
	# Now, create a difference of $PATH and $extra_paths and add that to $PATH:
	IFS=":"
	for path in $extra_paths
	do
		b_path_found='false'
		for sys_path in $PATH
		do
			if [[ $path == $sys_path ]];then
				b_path_found='true'
			fi
		done
		if [[ $b_path_found == 'false' ]];then
			added_path="$added_path:$path"
		fi
	done

	IFS="$ORIGINAL_IFS"
	PATH="$PATH$added_path"
	# echo "PATH='$PATH'"
	##/bin/sh -c 'echo "PATH in subshell=\"$PATH\""'
}

# No args taken.
check_recommended_apps()
{
	eval $LOGFS
	local bash_array_test=( "one" "two" )

	# check for array ability of bash, this is only good for the warning at this time
	# the boolean could be used later
	# bash version 2.05b is used in DSL
	# bash version 3.0 is used in Puppy Linux; it has a known array bug <reference to be placed here>
	# versions older than 3.1 don't handle arrays
	# distro's using below 2.05b are unknown, released in 2002
	if [[ ${bash_array_test[1]} -eq "two" ]];then
		B_BASH_ARRAY='true'
	else
		script_debugger "Suggestion: update to Bash v3.1 for optimal inxi output"
	fi
	# test for a few apps that bsds may not have after initial tests
	if type -p lspci &>/dev/null;then
		B_LSPCI='true'
	fi
	if [[ -n $BSD_TYPE ]];then
		if type -p sysctl &>/dev/null;then
			B_SYSCTL='true'
		fi
		if type -p pciconf &>/dev/null;then
			B_PCICONF='true'
		fi
	fi
	# now setting qdbus/dcop for first run, some systems can have both by the way
	if type -p qdbus &>/dev/null;then
		B_QDBUS='true'
	fi
	if type -p dcop &>/dev/null;then
		B_DCOP='true'
	fi
	eval $LOGFE
}

# Determine if any of the absolutely necessary tools are absent
# No args taken.
check_required_apps()
{
	eval $LOGFS
	local app_name=''
	# bc removed from deps for now
	local depends="df gawk grep ps readlink tr uname wc"
	
	if [[ -z $BSD_TYPE  ]];then
		depends="$depends lspci"
	elif [[ $BSD_TYPE == 'bsd' ]];then
		depends="$depends sysctl"
		# debian-bsd has lspci but you must be root to run it
	elif [[ $BSD_TYPE == 'debian-bsd' ]];then
		depends="$depends sysctl lspci"
	fi
	# no need to add xprop because it will just give N/A if not there, but if we expand use of xprop,
	# should add that here as a test, then use the B_SHOW_DISPLAY_DATA flag to trigger the tests in de function
	local x_apps="xrandr xdpyinfo glxinfo" 

	if [[ $B_RUNNING_IN_DISPLAY == 'true' ]];then
		for app_name in $x_apps
		do
			if ! type -p $app_name &>/dev/null;then
				script_debugger "Resuming in non X mode: $app_name not found. For package install advice run: $SELF_NAME --recommends"
				B_SHOW_DISPLAY_DATA='false'
				break
			fi
		done
	fi

	app_name=''

	for app_name in $depends
	do
		if ! type -p $app_name &>/dev/null;then
			error_handler 5 "$app_name"
		fi
	done
	eval $LOGFE
}

## note: this is now running inside each gawk sequence directly to avoid exiting gawk
## looping in bash through arrays, then re-entering gawk to clean up, then writing back to array
## in bash. For now I'll leave this here because there's still some interesting stuff to get re methods
# Enforce boilerplate and buzzword filters
# args: $1 - BAN_LIST_NORMAL/BAN_LIST_CPU; $2 - string to sanitize
sanitize_characters()
{
	eval $LOGFS
	# Cannot use strong quotes to unquote a string with pipes in it!
	# bash will interpret the |'s as usual and try to run a subshell!
	# Using weak quotes instead, or use '"..."'
	echo "$2" | gawk "
	BEGIN {
		IGNORECASE=1
	}
	{
		gsub(/${!1}/,\"\")
		gsub(/ [ ]+/,\" \")    ## ([ ]+) with (space)
		gsub(/^ +| +$/,\"\")   ## (pipe char) with (nothing)
		print                  ## prints (returns) cleaned input
	}"
	eval $LOGFE
}

# Set the colorscheme
# args: $1 = <scheme number>|<"none">
set_color_scheme()
{
	eval $LOGFS
	local i='' a_output_colors='' a_color_codes=''

	if [[ $1 -ge ${#A_COLOR_SCHEMES[@]} ]];then
		set -- 1
	fi
	# Set a global variable to allow checking for chosen scheme later
	SCHEME="$1"
	if [[ $B_IRC == 'false' ]];then
		a_color_codes=( $ANSI_COLORS )
	else
		a_color_codes=( $IRC_COLORS )
	fi
	for (( i=0; i < ${#A_COLORS_AVAILABLE[@]}; i++ ))
	do
		eval "${A_COLORS_AVAILABLE[i]}=\"${a_color_codes[i]}\""
	done
	IFS=","
	a_output_colors=( ${A_COLOR_SCHEMES[$1]} )
	IFS="$ORIGINAL_IFS"
	# then assign the colors globally
	C1="${!a_output_colors[0]}"
	C2="${!a_output_colors[1]}"
	CN="${!a_output_colors[2]}"
	# ((COLOR_SCHEME++)) ## note: why is this? ##
	# handle some explicit colors that are used for no color 0
	if [[ $SCHEME -eq 0 ]];then
		NORMAL=''
		RED=''
	fi
	eval $LOGFE
}

select_default_color_scheme()
{
	eval $LOGFS
	local spacer='  ' options='' user_selection='' config_variable=''
	local config_file="$SELF_CONFIG_DIR/$SELF_NAME.conf"
	local irc_clear="[0m" 
	local irc_gui='Unset' irc_console='Unset' irc_x_term='Unset'
	local console='Unset' virt_term='Unset' global='Unset' 
	
	if [[ -n $IRC_COLOR_SCHEME ]];then
		irc_gui="Set: $IRC_COLOR_SCHEME"
	fi
	if [[ -n $IRC_CONS_COLOR_SCHEME ]];then
		irc_console="Set: $IRC_CONS_COLOR_SCHEME"
	fi
	if [[ -n $IRC_X_TERM_COLOR_SCHEME ]];then
		irc_x_term="Set: $IRC_X_TERM_COLOR_SCHEME"
	fi
	if [[ -n $VIRT_TERM_COLOR_SCHEME ]];then
		virt_term="Set: $VIRT_TERM_COLOR_SCHEME"
	fi
	if [[ -n $CONSOLE_COLOR_SCHEME ]];then
		console="Set: $CONSOLE_COLOR_SCHEME"
	fi
	if [[ -n $GLOBAL_COLOR_SCHEME ]];then
		global="Set: $GLOBAL_COLOR_SCHEME"
	fi
	
	# don't want these printing in irc since they show literally
	if [[ $B_IRC == 'true' ]];then
		irc_clear=''
	fi
	# first make output neutral so it's just plain default for console client
	set_color_scheme "0"
	# print_lines_basic "0" "" ""
	if [[ $B_IRC == 'false' ]];then
		print_lines_basic "0" "" "Welcome to $SELF_NAME! Please select the default $COLOR_SELECTION color scheme."
		# print_screen_output "You will see this message only one time per user account, unless you set preferences in: /etc/$SELF_NAME.conf"
		print_screen_output " "
	fi
	print_lines_basic "0" "" "Because there is no way to know your $COLOR_SELECTION foreground/background colors, you can set your color preferences from color scheme option list below. 0 is no colors, 1 neutral. After these, there are 4 sets: 1-dark or light backgrounds; 2-light backgrounds; 3-dark backgrounds; 4-miscellaneous."
	if [[ $B_IRC == 'false' ]];then
		print_lines_basic "0" "" "Please note that this will set the $COLOR_SELECTION preferences only for user: $(whoami)"
	fi
	print_screen_output "$LINE1"
	for (( i=0; i < ${#A_COLOR_SCHEMES[@]}; i++ ))
	do
		if [[ $i -gt 9 ]];then
			spacer=' '
		fi
		# only offer the safe universal defaults
		case $COLOR_SELECTION in
			global|irc|irc-console|irc-virtual-terminal)
				if [[ $i -gt $SAFE_COLOR_COUNT ]];then
					break
				fi
				;;
		esac
		set_color_scheme $i
		print_screen_output "$irc_clear $i)$spacer${C1}Card:${C2} nVidia G86 [GeForce 8400 GS] ${C1}Display Server${C2} x11 (X.Org 1.7.7)"
	done
	set_color_scheme 0
	
	if [[ $B_IRC == 'false' ]];then
		echo -n "[0m"
		
		print_screen_output "$irc_clear $i)${spacer}Remove all color settings. Restore $SELF_NAME default."
		print_screen_output "$irc_clear $(($i+1)))${spacer}Continue, no changes or config file setting."
		print_screen_output "$irc_clear $(($i+2)))${spacer}Exit, use another terminal, or set manually."
		print_screen_output "$LINE1"
		print_lines_basic "0" "" "Simply type the number for the color scheme that looks best to your eyes for your $COLOR_SELECTION settings and hit ENTER. NOTE: You can bring this option list up by starting $SELF_NAME with option: -c plus one of these numbers:"
		print_lines_basic "0" "" "94^(console,^no X^-^$console); 95^(terminal,^X^-^$virt_term); 96^(irc,^gui,^X^-^$irc_gui); 97^(irc,^X,^in^terminal^-^$irc_x_term); 98^(irc,^no^X^-^$irc_console); 99^(global^-^$global)"
		print_lines_basic "0" "" ""
		print_screen_output "Your selection(s) will be stored here: $config_file"
		print_lines_basic "0" "" "Global overrides all individual color schemes. Individual schemes remove the global setting."
		print_screen_output "$LINE1"
		read user_selection
		if [[ "$user_selection" =~ ^([0-9]+)$ && $user_selection -lt $i ]];then
			case $COLOR_SELECTION in
				irc)
					config_variable='IRC_COLOR_SCHEME'
					;;
				irc-console)
					config_variable='IRC_CONS_COLOR_SCHEME'
					;;
				irc-virtual-terminal)
					config_variable='IRC_X_TERM_COLOR_SCHEME'
					;;
				console)
					config_variable='CONSOLE_COLOR_SCHEME'
					;;
				virtual-terminal)
					config_variable='VIRT_TERM_COLOR_SCHEME'
					;;
				global)
					config_variable='GLOBAL_COLOR_SCHEME'
					;;
			esac
			set_color_scheme $user_selection
			# make file/directory first if missing
			if [[ ! -f $config_file ]];then
				touch $config_file
			fi
			if [[ -z $( grep -s "$config_variable=" $config_file ) ]];then
				print_lines_basic "0" "" "Creating and updating config file for $COLOR_SELECTION color scheme now..."
				echo "$config_variable=$user_selection" >> $config_file
			else
				print_screen_output "Updating config file for $COLOR_SELECTION color scheme now..."
				sed $SED_I "s/$config_variable=.*/$config_variable=$user_selection/" $config_file
			fi
			# file exists now so we can go on to cleanup
			case $COLOR_SELECTION in
				irc|irc-console|irc-virtual-terminal|console|virtual-terminal)
					sed $SED_I '/GLOBAL_COLOR_SCHEME=/d' $config_file
					;;
				global)
					sed $SED_I -e '/VIRT_TERM_COLOR_SCHEME=/d' -e '/CONSOLE_COLOR_SCHEME=/d' -e '/IRC_COLOR_SCHEME=/d' \
					-e '/IRC_CONS_COLOR_SCHEME=/d' -e '/IRC_X_TERM_COLOR_SCHEME=/d' $config_file
					;;
			esac
		elif [[ $user_selection == $i ]];then
			print_screen_output "Removing all color settings from config file now..."
			sed $SED_I -e '/VIRT_TERM_COLOR_SCHEME=/d' -e '/GLOBAL_COLOR_SCHEME=/d' -e '/CONSOLE_COLOR_SCHEME=/d' \
			-e '/IRC_COLOR_SCHEME=/d' -e '/IRC_CONS_COLOR_SCHEME=/d' -e '/IRC_X_TERM_COLOR_SCHEME=/d' $config_file
			set_color_scheme $DEFAULT_COLOR_SCHEME
		elif [[ $user_selection == $(( $i+1 )) ]];then
			print_lines_basic "0" "" "Ok, continuing $SELF_NAME unchanged. You can set the colors anytime by starting with: -c 95 to 99"
			if [[ -n $CONSOLE_COLOR_SCHEME && -z $DISPLAY ]];then
				set_color_scheme $CONSOLE_COLOR_SCHEME
			elif [[ -n $VIRT_TERM_COLOR_SCHEME ]];then
				set_color_scheme $VIRT_TERM_COLOR_SCHEME
			else
				set_color_scheme $DEFAULT_COLOR_SCHEME
			fi
		elif [[ $user_selection == $(( $i+2 )) ]];then
			set_color_scheme $DEFAULT_COLOR_SCHEME
			print_screen_output "Ok, exiting $SELF_NAME now. You can set the colors later."
			exit 0
		else
			print_screen_output "Error - Invalid Selection. You entered this: $user_selection"
			print_screen_output " "
			select_default_color_scheme
		fi
	else
		print_screen_output "$LINE1"
		print_lines_basic "0" "" "After finding the scheme number you like, simply run this again in a terminal to set the configuration data file for your irc client. You can set color schemes for the following: start inxi with -c plus:"
		print_screen_output "94 (console, no X - $console); 95 (terminal, X - $virt_term); 96 (irc, gui, X - $irc_gui);"
		print_screen_output "97 (irc, X, in terminal - $irc_x_term); 98 (irc, no X - $irc_console); 99 (global - $global)"
		exit 0
	fi

	eval $LOGFE
}

########################################################################
#### UTILITY FUNCTIONS
########################################################################

#### -------------------------------------------------------------------
#### error handler, debugger, script updater
#### -------------------------------------------------------------------

# Error handling
# args: $1 - error number; $2 - optional, extra information; $3 - optional extra info
error_handler()
{
	eval $LOGFS
	local error_message=''

	# assemble the error message
	case $1 in
		2)	error_message="large flood danger, debug buffer full!"
			;;
		3)	error_message="unsupported color scheme number: $2"
			;;
		4)	error_message="unsupported verbosity level: $2"
			;;
		5)	error_message="dependency not met: $2 not found in path.\nFor distribution installation package names and missing apps information, run: $SELF_NAME --recommends"
			;;
		6)	error_message="/proc not found! Quitting..."
			;;
		7)	error_message="One of the options you entered in your script parameters: $2\nis not supported.The option may require extra arguments to work.\nFor supported options (and their arguments), check the help menu: $SELF_NAME -h"
			;;
		8)	error_message="the self-updater failed, $DOWNLOADER exited with error: $2.\nYou probably need to be root.\nHint, to make for easy updates without being root, do: chown <user name> $SELF_PATH/$SELF_NAME"
			;;
		9)	error_message="unsupported debugging level: $2"
			;;
		10)
			error_message="the alt download url you provided: $2\nappears to be wrong, download aborted. Please note, the url\nneeds to end in /, without $SELF_NAME, like: http://yoursite.com/downloads/"
			;;
		11)
			error_message="unsupported testing option argument: -! $2"
			;;
		12)
			error_message="the git branch download url: $2\nappears to be empty currently. Make sure there is an actual source branch version\nactive before you try this again. Check https://github.com/smxi/inxi\nto verify the branch status."
			;;
		13)
			error_message="The -t option requires the following extra arguments (no spaces between letters/numbers):\nc m cm [required], for example: -t cm8 OR -t cm OR -t c9\n(numbers: 1-20, > 5 throttled to 5 in irc clients) You entered: $2"
			;;
		14)
			error_message="failed to write correctly downloaded $SELF_NAME to location $SELF_PATH.\nThis usually means you don't have permission to write to that location, maybe you need to be root?\nThe operation failed with error: $2"
			;;
		15)
			error_message="failed set execute permissions on $SELF_NAME at location $SELF_PATH.\nThis usually means you don't have permission to set permissions on files there, maybe you need to be root?\nThe operation failed with error: $2"
			;;
		16)
			error_message="$SELF_NAME downloaded but the file data is corrupted. Purged data and using current version."
			;;
		17)
			error_message="All $SELF_NAME self updater features have been disabled by the distribution\npackage maintainer. This includes the option you used: $2"
			;;
		18)
			error_message="The argument you provided for $2 does not have supported syntax.\nPlease use the following formatting:\n$3"
			;;
		19)
			error_message="The option $2 has been deprecated. Please use $3 instead.\nSee -h for instructions and syntax."
			;;
		20)
			error_message="The option you selected has been deprecated. $2\nSee the -h (help) menu for currently supported options."
			;;
		21)
			error_message="Width option requires an integer value of 80 or more.\nYou entered: $2"
			;;
		*)	error_message="error unknown: $@"
			set -- 99
			;;
	esac
	# then print it and exit
	print_screen_output "Error $1: $error_message"
	eval $LOGFE
	exit $1
}

# prior to script up set, pack the data into an array
# then we'll print it out later.
# args: $1 - $@ debugging string text
script_debugger()
{
	eval $LOGFS
	if [[ $B_SCRIPT_UP == 'true' ]];then
		# only return if debugger is off and no pre start up errors have occurred
		if [[ $DEBUG -eq 0 && $DEBUG_BUFFER_INDEX -eq 0 ]];then
			return 0
		# print out the stored debugging information if errors occurred
		elif [[ $DEBUG_BUFFER_INDEX -gt 0 ]];then
			for (( DEBUG_BUFFER_INDEX=0; DEBUG_BUFFER_INDEX < ${#A_DEBUG_BUFFER[@]}; DEBUG_BUFFER_INDEX++ ))
			do
				print_screen_output "${A_DEBUG_BUFFER[$DEBUG_BUFFER_INDEX]}"
			done
			DEBUG_BUFFER_INDEX=0
		fi
		# or print out normal debugger messages if debugger is on
		if [[ $DEBUG -gt 0 ]];then
			print_screen_output "$1"
		fi
	else
		if [[ $B_DEBUG_FLOOD == 'true' && $DEBUG_BUFFER_INDEX -gt 10 ]];then
			error_handler 2
		# this case stores the data for later printout, will print out only
		# at B_SCRIPT_UP == 'true' if array index > 0
		else
			A_DEBUG_BUFFER[$DEBUG_BUFFER_INDEX]="$1"
			# increment count for next pre script up debugging error
			(( DEBUG_BUFFER_INDEX++ ))
		fi
	fi
	eval $LOGFE
}

# NOTE: no logging available until get_parameters is run, since that's what sets logging
# in order to trigger earlier logging manually set B_USE_LOGGING to true in top variables.
# $1 alone: logs data; $2 with or without $3 logs func start/end.
# $1 type (fs/fe/cat/raw) or logged data; [$2 is $FUNCNAME; [$3 - function args]]
log_function_data()
{
	if [ "$B_USE_LOGGING" == 'true' ];then
		local logged_data='' spacer='   ' line='----------------------------------------'
		case $1 in
			fs)
				logged_data="Function: $2 - Primary: Start"
				if [ -n "$3" ];then
					logged_data="$logged_data\n${spacer}Args: $3"
				fi
				spacer=''
				;;
			fe)
				logged_data="Function: $2 - Primary: End"
				spacer=''
				;;
			cat)
				if [[ $B_LOG_FULL_DATA == 'true' ]];then
					for cat_file in $2
					do
						logged_data="$logged_data\n$line\nFull file data: cat $cat_file\n\n$( cat $cat_file )\n$line\n"
					done
					spacer=''
				fi
				;;
			raw)
				if [[ $B_LOG_FULL_DATA == 'true' ]];then
					logged_data="\n$line\nRaw system data:\n\n$2\n$line\n"
					spacer=''
				fi
				;;
			*)
				logged_data="$1"
				;;
		esac
		# Create any required line breaks and strip out escape color code, either ansi (case 1)or irc (case 2).
		# This pattern doesn't work for irc colors, if we need that someone can figure it out
		if [[ -n $logged_data ]];then
			if [[ $B_LOG_COLORS != 'true' ]];then
				echo -e "${spacer}$logged_data" | sed $SED_RX 's/\x1b\[[0-9]{1,2}(;[0-9]{1,2}){0,2}m//g' >> $LOG_FILE
			else
				echo -e "${spacer}$logged_data" >> $LOG_FILE
			fi
		fi
	fi
}

# called in the initial -@ 10 script args setting so we can get logging as soon as possible
# will have max 3 files, inxi.log, inxi.1.log, inxi.2.log
create_rotate_logfiles()
{
	# do the rotation if logfile exists
	if [[ -f $LOG_FILE ]];then
		# copy if present second to third
		if [[ -f $LOG_FILE_1 ]];then
			mv -f $LOG_FILE_1 $LOG_FILE_2
		fi
		# then copy initial to second
		mv -f $LOG_FILE $LOG_FILE_1
	fi
	# now create the logfile
	touch $LOG_FILE
	# and echo the start data
	echo "=========================================================" >> $LOG_FILE
	echo "START $SELF_NAME LOGGING:"                               >> $LOG_FILE
	echo "Script started: $( date +%Y-%m-%d-%H:%M:%S )"              >> $LOG_FILE
	echo "=========================================================" >> $LOG_FILE
}

# args: $1 - download url, not including file name; $2 - string to print out
# $3 - update type option
# note that $1 must end in / to properly construct the url path
script_self_updater()
{
	eval $LOGFS
	local downloader_error=0 file_contents='' downloader_man_error=0 
	local man_file_location=$( set_man_location )
	local man_file_path="$man_file_location/inxi.1.gz" 
	
	if [[ $B_IRC == 'true' ]];then
		print_screen_output "Sorry, you can't run the $SELF_NAME self updater option (-$3) in an IRC client."
		exit 1
	fi

	print_screen_output "Starting $SELF_NAME self updater."
	print_screen_output "Currently running $SELF_NAME version number: $SELF_VERSION"
	print_screen_output "Current version patch number: $SELF_PATCH"
	print_screen_output "Current version release date: $SELF_DATE"
	print_screen_output "Updating $SELF_NAME in $SELF_PATH using $2 as download source..."
	case $DOWNLOADER in
		curl)
			file_contents="$( curl $NO_SSL_OPT -s $1$SELF_NAME )" || downloader_error=$?
			;;
		fetch)
			file_contents="$( fetch $NO_SSL_OPT -q -o - $1$SELF_NAME )" || downloader_error=$?
			;;
		ftp)
			file_contents="$( ftp $NO_SSL_OPT -o - $1$SELF_NAME 2>/dev/null )" || downloader_error=$?
			;;
		wget)
			file_contents="$( wget $NO_SSL_OPT -q -O - $1$SELF_NAME )" || downloader_error=$?
			;;
		no-downloader)
			downloader_error=1
			;;
	esac

	# then do the actual download
	if [[  $downloader_error -eq 0 ]];then
		# make sure the whole file got downloaded and is in the variable
		if [[ -n $( grep '###\*\*EOF\*\*###' <<< "$file_contents" ) ]];then
			echo "$file_contents" > $SELF_PATH/$SELF_NAME || error_handler 14 "$?"
			chmod +x $SELF_PATH/$SELF_NAME || error_handler 15 "$?"
			parse_version_data 'main'
			parse_version_data 'patch'
			parse_version_data 'date'
			print_screen_output "Successfully updated to $2 version: $SELF_VERSION"
			print_screen_output "New $2 version patch number: $SELF_PATCH"
			print_screen_output "New $2 version release date: $SELF_DATE"
			print_screen_output "To run the new version, just start $SELF_NAME again."
			print_screen_output "----------------------------------------"
			print_screen_output "Starting download of man page file now."
			if [[ ! -d $man_file_location ]];then
				print_screen_output "The required man directory was not detected on your system, unable to continue: $man_file_location"
			else
				if [[ $B_ROOT == 'true' ]];then
					print_screen_output "Checking Man page download URL..."
					if [[ -f /usr/share/man/man8/inxi.8.gz ]];then
						print_screen_output "Updating man page location to man1."
						mv -f /usr/share/man/man8/inxi.8.gz $man_file_location/inxi.1.gz 
						if type -p mandb &>/dev/null;then
							exec $( type -p mandb ) -q 
						fi
					fi
					if [[ $DOWNLOADER == 'wget' ]];then
						wget $NO_SSL_OPT -q --spider $MAN_FILE_DOWNLOAD || downloader_man_error=$?
					fi
					if [[ $downloader_man_error -eq 0 ]];then
						if [[ $DOWNLOADER == 'wget' ]];then
							print_screen_output "Man file download URL verified: $MAN_FILE_DOWNLOAD"
						fi
						print_screen_output "Downloading Man page file now."
						case $DOWNLOADER in
							curl)
								curl $NO_SSL_OPT -s -o $man_file_path $MAN_FILE_DOWNLOAD || downloader_man_error=$?
								;;
							fetch)
								fetch $NO_SSL_OPT -q -o $man_file_path $MAN_FILE_DOWNLOAD || downloader_man_error=$?
								;;
							ftp)
								ftp $NO_SSL_OPT -o $man_file_path $MAN_FILE_DOWNLOAD 2>/dev/null || downloader_man_error=$?
								;;
							wget)
								wget $NO_SSL_OPT -q -O $man_file_path $MAN_FILE_DOWNLOAD || downloader_man_error=$?
								;;
							no-downloader)
								downloader_man_error=1
								;;
						esac
						if [[ $downloader_man_error -gt 0 ]];then
							print_screen_output "Oh no! Something went wrong downloading the Man gz file at: $MAN_FILE_DOWNLOAD"
							print_screen_output "Check the error messages for what happened. Error: $downloader_man_error"
						else
							print_screen_output "Download/install of man page successful. Check to make sure it works: man inxi"
						fi
					else
						print_screen_output "Man file download URL failed, unable to continue: $MAN_FILE_DOWNLOAD"
					fi
				else
					print_screen_output "Updating / Installing the Man page requires root user, writing to: $man_file_location"
					print_screen_output "If you want the man page, you'll have to run $SELF_NAME -$3 as root."
				fi
			fi
			exit 0
		else
			error_handler 16
		fi
	# now run the error handlers on any wget failure
	else
		if [[ $2 == 'source server' ]];then
			error_handler 8 "$downloader_error"
		elif [[ $2 == 'alt server' ]];then
			error_handler 10 "$1"
		else
			error_handler 12 "$1"
		fi
	fi
	eval $LOGFS
}

set_man_location()
{
	local location='' default_location='/usr/share/man/man1' 
	local man_paths=$(man --path 2>/dev/null) man_local='/usr/local/share/man'
	local b_use_local=false
	
	if [[ -n "$man_paths" && -n $( grep $man_local <<< "$man_paths" ) ]];then
		b_use_local=true
	fi
	
	# for distro installs, existing inxi man manual installs, do nothing
	if [[ -f $default_location/inxi.1.gz ]];then
		location=$default_location
	else
		if [[ $b_use_local == 'true' ]];then
			if [[ ! -d $man_local/man1 ]];then
				mkdir $man_local/man1
			fi
			location="$man_local/man1"
		fi
# 		print_screen_output "Updating man page location to man1."
# 		mv -f /usr/share/man/man1/inxi.1.gz /usr/local/share/man/man1/inxi.1.gz 
# 		if type -p mandb &>/dev/null;then
# 			exec $( type -p mandb ) -q 
# 		fi
	fi
	
	if [[ -z "$location" ]];then
		location=$default_location
	fi
	
	echo $location
}

# args: $1 - debug data type: sys|xorg|disk
debug_data_collector()
{
	local xiin_app='' sys_data_file='' error='' b_run_xiin='false' b_xiin_downloaded='false'
	local Debug_Data_Dir='' bsd_string='' xorg_d_files='' xorg_file='' a_distro_ids=''
	local completed_gz_file='' Xiin_File='xiin.py' ftp_upload='ftp.techpatterns.com/incoming'
	local Line='-------------------------' 
	local start_directory=$( pwd )
	local host='' debug_i='' root_string='' b_perl_worked='false' b_uploaded='false'
	
	if (( "$BASH" >= 4 ));then
		host="${HOSTNAME,,}"
	else 
		host=$( tr '[A-Z]' '[a-z]' <<< "$HOSTNAME" )
	fi
	
	if [[ $B_DEBUG_I == 'true' ]];then
		debug_i='i'
	fi
	
	if [[ -n $host ]];then
		host=${host// /-}
	else
		host="-no-host"
	fi
	if [[ -n $BSD_TYPE ]];then
		bsd_string="-$BSD_TYPE-$BSD_VERSION"
	fi
	if [[ $( whoami ) == 'root' ]];then
		root_string='-root'
	fi
	
	Debug_Data_Dir="inxi$bsd_string-$host-$(date +%Y%m%d-%H%M%S)-$1$root_string" 
	
	if [[ $B_IRC == 'false' ]];then
		if [[ -n $ALTERNATE_FTP ]];then
			ftp_upload=$ALTERNATE_FTP
		fi
		echo "Starting debugging data collection type: $1"
		cd $SELF_DATA_DIR
		if [[ -d $SELF_DATA_DIR/$Debug_Data_Dir ]];then
			echo "Deleting previous $SELF_NAME debugger data directory..."
			rm -rf $SELF_DATA_DIR/$Debug_Data_Dir
		fi
		mkdir $SELF_DATA_DIR/$Debug_Data_Dir
		if [[ -f $SELF_DATA_DIR/$Debug_Data_Dir.tar.gz ]];then
			echo 'Deleting previous tar.gz file...'
			rm -f $SELF_DATA_DIR/$Debug_Data_Dir.tar.gz
		fi
		
		echo 'Collecting system info: sensors, lsusb, lspci, lspci -v data, plus /proc data'
		echo 'also checking for dmidecode data: note, you must be root to have dmidecode work.'
		echo "Data going into: $SELF_DATA_DIR/$Debug_Data_Dir"
		# bsd tools http://cb.vu/unixtoolbox.xhtml
		# freebsd
		if type -p pciconf &>/dev/null;then
			pciconf -l -cv &> $Debug_Data_Dir/bsd-pciconf-cvl.txt
			pciconf -vl &> $Debug_Data_Dir/bsd-pciconf-vl.txt
			pciconf -l &> $Debug_Data_Dir/bsd-pciconf-l.txt
		else
			touch $Debug_Data_Dir/bsd-pciconf-absent
		fi
		# openbsd
		if type -p pcidump &>/dev/null;then
			pcidump &> $Debug_Data_Dir/bsd-pcidump-openbsd.txt
			pcidump -v &> $Debug_Data_Dir/bsd-pcidump-v-openbsd.txt
		else
			touch $Debug_Data_Dir/bsd-pcidump-openbsd-absent
		fi
		# netbsd
		if type -p pcictl &>/dev/null;then
			pcictl list &> $Debug_Data_Dir/bsd-pcictl-list-netbsd.txt
			pcictl list -n &> $Debug_Data_Dir/bsd-pcictl-list-n-netbsd.txt
		else
			touch $Debug_Data_Dir/bsd-pcictl-netbsd-absent
		fi
		if type -p sysctl &>/dev/null;then
			sysctl -a &> $Debug_Data_Dir/bsd-sysctl-a.txt
		else
			touch $Debug_Data_Dir/bsd-sysctl-absent
		fi
		if type -p usbdevs &>/dev/null;then
			usbdevs -v  &> $Debug_Data_Dir/bsd-usbdevs-v.txt
		else
			touch $Debug_Data_Dir/bsd-usbdevs-absent
		fi
		if type -p kldstat &>/dev/null;then
			kldstat  &> $Debug_Data_Dir/bsd-kldstat.txt
		else
			touch $Debug_Data_Dir/bsd-kldstat-absent
		fi
		# diskinfo -v <disk>
		# fdisk <disk>
		dmidecode &> $Debug_Data_Dir/dmidecode.txt
		
		get_repo_data "$SELF_DATA_DIR/$Debug_Data_Dir"
		
		if type -p shopt &>/dev/null;then
			shopt -s nullglob
			a_distro_ids=(/etc/*[-_]{release,version})
			shopt -u nullglob
			echo ${a_distro_ids[@]} &> $Debug_Data_Dir/etc-distro-files.txt
			for distro_file in ${a_distro_ids[@]} /etc/issue
			do
				if [[ -f $distro_file ]];then
					cat $distro_file &> $Debug_Data_Dir/distro-file${distro_file//\//-}
				fi
			done
		fi
		dmesg &> $Debug_Data_Dir/dmesg.txt
		lscpu &> $Debug_Data_Dir/lscpu.txt
		lspci &> $Debug_Data_Dir/lspci.txt
		lspci -k &> $Debug_Data_Dir/lspci-k.txt
		lspci -knn &> $Debug_Data_Dir/lspci-knn.txt
		lspci -n &> $Debug_Data_Dir/lspci-n.txt
		lspci -nn &> $Debug_Data_Dir/lspci-nn.txt
		lspci -mm &> $Debug_Data_Dir/lspci-mm.txt
		lspci -mmnn &> $Debug_Data_Dir/lspci-mmnn.txt
		lspci -mmnnv &> $Debug_Data_Dir/lspci-mmnnv.txt
		lspci -v &> $Debug_Data_Dir/lspci-v.txt
		lsusb &> $Debug_Data_Dir/lsusb.txt
		if type -p hciconfig &>/dev/null;then
			hciconfig -a &> $Debug_Data_Dir/hciconfig-a.txt
		else
			touch $Debug_Data_Dir/hciconfig-absent
		fi
		ls /sys &> $Debug_Data_Dir/ls-sys.txt
		ps aux &> $Debug_Data_Dir/ps-aux.txt
		ps -e &> $Debug_Data_Dir/ps-e.txt
		ps -p 1 &> $Debug_Data_Dir/ps-p-1.txt
		echo "Collecting init data..."
		cat /proc/1/comm &> $Debug_Data_Dir/proc-1-comm.txt
		runlevel &> $Debug_Data_Dir/runlevel.txt
		if type -p rc-status &>/dev/null;then
			rc-status -a &> $Debug_Data_Dir/rc-status-a.txt
			rc-status -l &> $Debug_Data_Dir/rc-status-l.txt
			rc-status -r &> $Debug_Data_Dir/rc-status-r.txt
		else
			touch $Debug_Data_Dir/rc-status-absent
		fi
		if type -p systemctl &>/dev/null;then
			systemctl list-units &> $Debug_Data_Dir/systemctl-list-units.txt
			systemctl list-units --type=target &> $Debug_Data_Dir/systemctl-list-units-target.txt
		else
			touch $Debug_Data_Dir/systemctl-absent
		fi
		if type -p initctl &>/dev/null;then
			initctl list &> $Debug_Data_Dir/initctl-list.txt
		else
			touch $Debug_Data_Dir/initctl-absent
		fi
		sensors &> $Debug_Data_Dir/sensors.txt
		if type -p strings &>/dev/null;then
			touch $Debug_Data_Dir/strings-present
		else
			touch $Debug_Data_Dir/strings-absent
		fi
		local id_dir='/sys/class/power_supply/' 
		local ids=$( ls $id_dir 2>/dev/null )
		if [[ -n $ids ]];then
			for batid in $ids 
			do
				cat $id_dir$batid'/uevent' &> $Debug_Data_Dir/sys-power-supply-$batid.txt
			done
		else
			touch $Debug_Data_Dir/sys-power-supply-none
		fi
		
		# leaving this commented out to remind that some systems do not
		# support strings --version, but will just simply hang at that command
		# which you can duplicate by simply typing: strings then hitting enter, you will get hang.
		# strings --version  &> $Debug_Data_Dir/strings.txt
		if type -p nvidia-smi &>/dev/null;then
			nvidia-smi -q &> $Debug_Data_Dir/nvidia-smi-q.txt
			nvidia-smi -q -x &> $Debug_Data_Dir/nvidia-smi-xq.txt
		else
			touch $Debug_Data_Dir/nvidia-smi-absent
		fi
		head -n 1 /proc/asound/card*/codec* &> $Debug_Data_Dir/proc-asound-card-codec.txt
		if [[ -f /proc/version ]];then
			cat /proc/version &> $Debug_Data_Dir/proc-version.txt
		else
			touch $Debug_Data_Dir/proc-version-absent
		fi
		echo $CC &> $Debug_Data_Dir/cc-content.txt
		ls /usr/bin/gcc* &> $Debug_Data_Dir/gcc-sys-versions.txt
		if type -p gcc &>/dev/null;then
			gcc --version &> $Debug_Data_Dir/gcc-version.txt
		else
			touch $Debug_Data_Dir/gcc-absent
		fi
		if type -p clang &>/dev/null;then
			clang --version &> $Debug_Data_Dir/clang-version.txt
		else
			touch $Debug_Data_Dir/clang-absent
		fi
		if type -p systemd-detect-virt &>/dev/null;then
			systemd-detect-virt &> $Debug_Data_Dir/systemd-detect-virt-info.txt
		else
			touch $Debug_Data_Dir/systemd-detect-virt-absent
		fi
		if type -p perl &>/dev/null;then
			perl -MFile::Find=find -MFile::Spec::Functions -Tlwe 'find { wanted => sub { print canonpath $_ if /\.pm\z/ }, no_chdir => 1 }, @INC' &> $Debug_Data_Dir/perl-modules.txt
		else
			touch $Debug_Data_Dir/perl-missing.txt
		fi
		cat /etc/src.conf &> $Debug_Data_Dir/bsd-etc-src-conf.txt
		cat /etc/make.conf &> $Debug_Data_Dir/bsd-etc-make-conf.txt
		cat /etc/issue &> $Debug_Data_Dir/etc-issue.txt
		cat $FILE_LSB_RELEASE &> $Debug_Data_Dir/lsb-release.txt
		cat $FILE_OS_RELEASE &> $Debug_Data_Dir/os-release.txt
		cat $FILE_ASOUND_DEVICE &> $Debug_Data_Dir/proc-asound-device.txt
		cat $FILE_ASOUND_VERSION &> $Debug_Data_Dir/proc-asound-version.txt
		cat $FILE_CPUINFO &> $Debug_Data_Dir/proc-cpu-info.txt
		cat $FILE_MEMINFO &> $Debug_Data_Dir/proc-meminfo.txt
		cat $FILE_MODULES &> $Debug_Data_Dir/proc-modules.txt
		cat /proc/net/arp &> $Debug_Data_Dir/proc-net-arp.txt 
		# bsd data
		cat /var/run/dmesg.boot &> $Debug_Data_Dir/bsd-var-run-dmesg.boot.txt 
		echo $COLS_INNER &> $Debug_Data_Dir/cols-inner.txt
		echo $XDG_CONFIG_HOME &> $Debug_Data_Dir/xdg_config_home.txt
		echo $XDG_CONFIG_DIRS &> $Debug_Data_Dir/xdg_config_dirs.txt
		echo $XDG_DATA_HOME &> $Debug_Data_Dir/xdg_data_home.txt
		echo $XDG_DATA_DIRS &> $Debug_Data_Dir/xdg_data_dirs.txt
		
		check_recommends_user_output &> $Debug_Data_Dir/check-recommends-user-output.txt
		if [[ $1 == 'xorg' || $1 == 'all' ]];then
			if [[ $B_RUNNING_IN_DISPLAY != 'true' ]];then
				echo 'Warning: only some of the data collection can occur if you are not in X'
				touch $Debug_Data_Dir/warning-user-not-in-x
			fi
			if [[ $B_ROOT == 'true' ]];then
				echo 'Warning: only some of the data collection can occur if you are running as Root user'
				touch $Debug_Data_Dir/warning-root-user
			fi
			echo 'Collecting Xorg log and xorg.conf files'
			if [[ -e $FILE_XORG_LOG ]];then
				cat $FILE_XORG_LOG &> $Debug_Data_Dir/xorg-log-file.txt
			else
				touch $Debug_Data_Dir/xorg-log-file-absent
			fi
			if [[ -e /etc/X11/xorg.conf ]];then
				cat /etc/X11/xorg.conf &> $Debug_Data_Dir/xorg-conf.txt
			else
				touch $Debug_Data_Dir/xorg-conf-file-absent
			fi
			if [[ -n $( ls /etc/X11/xorg.conf.d/ 2>/dev/null ) ]];then
				ls /etc/X11/xorg.conf.d &> $Debug_Data_Dir/ls-etc-x11-xorg-conf-d.txt
				xorg_d_files=$(ls /etc/X11/xorg.conf.d)
				for xorg_file in $xorg_d_files
				do
					cat /etc/X11/xorg.conf.d/$xorg_file &> $Debug_Data_Dir/xorg-conf-d-$xorg_file.txt
				done
			else
				touch $Debug_Data_Dir/xorg-conf-d-files-absent
			fi
			echo 'Collecting X, xprop, glxinfo, xrandr, xdpyinfo data, wayland, weston...'
			if type -p weston-info &>/dev/null; then
				weston-info &> $Debug_Data_Dir/weston-info.txt
			else
				touch $Debug_Data_Dir/weston-info-absent
			fi
			if type -p weston &>/dev/null; then
				weston --version &> $Debug_Data_Dir/weston-version.txt
			else
				touch $Debug_Data_Dir/weston-absent
			fi
			if type -p xprop &>/dev/null; then
				xprop -root &> $Debug_Data_Dir/xprop_root.txt
			else
				touch $Debug_Data_Dir/xprop-absent
			fi
			if type -p glxinfo &>/dev/null; then
				glxinfo &> $Debug_Data_Dir/glxinfo-full.txt
				glxinfo -B &> $Debug_Data_Dir/glxinfo-B.txt
			else
				touch $Debug_Data_Dir/glxinfo-absent
			fi
			if type -p xdpyinfo &>/dev/null; then
				xdpyinfo &> $Debug_Data_Dir/xdpyinfo.txt
			else
				touch $Debug_Data_Dir/xdpyinfo-absent
			fi
			if type -p xrandr &>/dev/null; then
				xrandr &> $Debug_Data_Dir/xrandr.txt
			else
				touch $Debug_Data_Dir/xrandr-absent
			fi
			if type -p X &>/dev/null; then
				X -version &> $Debug_Data_Dir/x-version.txt
			else
				touch $Debug_Data_Dir/x-absent
			fi
			if type -p Xorg &>/dev/null; then
				Xorg -version &> $Debug_Data_Dir/xorg-version.txt
			else
				touch $Debug_Data_Dir/xorg-absent
			fi
			
			echo $GNOME_DESKTOP_SESSION_ID &> $Debug_Data_Dir/gnome-desktop-session-id.txt
			# kde 3 id
			echo $KDE_FULL_SESSION &> $Debug_Data_Dir/kde3-full-session.txt
			echo $KDE_SESSION_VERSION &> $Debug_Data_Dir/kde-gte-4-session-version.txt
			if type -p kf5-config &>/dev/null; then
				kf5-config --version &> $Debug_Data_Dir/kde-kf5-config-version-data.txt
			elif type -p kf6-config &>/dev/null; then
				kf6-config --version &> $Debug_Data_Dir/kde-kf6-config-version-data.txt
			elif type -p kf$KDE_SESSION_VERSION-config &>/dev/null; then
				kf$KDE_SESSION_VERSION-config --version &> $Debug_Data_Dir/kde-kf$KDE_SESSION_VERSION-KSV-config-version-data.txt
			else
				touch $Debug_Data_Dir/kde-kf-config-absent
			fi
			if type -p plasmashell &>/dev/null; then
				plasmashell --version &> $Debug_Data_Dir/kde-plasmashell-version-data.txt
			else
				touch $Debug_Data_Dir/kde-plasmashell-absent
			fi
			if type -p kwin_x11 &>/dev/null; then
				kwin_x11 --version &> $Debug_Data_Dir/kde-kwin_x11-version-data.txt
			else
				touch $Debug_Data_Dir/kde-kwin_x11-absent
			fi
			if type -p kded4 &>/dev/null; then
				kded4 --version &> $Debug_Data_Dir/kded4-version-data.txt
			elif type -p kded5 &>/dev/null; then
				kded5 --version &> $Debug_Data_Dir/kded5-version-data.txt
			elif type -p kded &>/dev/null; then
				kded --version &> $Debug_Data_Dir/kded-version-data.txt
			else
				touch $Debug_Data_Dir/kded-$KDE_SESSION_VERSION-absent
			fi
			# kde 5/plasma desktop 5, this is maybe an extra package and won't be used
			if type -p about-distro &>/dev/null; then
				about-distro &> $Debug_Data_Dir/kde-about-distro.txt
			else
				touch $Debug_Data_Dir/kde-about-distro-absent
			fi
			echo $XDG_CURRENT_DESKTOP &> $Debug_Data_Dir/xdg-current-desktop.txt
			echo $XDG_SESSION_DESKTOP &> $Debug_Data_Dir/xdg-session-desktop.txt
			echo $DESKTOP_SESSION &> $Debug_Data_Dir/desktop-session.txt
			echo $GDMSESSION &> $Debug_Data_Dir/gdmsession.txt
			# wayland data collectors:
			echo $XDG_SESSION_TYPE &> $Debug_Data_Dir/xdg-session-type.txt
			echo $WAYLAND_DISPLAY &> $Debug_Data_Dir/wayland-display.txt
			echo $GDK_BACKEND &> $Debug_Data_Dir/gdk-backend.txt
			echo $QT_QPA_PLATFORM &> $Debug_Data_Dir/qt-qpa-platform.txt
			echo $CLUTTER_BACKEND &> $Debug_Data_Dir/clutter-backend.txt
			echo $SDL_VIDEODRIVER &> $Debug_Data_Dir/sdl-videodriver.txt
			if type -p loginctl &>/dev/null;then
				loginctl --no-pager list-sessions &> $Debug_Data_Dir/loginctl-list-sessions.txt
			else
				touch $Debug_Data_Dir/loginctl-absent
			fi
		fi
		if [[ $1 == 'disk' || $1 == 'all' ]];then
			echo 'Collecting dev, label, disk, uuid data, df...'
			ls -l /dev &> $Debug_Data_Dir/dev-data.txt
			ls -l /dev/disk &> $Debug_Data_Dir/dev-disk-data.txt
			ls -l /dev/disk/by-id &> $Debug_Data_Dir/dev-disk-id-data.txt
			ls -l /dev/disk/by-label &> $Debug_Data_Dir/dev-disk-label-data.txt
			ls -l /dev/disk/by-uuid &> $Debug_Data_Dir/dev-disk-uuid-data.txt
			# http://comments.gmane.org/gmane.linux.file-systems.zfs.user/2032
			ls -l /dev/disk/by-wwn &> $Debug_Data_Dir/dev-disk-wwn-data.txt
			ls -l /dev/disk/by-path &> $Debug_Data_Dir/dev-disk-path-data.txt
			ls -l /dev/mapper &> $Debug_Data_Dir/dev-disk-mapper-data.txt
			readlink /dev/root &> $Debug_Data_Dir/dev-root.txt
			df -h -T -P --exclude-type=aufs --exclude-type=squashfs --exclude-type=unionfs --exclude-type=devtmpfs --exclude-type=tmpfs --exclude-type=iso9660 --exclude-type=devfs --exclude-type=linprocfs --exclude-type=sysfs --exclude-type=fdescfs &> $Debug_Data_Dir/df-h-T-P-excludes.txt
			df -T -P --exclude-type=aufs --exclude-type=squashfs --exclude-type=unionfs --exclude-type=devtmpfs --exclude-type=tmpfs --exclude-type=iso9660 --exclude-type=devfs --exclude-type=linprocfs --exclude-type=sysfs --exclude-type=fdescfs &> $Debug_Data_Dir/df-T-P-excludes.txt
			df -T -P --exclude-type=aufs --exclude-type=squashfs --exclude-type=unionfs --exclude-type=devtmpfs --exclude-type=tmpfs --exclude-type=iso9660 --exclude-type=devfs --exclude-type=linprocfs --exclude-type=sysfs --exclude-type=fdescfs --total &> $Debug_Data_Dir/df-T-P-excludes-total.txt
			df -h -T &> $Debug_Data_Dir/bsd-df-h-T-no-excludes.txt
			df -h &> $Debug_Data_Dir/bsd-df-h-no-excludes.txt
			df -k -T &> $Debug_Data_Dir/bsd-df-k-T-no-excludes.txt
			df -k &> $Debug_Data_Dir/bsd-df-k-no-excludes.txt
			atacontrol list &> $Debug_Data_Dir/bsd-atacontrol-list.txt
			camcontrol devlist &> $Debug_Data_Dir/bsd-camcontrol-devlist.txt
			# bsd tool
			mount &> $Debug_Data_Dir/mount.txt
			btrfs filesystem show  &> $Debug_Data_Dir/btrfs-filesystem-show.txt
			btrfs filesystem show --mounted  &> $Debug_Data_Dir/btrfs-filesystem-show-mounted.txt
			# btrfs filesystem show --all-devices  &> $Debug_Data_Dir/btrfs-filesystem-show-all-devices.txt
			gpart list &> $Debug_Data_Dir/bsd-gpart-list.txt
			gpart show &> $Debug_Data_Dir/bsd-gpart-show.txt
			gpart status &> $Debug_Data_Dir/bsd-gpart-status.txt
			swapctl -l -k &> $Debug_Data_Dir/bsd-swapctl-l-k.txt
			swapon -s &> $Debug_Data_Dir/swapon-s.txt
			sysctl -b kern.geom.conftxt &> $Debug_Data_Dir/bsd-sysctl-b-kern.geom.conftxt.txt
			sysctl -b kern.geom.confxml &> $Debug_Data_Dir/bsd-sysctl-b-kern.geom.confxml.txt
			zfs list &> $Debug_Data_Dir/bsd-zfs-list.txt
			zpool list &> $Debug_Data_Dir/bsd-zpool-list.txt
			zpool list -v &> $Debug_Data_Dir/bsd-zpool-list-v.txt
			df -P --exclude-type=aufs --exclude-type=squashfs --exclude-type=unionfs --exclude-type=devtmpfs --exclude-type=tmpfs --exclude-type=iso9660 &> $Debug_Data_Dir/df-P-excludes.txt
			df -P &> $Debug_Data_Dir/bsd-df-P-no-excludes.txt
			cat /proc/mdstat &> $Debug_Data_Dir/proc-mdstat.txt
			cat $FILE_PARTITIONS &> $Debug_Data_Dir/proc-partitions.txt
			cat $FILE_SCSI &> $Debug_Data_Dir/proc-scsi.txt
			cat $FILE_MOUNTS &> $Debug_Data_Dir/proc-mounts.txt
			cat /proc/sys/dev/cdrom/info &> $Debug_Data_Dir/proc-cdrom-info.txt
			ls /proc/ide/ &> $Debug_Data_Dir/proc-ide.txt
			cat /proc/ide/*/* &> $Debug_Data_Dir/proc-ide-hdx-cat.txt
			cat /etc/fstab &> $Debug_Data_Dir/etc-fstab.txt
			cat /etc/mtab &> $Debug_Data_Dir/etc-mtab.txt
			if type -p nvme &>/dev/null; then
				touch $Debug_Data_Dir/nvme-present
			else
				touch $Debug_Data_Dir/nvme-absent
			fi
		fi
		if [[ $1 == 'disk' || $1 == 'sys' || $1 == 'all' ]];then
			echo 'Collecting networking data...'
			ifconfig &> $Debug_Data_Dir/ifconfig.txt
			ip addr &> $Debug_Data_Dir/ip-addr.txt
		fi
		# create the error file in case it's needed
		if [[ $B_UPLOAD_DEBUG_DATA == 'true' || $1 == 'disk' || $1 == 'sys' || $1 == 'all' ]];then
			touch $SELF_DATA_DIR/$Debug_Data_Dir/xiin-error.txt
		fi
		# note, only bash 4> supports ;;& for case, so using if/then here
		if [[ -z $BSD_TYPE ]] && [[ $1 == 'disk' || $1 == 'sys' || $1 == 'all' ]];then
			echo $Line
			sys_data_file=$SELF_DATA_DIR/$Debug_Data_Dir/xiin-sys.txt
			echo "Getting file paths in /sys..."
			ls_sys 1
			ls_sys 2
			ls_sys 3
			ls_sys 4
			# note, this generates more lines than the full sys parsing, so only use if required
			# ls_sys 5 
			touch $sys_data_file
			if type -p perl &>/dev/null;then
				echo "Parsing /sys files..."
				echo -n "Using Perl: " && perl --version | grep -oE 'v[0-9.]+'
				sys_traverse_data="$( perl -e '
				use File::Find;
				use strict;
				# use warnings;
				use 5.010;
				my @content = (); 
				find( \&wanted, "/sys");
				process_data( @content );
				sub wanted {
					return if -d; # not directory
					return unless -e; # Must exist
					return unless -r; # Must be readable
					return unless -f; # Must be file
					# note: a new file in 4.11 /sys can hang this, it is /parameter/ then
					# a few variables. Since inxi does not need to see that file, we will
					# not use it. Also do not need . files or __ starting files
					return if $File::Find::name =~ /\/(\.[a-z]|__|parameters\/|debug\/)/;
					# comment this one out if you experience hangs or if 
					# we discover syntax of foreign language characters
					return unless -T; # Must be ascii like
					# print $File::Find::name . "\n";
					push @content, $File::Find::name;
					return;
				}
				sub process_data {
					my $result = "";
					my $row = "";
					my $fh;
					my $data="";
					my $sep="";
					# no sorts, we want the order it comes in
					# @content = sort @content; 
					foreach (@content){
						$data="";
						$sep="";
						open($fh, "<$_");
						while ($row = <$fh>) {
							chomp $row;
							$data .= $sep . "\"" . $row . "\"";
							$sep=", ";
						}
						$result .= "$_:[$data]\n";
						# print "$_:[$data]\n"
					}
					# print scalar @content . "\n";
					print "$result";
				} ' )"
				if [[ -z "$sys_traverse_data" ]];then
					echo -e "ERROR: failed to generate /sys data - removing data file.\nContinuing with incomplete data collection."
					echo "Continuing with incomplete data collection."
					rm -f $sys_data_file
					echo "/sys data generation failed. No data collected." >> $Debug_Data_Dir/xiin-error.txt
				else
					b_perl_worked='true'
					echo 'Completed /sys data collection.'
					echo -n "$sys_traverse_data" > $sys_data_file
				fi
			fi
			if [[ -z "$sys_traverse_data" ]];then
				download_xiin 'sys'
				if [[ $? -eq 0 ]];then
					b_run_xiin='true'
					b_xiin_downloaded='true'
					echo "Running $Xiin_File tool now on /sys..."
					echo -n "Using " && python --version
					python --version &> $Debug_Data_Dir/python-version.txt
					python ./$Xiin_File -d /sys -f $sys_data_file
					if [[ $? -ne 0 ]];then
						error=$?
						echo -e "ERROR: $Xiin_File exited with error $error - removing data file.\nContinuing with incomplete data collection."
						rm -f $sys_data_file
						echo "$Xiin_File data generation failed with python error $error" >> $Debug_Data_Dir/xiin-error.txt
					fi
				fi
			fi
			
		fi
		# has to be before gz cleanup
		if [[ $B_UPLOAD_DEBUG_DATA == 'true' ]];then
			if [[ $b_xiin_downloaded == 'false' && $b_perl_worked == 'false' ]];then
				echo $Line
				download_xiin 'upload'
				if [[ $? -eq 0 ]];then
					b_run_xiin='true'
				fi
			fi
		fi
		echo $Line
		echo "Creating $SELF_NAME output file now. This can take a few seconds..."
		echo "Starting $SELF_NAME from: $start_directory"
		cd $start_directory
		$SELF_PATH/$SELF_NAME -F${debug_i}Rfrploudmxxx -c 0 -@ 8 -y 120 > $SELF_DATA_DIR/$Debug_Data_Dir/inxi-F${debug_i}Rfrploudmxxxy120.txt
		cp $LOG_FILE $SELF_DATA_DIR/$Debug_Data_Dir
		if [[ -f $SELF_DATA_DIR/$Debug_Data_Dir.tar.gz ]];then
			echo "Found and removing previous tar.gz data file: $Debug_Data_Dir.tar.gz"
			rm -f $SELF_DATA_DIR/$Debug_Data_Dir.tar.gz
		fi
		cd $SELF_DATA_DIR
		echo 'Creating tar.gz compressed file of this material now. Contents:'
		echo $Line
		tar -cvzf $Debug_Data_Dir.tar.gz $Debug_Data_Dir
		echo $Line
		echo 'Cleaning up leftovers...'
		rm -rf $Debug_Data_Dir
		echo 'Testing gzip file integrity...'
		gzip -t $Debug_Data_Dir.tar.gz
		if [[ $? -gt 0 ]];then
			echo 'Data in gz is corrupted, removing gzip file, try running data collector again.'
			rm -f $Debug_Data_Dir.tar.gz
			echo "Data in gz is corrupted, removed gzip file" >> $Debug_Data_Dir/gzip-error.txt
		else
			echo 'All done, you can find your data gzipped directory here:'
			completed_gz_file=$SELF_DATA_DIR/$Debug_Data_Dir.tar.gz
			echo $completed_gz_file
			if [[ $B_UPLOAD_DEBUG_DATA == 'true' ]];then
				echo $Line
				if [[ $b_perl_worked == 'true' ]];then
					upload_debugger_data "$completed_gz_file"
					if [[ $? -gt 0 ]];then
						echo "Error: looks like the Perl ftp upload failed. Error number: $?"
					else
						b_uploaded='true'
						echo "Hurray! Looks like the Perl ftp upload worked!"
					fi
				fi
				if [[ $b_uploaded == 'false' ]];then
					if [[ $b_run_xiin == 'true' ]];then
						echo "Running automatic upload of data to remote server $ftp_upload now..."
						python ./$Xiin_File --version
						python ./$Xiin_File -u $completed_gz_file $ftp_upload
						if [[ $? -gt 0 ]];then
							echo $Line
							echo "Error: looks like the Python ftp upload failed. Error number: $?"
							# echo "The ftp upload failed. Error number: $?" >> $Debug_Data_Dir/xiin-error.txt
						fi
					else
						echo 'Unable to run the automatic ftp upload because no uploaders appear to be working or available.'
						# that has been removed at this point, so no more logging
						# echo "Unable to run the automoatic ftp upload because of an error with the xiin download" >> $Debug_Data_Dir/xiin-error.txt
					fi
				fi
			else
				echo 'You can upload this here using most file managers: ftp.techpatterns.com/incoming'
				echo 'then let a maintainer know it is uploaded.'
			fi
		fi
	else
		echo 'This feature only available in console or shell client! Exiting now.'
	fi
	exit 0
}
## args: $1 - level
ls_sys()
{
	local files=''
	case $1 in
		1)files='/sys/';;
		2)files='/sys/*/';;
		3)files='/sys/*/*/';;
		4)files='/sys/*/*/*/';; # this should be enough for most use cases
		5)files='/sys/*/*/*/*/';; # very large file, shows best shortcuts though
		6)files='/sys/*/*/*/*/*/';; # slows down too much, too big, can cause ls error
		7)files='/sys/*/*/*/*/*/*/';; # impossibly big, will fail
	esac
	ls -l $files 2>/dev/null | awk '{ 
		if (NF > 7) {
			if ($1 ~/^d/){
				f="d - "
			}
			else if ($1 ~/^l/){
				f="l - "
			}
			else {
				f="f - "
			}
			# includes -> target for symbolic link if present
			print "\t" f $9 " "  $10 " " $11
		} 
		else if (!/^total / ) { 
			print $0
		} 
	}' &> $Debug_Data_Dir/sys-level-$1.txt
}

## args: $1 - debugger file name
upload_debugger_data()
{
	local result='' debugger_file=$1 
	
	if ! type -p perl &>/dev/null;then
		echo "Perl is not installed!"
		return 2
	elif ! perl -MNet::FTP -e 1 &>/dev/null;then
		echo "Required Perl module Net::FTP not installed."
		return 3
	fi
	export debugger_file
	echo "Starting Perl Uploader..."
	
	result="$( perl -e '
	use strict;
	use warnings;
	use Net::FTP;
	my ($ftp, $host, $user, $pass, $dir, $fpath, $error);
	$host = "ftp.techpatterns.com";
	$user = "anonymous";
	$pass = "anonymous\@techpatterns.com";
	$dir = "incoming";
	$fpath = $ENV{debugger_file};
	# NOTE: important: must explicitly set to passive true/1
	$ftp = Net::FTP->new($host, Debug => 0, Passive => 1);
	$ftp->login($user, $pass) || die $ftp->message;
	$ftp->binary();
	$ftp->cwd($dir);
	print "Connected to FTP server.\n";
	$ftp->put($fpath) || die $ftp->message;
	$ftp->quit;
	print "Uploaded file.\n";
	print $ftp->message;
	' )"
	
	echo "$result"
	if [[ "$result" == *Goodbye* ]];then
		return 0
	else
		return 1
	fi
}
# $1 - download type [sys|upload]
download_xiin()
{
	local xiin_download='' xiin_url="https://github.com/smxi/inxi/raw/xiin/$Xiin_File" 
	local downloader_error=0 download_type='uploader'
	
	if [[ $1 == 'sys' ]];then
		download_type='tree traverse'
	fi
	touch $Debug_Data_Dir/download_xiin.txt
	echo "download_xiin: \$1 - $1" >> $Debug_Data_Dir/download_xiin.txt
	echo "Downloading required $download_type tool $Xiin_File..."
	if [[ -f xiin && ! -f $Xiin_File ]];then
		mv -f xiin $Xiin_File
	fi
	# -Nc is creating really weird download anomalies, so using -O instead
	case $DOWNLOADER in
		curl)
			xiin_download="$( curl $NO_SSL_OPT -s $xiin_url )" || downloader_error=$?
			;;
		fetch)
			xiin_download="$( fetch $NO_SSL_OPT -q -o - $xiin_url )" || downloader_error=$?
			;;
		ftp)
			xiin_download="$( ftp $NO_SSL_OPT -o - $xiin_url 2>/dev/null )" || downloader_error=$?
			;;
		wget)
			xiin_download="$( wget $NO_SSL_OPT -q -O - $xiin_url )" || downloader_error=$?
			;;
		no-downloader)
			downloader_error=100
			;;
	esac
	# if nothing got downloaded kick out error, otherwise we'll use an older version
	if [[ $downloader_error -gt 0 && ! -f $Xiin_File ]];then
		echo -e "ERROR: Failed to download required file: $Xiin_File\nMaybe the remote site is down or your networking is broken?"
		if [[ $1 == 'sys' ]];then
			echo "Continuing with incomplete data collection."
		else
			echo "$SELF_NAME will be unable to automatically upload the debugger data."
		fi
		echo "$Xiin_File download failed and no existing $Xiin_File: error: $downloader_error" >> $Debug_Data_Dir/xiin-error.txt
		return 1
	elif [[ -n $( grep -s '# EOF' <<< "$xiin_download" ) || -f $Xiin_File ]];then
		if [[ -n $( grep -s '# EOF' <<< "$xiin_download" ) ]];then
			echo "Updating $Xiin_File from remote location"
			echo "$xiin_download" > $Xiin_File
		else
			echo "Using local $Xiin_File due to download failure"
		fi
		return 0
	else
		if [[ $1 == 'sys' ]];then
			echo -e "ERROR: $Xiin_File downloaded but the program file data is corrupted.\nContinuing with incomplete data collection."
		else
			echo -e "ERROR: $Xiin_File downloaded but the program file data is corrupted.\nWill not be able to automatically upload debugger data file."
		fi
		echo "$Xiin_File downloaded but the program file data is corrupted." >> $Debug_Data_Dir/xiin-error.txt
		return 2
	fi
}

check_recommends_user_output()
{
	local Line=$LINE1
	local gawk_version='N/A' sed_version='N/A' sudo_version='N/A' python_version='N/A'
	local downloaders_bsd='' perl_version='N/A'
	
	if [[ $B_IRC == 'true' ]];then
		print_screen_output "Sorry, you can't run this option in an IRC client."
		exit 1
	fi
	if [[ -n $BSD_TYPE ]];then
		downloaders_bsd='
		fetch:BSD-only~BSD-only~BSD-only~:-i_wan_ip;-w/-W;-U/-!_[11-15]_(BSDs)
		ftp:ftp-OpenBSD-only~ftp-OpenBSD-only~ftp-OpenBSD-only~:-i_wan_ip;-w/-W;-U/-!_[11-15]_(OpenBSD_only)'
	fi
	initialize_paths
	print_lines_basic "0" "" "$SELF_NAME will now begin checking for the programs it needs to operate. First a check of the main languages and tools $SELF_NAME uses. Python is only for debugging data uploads unless Perl is missing."
	echo $Line
	echo "Bash version: $( bash --version 2>&1 | awk 'BEGIN {IGNORECASE=1} /^GNU bash/ {print $4}' )"
	if type -p gawk &>/dev/null;then
		gawk_version=$( gawk --version 2>&1 | awk 'BEGIN {IGNORECASE=1} /^GNU Awk/ {print $3}' )
	fi
	if type -p sed &>/dev/null;then
		# sed (GNU sed) 4.4 OR GNU sed version 4.4
		sed_version=$( sed --version 2>&1 | awk 'BEGIN {IGNORECASE=1} /^(GNU sed version|sed)/ {print $4;exit}' )
		if [[ -z $sed_version ]];then
			# note: bsd sed shows error with --version flag
			sed_version=$( sed --version 2>&1 | awk 'BEGIN {IGNORECASE=1} /^sed: illegal option/ {print "BSD sed";exit}' )
		fi
	fi
	if type -p sudo &>/dev/null;then
		sudo_version=$( sudo -V 2>&1 | awk 'BEGIN {IGNORECASE=1} /^Sudo version/ {print $3}' )
	fi
	if type -p python &>/dev/null;then
		python_version=$( python --version 2>&1 | awk 'BEGIN {IGNORECASE=1} /^Python/ {print $2}' )
	fi
	# NOTE: does not actually handle 5/6 version, but ok for now
	if type -p perl &>/dev/null;then
		perl_version=$(perl --version | grep -m 1 -oE 'v[0-9.]+')
	fi
	echo "Gawk version: $gawk_version"
	echo "Sed version: $sed_version"
	echo "Sudo version: $sudo_version"
	echo "Python version: $python_version (deprecated)"
	echo "Perl version: $perl_version"
	echo $Line
	
	echo "Test One: Required System Directories (Linux Only)."
	print_lines_basic "0" "" "If one of these system directories is missing, $SELF_NAME cannot operate:"
	echo 
	check_recommends_items 'required-dirs'
	
	echo "Test Two: Required Core Applications."
	print_lines_basic "0" "" "If one of these applications is missing, $SELF_NAME cannot operate:"
	echo 
	check_recommends_items 'required-apps'
	
	print_lines_basic "0" "" "Test Three: Script Recommends for Graphics Features."
	print_lines_basic "0" "" "NOTE: If you do not use X these do not matter (like a headless server). Otherwise, if one of these applications is missing, $SELF_NAME will have incomplete output:"
	echo 
	check_recommends_items 'recommended-x-apps'
	
	echo 'Test Four: Script Recommends for Remaining Features.' 
	print_lines_basic "0" "" "If one of these applications is missing, $SELF_NAME will have incomplete output:"
	echo 
	check_recommends_items 'recommended-apps'
	
	echo 'Test Five: Script Recommends for Remaining Features.' 
	print_lines_basic "0" "" "One of these downloaders needed for options -i/-w/-W (-U/-! [11-15], if supported):"
	echo 
	check_recommends_items 'downloaders'
	
	echo 'Test Six: System Directories for Various Information.'
	echo '(Unless otherwise noted, these are for GNU/Linux systems)' 
	print_lines_basic "0" "" "If one of these directories is missing, $SELF_NAME may have incomplete output:"
	echo 
	check_recommends_items 'system-dirs'
	
	echo 'Test Seven: System Files for Various Information.'
	echo '(Unless otherwise noted, these are for GNU/Linux systems)' 
	print_lines_basic "0" "" "If one of these files is missing, $SELF_NAME may have incomplete output:"
	echo 
	check_recommends_items 'system-files'
	
	echo 'All tests completed.' 
}
# args: $1 - check item
check_recommends_items()
{
	local item='' item_list='' item_string='' missing_items='' missing_string=''
	local package='' application='' feature='' type='' starter='' finisher=''
	local package_deb='' package_pacman='' package_rpm='' 
	local print_string='' separator='' width=56
	local required_dirs='/proc /sys'
	# package-owner: 1 - debian/ubuntu; 2 - arch; 3 - yum/rpm
	# pardus: pisi sf -q /usr/bin/package
	local required_apps='
	df:coreutils~coreutils~coreutils~:partition_data 
	gawk:gawk~gawk~gawk~:core_tool
	grep:grep~grep~grep~:string_search 
	lspci:pciutils~pciutils~pciutils~:hardware_data 
	ps:procps~procps~procps~:process_data 
	readlink:coreutils~coreutils~coreutils~: 
	sed:sed~sed~sed~:string_replace 
	tr:coreutils~coreutils~coreutils~:character_replace 
	uname:uname~coreutils~coreutils~:kernel_data 
	wc:coreutils~coreutils~coreutils~:word_character_count
	'
	local x_recommends='
	glxinfo:mesa-utils~mesa-demos~glx-utils_(openSUSE_12.3_and_later_Mesa-demo-x)~:-G_glx_info 
	xdpyinfo:X11-utils~xorg-xdpyinfo~xorg-x11-utils~:-G_multi_screen_resolution 
	xprop:X11-utils~xorg-xprop~x11-utils~:-S_desktop_data 
	xrandr:x11-xserver-utils~xrandr~x11-server-utils~:-G_single_screen_resolution
	'
	local recommended_apps='
	dig:dnsutils~dnsutils~bind-utils:-i_first_wlan_ip_default_test
	dmidecode:dmidecode~dmidecode~dmidecode~:-M_if_no_sys_machine_data;_-m_memory 
	file:file~file~file~:-o_unmounted_file_system
	hciconfig:bluez~bluez-utils~bluez-utils~:-n_-i_bluetooth_data
	hddtemp:hddtemp~hddtemp~hddtemp~:-Dx_show_hdd_temp 
	ifconfig:net-tools~net-tools~net-tools~:-i_ip_lan-deprecated
	ip:iproute~iproute2~iproute~:-i_ip_lan
	sensors:lm-sensors~lm_sensors~lm-sensors~:-s_sensors_output
	strings:binutils~~~:-I_sysvinit_version
	lsusb:usbutils~usbutils~usbutils~:-A_usb_audio;-N_usb_networking 
	modinfo:module-init-tools~module-init-tools~module-init-tools~:-Ax,-Nx_module_version 
	runlevel:sysvinit~sysvinit~systemd~:-I_runlevel
	sudo:sudo~sudo~sudo~:-Dx_hddtemp-user;-o_file-user
	uptime:procps~procps~procps~:-I_uptime_(check_which_package_owns_Debian)
	'
	
	local downloaders="
	wget:wget~wget~wget~:-i_wan_ip;-w/-W;-U/-!_[11-15]_(if_supported)
	curl:curl~curl~curl~:-i_wan_ip;-w/-W;-U/-!_[11-15]_(if_supported)
	$downloaders_bsd
	"
	local recommended_dirs='
	/sys/class/dmi/id:-M_system,_motherboard,_bios
	/dev:-l,-u,-o,-p,-P,-D_disk_partition_data
	/dev/disk/by-label:-l,-o,-p,-P_partition_labels
	/dev/disk/by-uuid:-u,-o,-p,-P_partition_uuid
	'
	local recommended_files="
	$FILE_ASOUND_DEVICE:-A_sound_card_data
	$FILE_ASOUND_VERSION:-A_ALSA_data
	$FILE_CPUINFO:-C_cpu_data
	$FILE_LSB_RELEASE:-S_distro_version_data_[deprecated]
	$FILE_MDSTAT:-R_mdraid_data
	$FILE_MEMINFO:-I_memory_data
	$FILE_OS_RELEASE:-S_distro_version_data
	$FILE_PARTITIONS:-p,-P_partitions_data
	$FILE_MODULES:-G_module_data
	$FILE_MOUNTS:-P,-p_partition_advanced_data
	$FILE_DMESG_BOOT:-D,-d_disk_data_[BSD_only]
	$FILE_SCSI:-D_Advanced_hard_disk_data_[used_rarely]
	$FILE_XORG_LOG:-G_graphics_driver_load_status
	"
	
	if [[ -n $COLS_INNER ]];then
		if [[ $COLS_INNER -ge 90 ]];then
			width=${#LINE1} # match width of $LINE1
		elif [[ $COLS_INNER -ge 78 ]];then
			width=$(( $COLS_INNER - 11 ))
		fi
	fi
	
	case $1 in
		downloaders)
			item_list=$downloaders
			item_string='Downloaders'
			item_string=''
			missing_string='downloaders, and their corresponding packages,'
			type='applications'
			;;
		required-dirs)
			item_list=$required_dirs
			item_string='Required file system'
			item_string=''
			missing_string='system directories'
			type='directories'
			;;
		required-apps)
			item_list=$required_apps
			item_string='Required application'
			item_string=''
			missing_string='applications, and their corresponding packages,'
			type='applications'
			;;
		recommended-x-apps)
			item_list=$x_recommends
			item_string='Recommended X application'
			item_string=''
			missing_string='applications, and their corresponding packages,'
			type='applications'
			;;
		recommended-apps)
			item_list=$recommended_apps
			item_string='Recommended application'
			item_string=''
			missing_string='applications, and their corresponding packages,'
			type='applications'
			;;
		system-dirs)
			item_list=$recommended_dirs
			item_string='System directory'
			item_string=''
			missing_string='system directories'
			type='directories'
			;;
		system-files)
			item_list=$recommended_files
			item_string='System file'
			item_string=''
			missing_string='system files'
			type='files'
			;;
	esac
	# great trick from: http://ideatrash.net/2011/01/bash-string-padding-with-sed.html
	# left pad: sed -e :a -e 's/^.\{1,80\}$/& /;ta'
	# right pad: sed -e :a -e 's/^.\{1,80\}$/ &/;ta'
	# center pad: sed -e :a -e 's/^.\{1,80\}$/ & /;ta'
	
	for item in $item_list
	do
		if [[ $( awk -F ":" '{print NF-1}' <<< $item ) -eq 0 ]];then
			application=$item
			package=''
			feature=''
			location=''
		elif [[ $( awk -F ":" '{print NF-1}' <<< $item ) -eq 1 ]];then
			application=$( cut -d ':' -f 1 <<< $item )
			package=''
			feature=$( cut -d ':' -f 2 <<< $item )
			location=''
		else
			application=$( cut -d ':' -f 1 <<< $item )
			package=$( cut -d ':' -f 2 <<< $item )
			location=$( type -p $application )
			if [[ $( awk -F ":" '{print NF-1}' <<< $item ) -eq 2 ]];then
				feature=$( cut -d ':' -f 3 <<< $item )
			else
				feature=''
			fi
		fi
		if [[ -n $feature ]];then
			print_string="$item_string$application (info: $( sed 's/_/ /g' <<< $feature ))"
		else
			print_string="$item_string$application"
		fi
		
		starter="$( sed -e :a -e 's/^.\{1,'$width'\}$/&./;ta' <<< $print_string )"
		if [[ -z $( grep '^/' <<< $application ) && -n $location ]] || [[ -d $application || -f $application ]];then
			if [[ -n $location ]];then
				finisher=" $location"
			else
				finisher=" Present"
			fi
		else
			finisher=" Missing"
			missing_items="$missing_items$separator$application:$package"
			separator=' '
		fi
		
		echo "$starter$finisher"
	done
	echo 
	if [[ -n $missing_items ]];then
		echo "The following $type are missing from your system:"
		for item in $missing_items
		do
			application=$( cut -d ':' -f 1 <<< $item )
			if [[ $type == 'applications' ]];then
				echo
				package=$( cut -d ':' -f 2 <<< $item )
				package_deb=$( cut -d '~' -f 1 <<< $package )
				package_pacman=$( cut -d '~' -f 2 <<< $package )
				package_rpm=$( cut -d '~' -f 3 <<< $package )
				echo "Application: $application"
				print_lines_basic "0" "" "To add to your system, install the proper distribution package for your system:"
				print_lines_basic "0" "" "Debian/Ubuntu:^$package_deb^:: Arch Linux:^$package_pacman^:: Redhat/Fedora/Suse:^$package_rpm"
			elif [[ $type == 'directories' ]];then
				echo "Directory: $application"
			elif [[ $type == 'files' ]];then
				echo "File: $application"
			fi
		done
		if [[ $item_string == 'System directory' ]];then
			print_lines_basic "0" "" "These directories are created by the kernel, so don't worry if they are not present."
		fi
	else
		echo "All the $( cut -d ' ' -f 1 <<< $item_string | sed -e 's/Re/re/' -e 's/Sy/sy/' ) $type are present."
	fi
	echo $Line
}

#### -------------------------------------------------------------------
#### print / output cleaners
#### -------------------------------------------------------------------

# inxi speaks through here. When run by Konversation script alias mode, uses DCOP
# for dcop to work, must use 'say' operator, AND colors must be evaluated by echo -e
# note: dcop does not seem able to handle \n so that's being stripped out and replaced with space.
print_screen_output()
{
	eval $LOGFS
	# the double quotes are needed to avoid losing whitespace in data when certain output types are used
	# trim off whitespace at end
	local print_data="$( echo -e "$1" )" 

	# just using basic debugger stuff so you can tell which thing is printing out the data. This
	# should help debug kde 4 konvi issues when that is released into sid, we'll see. Turning off
	# the redundant debugger output which as far as I can tell does exactly nothing to help debugging.
	if [[ $DEBUG -gt 5 ]];then
		if [[ $KONVI -eq 1 ]];then
			# konvi doesn't seem to like \n characters, it just prints them literally
			# print_data="$( tr '\n' ' ' <<< "$print_data" )"
			# dcop "$DCPORT" "$DCOPOBJ" say "$DCSERVER" "$DCTARGET" "konvi='$KONVI' saying : '$print_data'"
			print_data="KP-$KONVI: $print_data"
		elif [[ $KONVI -eq 2 ]];then
			# echo "konvi='$KONVI' saying : '$print_data'"
			print_data="KP-$KONVI: $print_data"
		else
			# echo "printing out: '$print_data'"
			print_data="P: $print_data"
		fi
	fi
	if [[ $KONVI -eq 1 && $B_DCOP == 'true' ]]; then ## dcop Konversation (<= 1.1 (qt3))
		# konvi doesn't seem to like \n characters, it just prints them literally
		$print_data="$( tr '\n' ' ' <<< "$print_data" )"
		dcop "$DCPORT" "$DCOPOBJ" say "$DCSERVER" "$DCTARGET" "$print_data"
	elif [[ $KONVI -eq 3 && $B_QDBUS == 'true' ]]; then ## dbus Konversation (> 1.2 (qt4))
		qdbus org.kde.konversation /irc say "$DCSERVER" "$DCTARGET" "$print_data"
#	elif [[ $IRC_CLIENT == 'X-Chat' ]]; then
#		qdbus org.xchat.service print "$print_data\n"
	else
		# the -n is needed to avoid double spacing of output in terminal
		echo -ne "$print_data\n"
	fi
	eval $LOGFE
}

## this handles all verbose line construction with indentation/line starter
## args: $1 - null (, actually: " ") or line starter; $2 - line content
create_print_line()
{
	eval $LOGFS
	# convoluted, yes, but it works to trim spaces off end
	local line=${2%${2##*[![:space:]]}}
	printf "${C1}%-${INDENT}s${C2} %s" "$1" "$line${CN}"
	eval $LOGFE
}

# this removes newline and pipes.
# args: $1 - string to clean
remove_erroneous_chars()
{
	eval $LOGFS
	## RS is input record separator
	## gsub is substitute;
	gawk '
	BEGIN {
		RS=""
	}
	{
		gsub(/\n$/,"")         ## (newline; end of string) with (nothing)
		gsub(/\n/," ");        ## (newline) with (space)
		gsub(/^ *| *$/, "")    ## (pipe char) with (nothing)
		gsub(/  +/, " ")       ## ( +) with (space)
		gsub(/ [ ]+/, " ")     ## ([ ]+) with (space)
		gsub(/^ +| +$/, "")    ## (pipe char) with (nothing)
		printf $0
	}' "$1"      ## prints (returns) cleaned input
	eval $LOGFE
}

#### -------------------------------------------------------------------
#### parameter handling, print usage functions.
#### -------------------------------------------------------------------

# Get the parameters. Note: standard options should be lower case, advanced or testing, upper
# args: $1 - full script startup args: $@
get_parameters()
{
	eval $LOGFS
	local opt='' downloader_test='' debug_data_type='' weather_flag='wW:' 
	local use_short='true' # this is needed to trigger short output, every v/d/F/line trigger sets this false

	# if distro maintainers don't want the weather feature disable it
	if [[ $B_ALLOW_WEATHER == 'false' ]];then
		weather_flag=''
	fi
	if [[ $1 == '--version' ]];then
		print_version_info
		exit 0
	elif [[ $1 == '--help' ]];then
		show_options
		exit 0
	elif [[ $1 == '--recommends' ]];then
		check_recommends_user_output
		exit 0
	# the short form only runs if no args output args are used
	# no need to run through these if there are no args
	# reserved for future use: -g for extra Graphics; -m for extra Machine; -d for extra Disk
	elif [[ -n $1 ]];then
		while getopts AbBc:CdDfFGhHiIlmMnNopPrRsSt:uUv:V${weather_flag}xy:zZ%@:!: opt
		do
			case $opt in
			A)	B_SHOW_AUDIO='true'
				use_short='false'
				;;
			b)	use_short='false'
				B_SHOW_BASIC_CPU='true'
				B_SHOW_BASIC_RAID='true'
				B_SHOW_DISK_TOTAL='true'
				B_SHOW_GRAPHICS='true'
				B_SHOW_INFO='true'
				B_SHOW_MACHINE='true'
				B_SHOW_BATTERY='true'
				B_SHOW_NETWORK='true'
				B_SHOW_SYSTEM='true'
				;;
			B)	B_SHOW_BATTERY_FORCED='true'
				B_SHOW_BATTERY='true'
				use_short='false'
				;;
			c)	if [[ $OPTARG =~ ^[0-9][0-9]?$ ]];then
					case $OPTARG in
						99)
							B_RUN_COLOR_SELECTOR='true'
							COLOR_SELECTION='global'
							;;
						98)
							B_RUN_COLOR_SELECTOR='true'
							COLOR_SELECTION='irc-console'
							;;
						97)
							B_RUN_COLOR_SELECTOR='true'
							COLOR_SELECTION='irc-virtual-terminal'
							;;
						96)
							B_RUN_COLOR_SELECTOR='true'
							COLOR_SELECTION='irc'
							;;
						95)
							B_RUN_COLOR_SELECTOR='true'
							COLOR_SELECTION='virtual-terminal'
							;;
						94)
							B_RUN_COLOR_SELECTOR='true'
							COLOR_SELECTION='console'
							;;
						*)	
							B_COLOR_SCHEME_SET='true'
							## note: not sure about this, you'd think user values should be overridden, but
							## we'll leave this for now
							if [[ -z $COLOR_SCHEME ]];then
								set_color_scheme "$OPTARG"
							fi
							;;
					esac
				else
					error_handler 3 "$OPTARG"
				fi
				;;
			C)	B_SHOW_CPU='true'
				use_short='false'
				;;
			d)	B_SHOW_DISK='true'
				B_SHOW_FULL_OPTICAL='true'
				use_short='false'
				# error_handler 20 "-d has been replaced by -b"
				;;
			D)	B_SHOW_DISK='true'
				use_short='false'
				;;
			f)	B_SHOW_CPU='true'
				B_CPU_FLAGS_FULL='true'
				use_short='false'
				;;
			F)	# B_EXTRA_DATA='true'
				B_SHOW_ADVANCED_NETWORK='true'
				B_SHOW_AUDIO='true'
				# B_SHOW_BASIC_OPTICAL='true'
				B_SHOW_CPU='true'
				B_SHOW_DISK='true'
				B_SHOW_GRAPHICS='true'
				B_SHOW_INFO='true'
				B_SHOW_MACHINE='true'
				B_SHOW_BATTERY='true'
				B_SHOW_NETWORK='true'
				B_SHOW_PARTITIONS='true'
				B_SHOW_RAID='true'
				B_SHOW_SENSORS='true'
				B_SHOW_SYSTEM='true'
				use_short='false'
				;;
			G)	B_SHOW_GRAPHICS='true'
				use_short='false'
				;;
			i)	B_SHOW_IP='true'
				B_SHOW_NETWORK='true'
				B_SHOW_ADVANCED_NETWORK='true'
				use_short='false'
				;;
			I)	B_SHOW_INFO='true'
				use_short='false'
				;;
			l)	B_SHOW_LABELS='true'
				B_SHOW_PARTITIONS='true'
				use_short='false'
				;;
			m)	B_SHOW_MEMORY='true'
				use_short='false'
				;;
			M)	B_SHOW_MACHINE='true'
				use_short='false'
				;;
			n)	B_SHOW_ADVANCED_NETWORK='true'
				B_SHOW_NETWORK='true'
				use_short='false'
				;;
			N)	B_SHOW_NETWORK='true'
				use_short='false'
				;;
			o)	B_SHOW_UNMOUNTED_PARTITIONS='true'
				use_short='false'
				;;
			p)	B_SHOW_PARTITIONS_FULL='true'
				B_SHOW_PARTITIONS='true'
				use_short='false'
				;;
			P)	B_SHOW_PARTITIONS='true'
				use_short='false'
				;;
			r)	B_SHOW_REPOS='true'
				use_short='false'
				;;
			R)	B_SHOW_RAID='true'
				# it turns out only users with mdraid software installed will have raid,
				# so unless -R is explicitly called, blank -b/-F/-v6 and less output will not show
				# error if file is missing.
				B_SHOW_RAID_R='true'
				use_short='false'
				;;
			s)	B_SHOW_SENSORS='true'
				use_short='false'
				;;
			S)	B_SHOW_SYSTEM='true'
				use_short='false'
				;;
			t)	if [[ $OPTARG =~ ^(c|m|cm|mc)([1-9]|1[0-9]|20)?$ ]];then
					use_short='false'
					if [[ -n $( grep -E '[0-9]+' <<< $OPTARG ) ]];then
						PS_COUNT=$( sed 's/[^0-9]//g' <<< $OPTARG )
					fi
					if [[ -n $( grep 'c' <<< $OPTARG ) ]];then
						B_SHOW_PS_CPU_DATA='true'
					fi
					if [[ -n $( grep 'm' <<< $OPTARG ) ]];then
						B_SHOW_PS_MEM_DATA='true'
					fi
				else
					error_handler 13 "$OPTARG"
				fi
				;;
			u)	B_SHOW_UUIDS='true'
				B_SHOW_PARTITIONS='true'
				use_short='false'
				;;
			v)	if [[ $OPTARG =~ ^[0-9][0-9]?$ && $OPTARG -le $VERBOSITY_LEVELS ]];then
					if [[ $OPTARG -ge 1 ]];then
						use_short='false'
						B_SHOW_BASIC_CPU='true'
						B_SHOW_DISK_TOTAL='true'
						B_SHOW_GRAPHICS='true'
						B_SHOW_INFO='true'
						B_SHOW_SYSTEM='true'
					fi
					if [[ $OPTARG -ge 2 ]];then
						B_SHOW_BASIC_DISK='true'
						B_SHOW_BASIC_RAID='true'
						B_SHOW_BATTERY='true'
						B_SHOW_MACHINE='true'
						B_SHOW_NETWORK='true'
					fi
					if [[ $OPTARG -ge 3 ]];then
						B_SHOW_ADVANCED_NETWORK='true'
						B_SHOW_CPU='true'
						B_EXTRA_DATA='true'
					fi
					if [[ $OPTARG -ge 4 ]];then
						B_SHOW_DISK='true'
						B_SHOW_PARTITIONS='true'
					fi
					if [[ $OPTARG -ge 5 ]];then
						B_SHOW_AUDIO='true'
						B_SHOW_BASIC_OPTICAL='true'
						B_SHOW_MEMORY='true'
						B_SHOW_SENSORS='true'
						B_SHOW_LABELS='true'
						B_SHOW_UUIDS='true'
						B_SHOW_RAID='true'
					fi
					if [[ $OPTARG -ge 6 ]];then
						B_SHOW_FULL_OPTICAL='true'
						B_SHOW_PARTITIONS_FULL='true'
						B_SHOW_UNMOUNTED_PARTITIONS='true'
						B_EXTRA_EXTRA_DATA='true'
					fi
					if [[ $OPTARG -ge 7 ]];then
						B_EXTRA_EXTRA_EXTRA_DATA='true'
						B_SHOW_IP='true'
						B_SHOW_RAID_R='true'
					fi
				else
					error_handler 4 "$OPTARG"
				fi
				;;
			U)	if [[ $B_ALLOW_UPDATE == 'true' ]];then
					script_self_updater "$SELF_DOWNLOAD" 'source server' "$opt"
				else
					error_handler 17 "-$opt"
				fi
				;;
			V)	print_version_info
				exit 0
				;;
			w)	B_SHOW_WEATHER=true
				use_short='false'
				;;
			W)	ALTERNATE_WEATHER_LOCATION=$( sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//'  <<< $OPTARG )
				if [[ -n $( grep -Esi '([^,]+,.+|[0-9-]+)' <<< $ALTERNATE_WEATHER_LOCATION ) ]];then
					B_SHOW_WEATHER=true
					use_short='false'
				else
					error_handler 18 "-$opt: '$OPTARG'" "city,state OR latitude,longitude OR postal/zip code."
				fi
				;;
			# this will trigger either with x, xx, xxx or with Fx but not with xF
			x)	if [[ $B_EXTRA_EXTRA_DATA == 'true' ]];then
					B_EXTRA_EXTRA_EXTRA_DATA='true'
				elif [[ $B_EXTRA_DATA == 'true' ]];then
					B_EXTRA_EXTRA_DATA='true'
				else
					B_EXTRA_DATA='true'
				fi
				;;
			y)	if [[ -z ${OPTARG//[0-9]/} && $OPTARG -ge 80 ]];then
					set_display_width "$OPTARG"
				else
					error_handler 21 "$OPTARG"
				fi
				;;
			z)	B_OUTPUT_FILTER='true'
				;;
			Z)	B_OVERRIDE_FILTER='true'
				;;
			h)	show_options
				exit 0
				;;
			H)	show_options 'full'
				exit 0
				;;
			## debuggers and testing tools
			%)	B_HANDLE_CORRUPT_DATA='true'
				;;
			@)	if [[ -n $( grep -E "^([1-9]|1[0-5])$" <<< $OPTARG ) ]];then
					DEBUG=$OPTARG
					if [[ $B_EXTRA_EXTRA_DATA == 'true' ]];then
						B_UPLOAD_DEBUG_DATA='true'
					fi
					exec 2>&1
					# switch on logging only for -@ 8-10
					case $OPTARG in
						8|9|10)
							if [[ $OPTARG -eq 10 ]];then
								B_LOG_COLORS='true'
							elif [[ $OPTARG -eq 9 ]];then		
								B_LOG_FULL_DATA='true'
							fi
							B_USE_LOGGING='true'
							# pack the logging data for evals function start/end
							LOGFS=$LOGFS_STRING
							LOGFE=$LOGFE_STRING
							create_rotate_logfiles # create/rotate logfiles before we do anything else
							;;
						11|12|13|14|15)
							case $OPTARG in
								11)
									debug_data_type='sys'
									;;
								12)
									debug_data_type='xorg'
									;;
								13)
									debug_data_type='disk'
									;;
								14)
									debug_data_type='all'
									;;
								15)
									debug_data_type='all'
									B_DEBUG_I='true'
									;;
							esac
							initialize_data
							debug_data_collector $debug_data_type
							;;
					esac
				else
					error_handler 9 "$OPTARG"
				fi
				;;
			!)	# test for various supported methods
				case $OPTARG in
					1)	B_TESTING_1='true'
						;;
					2)	B_TESTING_2='true'
						;;
					3)	B_TESTING_1='true'
						B_TESTING_2='true'
						;;
					1[0-6]|http*)
						if [[ $B_ALLOW_UPDATE == 'true' ]];then
							case $OPTARG in
								10)
									script_self_updater "$SELF_DOWNLOAD_DEV" 'dev server' "$opt $OPTARG"
									;;
								11)
									script_self_updater "$SELF_DOWNLOAD_BRANCH_1" 'branch one server' "$opt $OPTARG"
									;;
								12)
									script_self_updater "$SELF_DOWNLOAD_BRANCH_2" 'branch two server' "$opt $OPTARG"
									;;
								13)
									script_self_updater "$SELF_DOWNLOAD_BRANCH_3" 'branch three server' "$opt $OPTARG"
									;;
								14)
									script_self_updater "$SELF_DOWNLOAD_BRANCH_4" 'branch four server' "$opt $OPTARG"
									;;
								15)
									script_self_updater "$SELF_DOWNLOAD_BRANCH_BSD" 'branch bsd server' "$opt $OPTARG"
									;;
								16)
									script_self_updater "$SELF_DOWNLOAD_BRANCH_GNUBSD" 'branch gnubsd server' "$opt $OPTARG"
									;;
								http*)
									script_self_updater "$OPTARG" 'alt server' "$opt <http...>"
									;;
							esac
						else
							error_handler 17 "-$opt $OPTARG"
						fi
						;;
					30)
						B_IRC='false'
						;;
					31)
						B_SHOW_HOST='false'
						;;
					32)
						B_SHOW_HOST='true'
						;;
					33)
						B_FORCE_DMIDECODE='true'
						;;
					34)
						NO_SSL_OPT=$NO_SSL
						;;
					40*)
						DISPLAY=${OPTARG/40/}
						if [[ $DISPLAY == '' ]];then
							DISPLAY=':0'
						fi
						DISPLAY_OPT="-display $DISPLAY"
						B_SHOW_DISPLAY_DATA='true'
						B_RUNNING_IN_DISPLAY='true'
						;;
					ftp*)
						ALTERNATE_FTP="$OPTARG"
						;;
					# for weather function, allows user to set an alternate weather location
					location=*)
						error_handler 19 "-$opt location=" "-W"
						;;
					*)	error_handler 11 "$OPTARG"
						;;
				esac
				;;
			*)	error_handler 7 "$1"
				;;
			esac
		done
	fi
	## this must occur here so you can use the debugging flag to show errors
	## Reroute all error messages to the bitbucket (if not debugging)
	if [[ $DEBUG -eq 0 ]];then
		exec 2>/dev/null
	fi
	#((DEBUG)) && exec 2>&1 # This is for debugging konversation

	# after all the args have been processed, if no long output args used, run short output
	if [[ $use_short == 'true' ]];then
		B_SHOW_SHORT_OUTPUT='true'
	fi
	# just in case someone insists on using -zZ
	if [[ $B_OVERRIDE_FILTER == 'true' ]];then
		B_OUTPUT_FILTER='false'
	fi
	# change basic to full if user requested it or if arg overrides it
	if [[ $B_SHOW_RAID == 'true' && $B_SHOW_BASIC_RAID == 'true' ]];then
		B_SHOW_BASIC_RAID='false'
	fi
	
	
	eval $LOGFE
}

## print out help menu, not including Testing or Debugger stuff because it's not needed
show_options()
{
	local color_scheme_count=$(( ${#A_COLOR_SCHEMES[@]} - 1 ))
	local partition_string='partition' partition_string_u='Partition'
	
	if [[ $B_IRC == 'true' ]];then
		print_screen_output "Sorry, you can't run the help option in an IRC client."
		exit 1
	fi
	if [[ -n $BSD_TYPE ]];then
		partition_string='slice'
		partition_string_u='Slice'
	fi
	# print_lines_basic "0" "" ""
	# print_lines_basic "1" "" ""
	# print_lines_basic "2" "" ""
	# print_screen_output " "
	print_lines_basic "0" "" "$SELF_NAME supports the following options. You can combine them, or list them one by one. Examples: $SELF_NAME^-v4^-c6 OR $SELF_NAME^-bDc^6. If you start $SELF_NAME with no arguments, it will show the short form."
	print_screen_output " "
	print_lines_basic "0" "" "The following options if used without -F, -b, or -v will show just option line(s): A, B, C, D, G, I, M, N, P, R, S, f, i, m, n, o, p, l, u, r, s, t - you can use these alone or together to show just the line(s) you want to see. If you use them with -v^[level], -b or -F, it will show the full output for that line along with the output for the chosen verbosity level."
	print_screen_output "- - - - - - - - - - - - - - - - - - - - - - - - - - - - -"
	print_screen_output "Output Control Options:"
	print_lines_basic "1" "-A" "Audio/sound card information."
	print_lines_basic "1" "-b" "Basic output, short form. Like $SELF_NAME^-v^2, only minus hard disk names ."
	print_lines_basic "1" "-B" "Battery info, shows charge, condition, plus extra information (if battery present)."
	print_lines_basic "1" "-c" "Color schemes. Scheme number is required. Color selectors run a color selector option prior to $SELF_NAME starting which lets you set the config file value for the selection."
	print_lines_basic "1" "" "Supported color schemes: 0-$color_scheme_count Example:^$SELF_NAME^-c^11"
	print_lines_basic "1" "" "Color selectors for each type display (NOTE: irc and global only show safe color set):"
# 	print_screen_output "    Supported color schemes: 0-$color_scheme_count Example: $SELF_NAME -c 11"
# 	print_screen_output "    Color selectors for each type display (NOTE: irc and global only show safe color set):"
	print_lines_basic "2" "94" "Console, out of X"
	print_lines_basic "2" "95" "Terminal, running in X - like xTerm"
	print_lines_basic "2" "96" "Gui IRC, running in X - like Xchat, Quassel, Konversation etc."
	print_lines_basic "2" "97" "Console IRC running in X - like irssi in xTerm"
	print_lines_basic "2" "98" "Console IRC not in  X"
	print_lines_basic "2" "99" "Global - Overrides/removes all settings. Setting specific removes global."
	print_lines_basic "1" "-C" "CPU output, including per CPU clockspeed and max CPU speed (if available)."
	print_lines_basic "1" "-d" "Optical drive data (and floppy disks, if present). Same as -Dd. See also -x and -xx."
	print_lines_basic "1" "-D" "Full hard Disk info, not only model, ie: /dev/sda ST380817AS 80.0GB. See also -x and -xx. Disk total used percentage includes swap partition size(s)."
	print_lines_basic "1" "-f" "All cpu flags, triggers -C. Not shown with -F to avoid spamming. ARM cpus show 'features'."
	print_lines_basic "1" "-F" "Full output for $SELF_NAME. Includes all Upper Case line letters, plus -s and -n. Does not show extra verbose options like -d -f -l -m -o -p -r -t -u -x"
	print_lines_basic "1" "-G" "Graphic card information (card, display server type/version, resolution, renderer, OpenGL version)."
	print_lines_basic "1" "-i" "Wan IP address, and shows local interfaces (requires ifconfig 
	network tool). Same as -Nni. Not shown with -F for user security reasons, you shouldn't paste your local/wan IP."
	print_lines_basic "1" "-I" "Information: processes, uptime, memory, irc client (or shell type), $SELF_NAME version."
	print_lines_basic "1" "-l" "$partition_string_u labels. Default: short $partition_string -P. For full -p output, use: -pl (or -plu)."
	print_lines_basic "1" "-m" "Memory (RAM) data. Physical system memory array(s), capacity, how many devices (slots) supported, and individual memory devices (sticks of memory etc). For devices, shows device locator, size, speed, type (like: DDR3). If neither -I nor -tm are selected, also shows ram used/total. Also see -x, -xx, -xxx"
	print_lines_basic "1" "-M" "Machine data. Device type (desktop, server, laptop, VM etc.), Motherboard, Bios, and if present, System Builder (Like Lenovo). Shows UEFI/BIOS/UEFI [Legacy}. Older systems/kernels without the required /sys data can use dmidecode instead, run as root. Dmidecode can be forced with -! 33"
	print_lines_basic "1" "-n" "Advanced Network card information. Same as -Nn. Shows interface, speed, mac id, state, etc."
	print_lines_basic "1" "-N" "Network card information. With -x, shows PCI BusID, Port number."
	print_lines_basic "1" "-o" "Unmounted $partition_string information (includes UUID and LABEL if available). Shows file system type if you have file installed, if you are root OR if you have added to /etc/sudoers (sudo v. 1.7 or newer) Example:^<username>^ALL^=^NOPASSWD:^/usr/bin/file^"
	print_lines_basic "1" "-p" "Full $partition_string information (-P plus all other detected ${partition_string}s)."
	print_lines_basic "1" "-P" "Basic $partition_string information (shows what -v^4 would show, but without extra data). Shows, if detected: / /boot /home /opt /tmp /usr /var /var/log /var/tmp . Use -p to see all mounted ${partition_string}s."
	print_lines_basic "1" "-r" "Distro repository data. Supported repo types: APK; APT; PACMAN; PISI; PORTAGE; PORTS (BSDs); SLACKPKG; URPMQ; YUM; ZYPP."
	print_lines_basic "1" "-R" "RAID data. Shows RAID devices, states, levels, and components, and extra data with -x/-xx. md-raid: If device is resyncing, shows resync progress line as well."
	print_lines_basic "1" "-s" "Sensors output (if sensors installed/configured): mobo/cpu/gpu temp; detected fan speeds. Gpu temp only for Fglrx/Nvidia drivers. Nvidia shows screen number for > 1 screens."
	print_lines_basic "1" "-S" "System information: host name, kernel, desktop environment (if in X), distro"
	print_lines_basic "1" "-t" "Processes. Requires extra options: c^(cpu) m^(memory) cm^(cpu+memory). If followed by numbers 1-20, shows that number of processes for each type (default:^$PS_COUNT; if in irc, max:^5): -t^cm10"
	print_lines_basic "1" "" "Make sure to have no space between letters and numbers (-t^cm10 - right, -t^cm^10 - wrong)."
	print_lines_basic "1" "-u" "$partition_string_u UUIDs. Default: short $partition_string -P. For full -p output, use: -pu (or -plu)."
	print_lines_basic "1" "-v" "Script verbosity levels. Verbosity level number is required. Should not be used with -b or -F"
	print_lines_basic "1" "" "Supported levels: 0-$VERBOSITY_LEVELS Example: $SELF_NAME^-v^4"
	print_lines_basic "2" "0" "Short output, same as: $SELF_NAME"
	print_lines_basic "2" "1" "Basic verbose, -S + basic CPU + -G + basic Disk + -I."
	print_lines_basic "2" "2" "Networking card (-N), Machine (-M) data, if present, Battery (-B), basic hard disk data (names only), and, if present, basic raid (devices only, and if inactive, notes that). similar to: $SELF_NAME^-b"
	print_lines_basic "2" "3" "Advanced CPU (-C), battery, network (-n) data, and switches on -x advanced data option."
	print_lines_basic "2" "4" "$partition_string_u size/filled data (-P) for (if present): /, /home, /var/, /boot. Shows full disk data (-D)."
	print_lines_basic "2" "5" "Audio card (-A); sensors^(-s), memory/ram^(-m), $partition_string label^(-l) and UUID^(-u), short form of optical drives, standard raid data (-R)."
	print_lines_basic "2" "6" "Full $partition_string (-p), unmounted $partition_string (-o), optical drive (-d), full raid; triggers -xx."
	print_lines_basic "2" "7" "Network IP data (-i); triggers -xxx."
	
	# if distro maintainers don't want the weather feature disable it
	if [[ $B_ALLOW_WEATHER == 'true' ]];then
		print_lines_basic "1" "-w" "Local weather data/time. To check an alternate location, see: -W^<location>. For extra weather data options see -x, -xx, and -xxx."
		print_lines_basic "1" "-W" "<location> Supported options for <location>: postal code; city, state/country; latitude, longitude. Only use if you want the weather somewhere other than the machine running $SELF_NAME. Use only ascii characters, replace spaces in city/state/country names with '+'. Example:^$SELF_NAME^-W^new+york,ny"
	fi
	print_lines_basic "1" "-x" "Adds the following extra data (only works with verbose or line output, not short form):"
	print_lines_basic "2" "-B" "Vendor/model, status (if available)"
	print_lines_basic "2" "-C" "CPU Flags, Bogomips on Cpu;CPU microarchitecture / revision if found, like: (Sandy Bridge rev.2)"
	print_lines_basic "2" "-d" "Extra optical drive data; adds rev version to optical drive."
	print_lines_basic "2" "-D" "Hdd temp with disk data if you have hddtemp installed, if you are root OR if you have added to /etc/sudoers (sudo v. 1.7 or newer) Example:^<username>^ALL^=^NOPASSWD:^/usr/sbin/hddtemp"
	print_lines_basic "2" "-G" "Direct rendering status for Graphics (in X)."
	print_lines_basic "2" "-G" "(for single gpu, nvidia driver) screen number gpu is running on."
	print_lines_basic "2" "-i" "For IPv6, show additional IP v6 scope addresses: Global, Site, Temporary, Unknown."
	print_lines_basic "2" "-I" "System GCC, default. With -xx, also show other installed GCC versions. If running in console, not in IRC client, shows shell version number, if detected. Init/RC Type and runlevel (if available)."
	print_lines_basic "2" "-m" "Part number; Max memory module size (if available)."
	print_lines_basic "2" "-N -A" "Version/port(s)/driver version (if available) for Network/Audio;"
	print_lines_basic "2" "-N -A -G" "Network, audio, graphics, shows PCI Bus ID/Usb ID number of card."
	print_lines_basic "2" "-R" "md-raid: Shows component raid id. Adds second RAID Info line: raid level; report on drives (like 5/5); blocks; chunk size; bitmap (if present). Resync line, shows blocks synced/total blocks. zfs-raid:	Shows raid array full size; available size; portion allocated to RAID"
	print_lines_basic "2" "-S" "Desktop toolkit if available (GNOME/XFCE/KDE only); Kernel gcc version"
	print_lines_basic "2" "-t" "Memory use output to cpu (-xt c), and cpu use to memory (-xt m)."
	if [[ $B_ALLOW_WEATHER == 'true' ]];then
		print_lines_basic "2" "-w -W" "Wind speed and time zone (-w only)."
	fi
	print_lines_basic "1" "-xx" "Show extra, extra data (only works with verbose or line output, not short form):"
	print_lines_basic "2" "-A" "Chip vendor:product ID for each audio device."
	print_lines_basic "2" "-B" "serial number, voltage (if available)."
	print_lines_basic "2" "-C" "Minimum CPU speed, if available."
	print_lines_basic "2" "-D" "Disk serial number; Firmware rev. if available."
	print_lines_basic "2" "-G" "Chip vendor:product ID for each video card; (mir/wayland only) compositor (alpha test); OpenGL compatibility version, if free drivers and available."
	print_lines_basic "2" "-I" "Other detected installed gcc versions (if present). System default runlevel. Adds parent program (or tty) for shell info if not in IRC (like Konsole or Gterm). Adds Init/RC (if found) version number."
	print_lines_basic "2" "-m" "Manufacturer, Serial Number, single/double bank (if found)."
	print_lines_basic "2" "-M" "Chassis information, bios rom size (dmidecode only), if data for either is available."
	print_lines_basic "2" "-N" "Chip vendor:product ID for each nic."
	print_lines_basic "2" "-R" "md-raid: Superblock (if present); algorythm, U data. Adds system info line (kernel support,read ahead, raid events). If present, adds unused device line. Resync line, shows progress bar."
	print_lines_basic "2" "-S" "Display manager (dm) in desktop output, if in X (like kdm, gdm3, lightdm)."
	if [[ $B_ALLOW_WEATHER == 'true' ]];then
		print_lines_basic "2" "-w -W" "Humidity, barometric pressure."
	fi
	print_lines_basic "2" "-@ 11-14" "Automatically uploads debugger data tar.gz file to ftp.techpatterns.com. EG: $SELF_NAME^-xx@14"
	print_lines_basic "1" "-xxx" "Show extra, extra, extra data (only works with verbose or line output, not short form):"
	print_lines_basic "2" "-B" "chemistry, cycles, location (if available)."
	print_lines_basic "2" "-m" "Width of memory bus, data and total (if present and greater than data); Detail, if present, for Type; module voltage, if available."
	print_lines_basic "2" "-S" "Panel/shell information in desktop output, if in X (like gnome-shell, cinnamon, mate-panel)."
	if [[ $B_ALLOW_WEATHER == 'true' ]];then
		print_lines_basic "2" "-w -W" "Location (uses -z/irc filter), weather observation time, wind chill, heat index, dew point (shows extra lines for data where relevant)."
	fi
	print_lines_basic "1" "-y" "Required extra option: integer, 80 or greater. Set the output line width max. Overrides IRC/Terminal settings or actual widths. If used with -h, put -y option first. Example:^inxi^-y^130"
	print_lines_basic "1" "-z" "Security filters for IP/Mac addresses, location, user home directory name. Default on for irc clients."
	print_lines_basic "1" "-Z" "Absolute override for output filters. Useful for debugging networking issues in irc for example."
	print_screen_output " "
	print_screen_output "Additional Options:"
	print_lines_basic "4" "-h --help" "This help menu."
	print_lines_basic "4" "-H" "This help menu, plus developer options. Do not use dev options in normal operation!"
	print_lines_basic "4" "--recommends" "Checks $SELF_NAME application dependencies + recommends, and directories, then shows what package(s) you need to install to add support for that feature. "
	if [[ $B_ALLOW_UPDATE == 'true' ]];then
		print_lines_basic "4" "-U" "Auto-update script. Will also install/update man page. Note: if you installed as root, you must be root to update, otherwise user is fine. Man page installs require root user mode."
	fi
	print_lines_basic "4" "-V --version" "$SELF_NAME version information. Prints information then exits."
	print_screen_output " "
	print_screen_output "Debugging Options:"
	print_lines_basic "1" "-%" "Overrides defective or corrupted data."
	print_lines_basic "1" "-@" "Triggers debugger output. Requires debugging level 1-14 (8-10 - logging of data). Less than 8 just triggers $SELF_NAME debugger output on screen."
	print_lines_basic "2" "1-7" "On screen debugger output"
	print_lines_basic "2" "8" "Basic logging"
	print_lines_basic "2" "9" "Full file/sys info logging"
	print_lines_basic "2" "10" "Color logging."
	print_lines_basic "1" "" "The following create a tar.gz file of system data, plus collecting the inxi output to file. To automatically upload debugger data tar.gz file to ftp.techpatterns.com: inxi^-xx@^<11-14>"
	print_lines_basic "1" "" "For alternate ftp upload locations: Example:^inxi^-!^ftp.yourserver.com/incoming^-xx@^14"
	print_lines_basic "2" "11" "With data file of tree traverse read of /sys."
	print_lines_basic "2" "12" "With xorg conf and log data, xrandr, xprop, xdpyinfo, glxinfo etc."
	print_lines_basic "2" "13" "With data from dev, disks, ${partition_string}s, etc., plus /sys tree traverse data file."
	print_lines_basic "2" "14" "Everything, full data collection."
	print_screen_output " "
	print_screen_output "Advanced Options:"
	print_lines_basic "1" "-! 31" "Turns off hostname in output. Useful if showing output from servers etc."
	print_lines_basic "1" "-! 32" "Turns on hostname in output. Overrides global B_SHOW_HOST='false'"
	print_lines_basic "1" "-! 33" "Forces use of dmidecode data instead of /sys where relevant (-M)."
	print_lines_basic "1" "-! 34" "Skips SSL certificate checks for all downloader activies (wget/fetch/curl only). Must go before other options."
	print_lines_basic "1" "-! 40" "Will try to get display data out of X. Default gets it from display :0. If you use this format: -! 40:1 it would get it from display 1 instead, or any display you specify as long as there is no space between -! 40 and the :[display-number]."
	
	if [[ $1 == 'full' ]];then
		print_screen_output " "
		print_screen_output "Developer and Testing Options (Advanced):"
		print_lines_basic "1" "-! 1" "Sets testing flag B_TESTING_1='true' to trigger testing condition 1."
		print_lines_basic "1" "-! 2" "Sets testing flag B_TESTING_2='true' to trigger testing condition 2."
		print_lines_basic "1" "-! 3" "Sets flags B_TESTING_1='true' and B_TESTING_2='true'."
		if [[ $B_ALLOW_UPDATE == 'true' ]];then
			print_lines_basic "1" "-! 10" "Triggers an update from the primary dev download server instead of source server."
			print_lines_basic "1" "-! 11" "Triggers an update from source branch one - if present, of course."
			print_lines_basic "1" "-! 12" "Triggers an update from source branch two - if present, of course."
			print_lines_basic "1" "-! 13" "Triggers an update from source branch three - if present, of course."
			print_lines_basic "1" "-! 14" "Triggers an update from source branch four - if present, of course."
			print_lines_basic "1" "-! 15" "Triggers an update from source branch BSD - if present, of course."
			print_lines_basic "1" "-! 16" "Triggers an update from source branch GNUBSD - if present, of course."
			print_lines_basic "1" "-! " "<http://......> Triggers an update from whatever server you list."
			print_lines_basic "1" "" "Example: inxi^-!^http://yourserver.com/testing/inxi"
		fi
		print_lines_basic "1" "-! " "<ftp.......> Changes debugging data ftp upload location to whatever you enter here. Only used together with -xx@^11-14, and must be used in front of that."
		print_lines_basic "1" "" "Example: inxi^-!^ftp.yourserver.com/incoming^-xx@^14"
	fi
	print_screen_output " "
}

# uses $TERM_COLUMNS to set width using $COLS_MAX as max width
# IMPORTANT: minimize use of subshells here or the output is too slow
# IMPORTANT: each text chunk must be a continuous line, no line breaks. For anyone who uses a 
# code editor that can't do visual (not hard coded) line wrapping, upgrade to one that can.
# args: $1 - 0 1 2 3 4 for indentation level; $2 -line starter, like -m; $3 - content of block.
print_lines_basic()
{
	local line_width=$COLS_MAX
	local print_string='' indent_inner='' indent_full='' indent_x='' 
	local indent_working='' indent_working_full=''
	local line_starter='' line_1_starter='' line_x_starter='' 
	# note: to create a padded string below
	local fake_string=' ' temp_count='' line_count='' spacer=''
	local indent_main=6 indent_x='' b_indent_x='true' 
	
	case $1 in
		# for no options, start at left edge
		0)	indent_full=0
			line_1_starter=''
			line_x_starter=''
			b_indent_x='false'
			;;
		1)	indent_full=$indent_main
			temp_count=${#2}
			if [[ $temp_count -le $indent_full ]];then
				indent_working=$indent_full
			else
				indent_working=$temp_count #$(( $temp_count + 1 ))
			fi
			line_1_starter="$( sed -e :a -e "s/^.\{1,$indent_working\}$/& /;ta" <<< $2 )"
			;;
		# first left pad 2 and 3, then right pad them
		2)	indent_full=$(( $indent_main + 6 ))
			indent_inner=3
			temp_count=${#2}
			if [[ $temp_count -le $indent_inner ]];then
				indent_working=$indent_inner
				#indent_working_full=$indent_full
			else
				indent_working=$(( $temp_count + 1 ))
				#indent_working_full=$(( $indent_full - $indent_inner - 1 ))
			fi
			line_1_starter="$( sed -e :a -e "s/^.\{1,$indent_working\}$/& /;ta" <<< $2 )"
			line_1_starter="$( sed -e :a -e "s/^.\{1,$indent_full\}$/ &/;ta" <<< "$line_1_starter" )"
			;;
		3)	indent_full=$(( $indent_main + 8 ))
			indent_inner=3
			temp_count=${#2}
			if [[ $temp_count -le $indent_inner ]];then
				indent_working=$indent_inner
			else
				indent_working=$(( $temp_count + 1 ))
			fi
			line_1_starter="$( sed -e :a -e "s/^.\{1,$indent_working\}$/& /;ta" <<< $2 )"
			line_1_starter="$( sed -e :a -e "s/^.\{1,$indent_full\}$/ &/;ta" <<< "$line_1_starter" )"
			;;
		# for long options
		4)	indent_full=$(( $indent_main + 8 ))
			temp_count=${#2}
			if [[ $temp_count -lt $indent_full ]];then
				indent_working=$indent_full
			else
				indent_working=$temp_count #$(( $temp_count + 1 ))
			fi
			line_1_starter="$( sed -e :a -e "s/^.\{1,$indent_working\}$/& /;ta" <<< $2 )"
			;;
	esac
	
	if [[ $b_indent_x == 'true' ]];then
		indent_x=$(( $indent_full + 1 ))
		line_x_starter="$(printf "%${indent_x}s" '')"
	fi
	
	line_count=$(( $line_width - $indent_full ))
	
	# bash loop is slow, only run this if required
	if [[ ${#3} -gt $line_count ]];then
		for word in $3
		do
			temp_string="$print_string$spacer$word"
			spacer=' '
			if [[ ${#temp_string} -lt $line_count ]];then
				print_string=$temp_string # lose any white space start/end
				# echo -n $(( $line_width - $indent_full ))
			else
				if [[ -n $line_1_starter ]];then
					line_starter="$line_1_starter"
					line_1_starter=''
				else
					line_starter="$line_x_starter"
				fi
				# clean up forced connections, ie, stuff we don't want wrapping
				print_string=${print_string//\^/ }
				print_screen_output "$line_starter$print_string"
				print_string="$word$spacer" # needed to handle second word on new line
				temp_string=''
				spacer=''
			fi
		done
	else
		# echo no loop
		print_string=$3
	fi
	# print anything left over
	if [[ -n $print_string ]];then
		if [[ -n $line_1_starter ]];then
			line_starter="$line_1_starter"
			line_1_starter=''
		else
			line_starter="$line_x_starter"
		fi
		print_string=${print_string//\^/ }
		print_screen_output "$line_starter$print_string"
	fi
}
# print_lines_basic '1' '-m' 'let us teest this string and lots more and stuff and more stuff and x is wy and z is x and fred is dead and gus is alive an yes we have to go now'
# print_lines_basic '2' '7' 'and its substring this string and lots more and stuff and more stuff and x is wy and z is x and fred is dead and gus is alive an yes we have to go now'
# print_lines_basic '2' '12' 'and its sss substring'
# print_lines_basic '3' '12' 'and its sss substring this string and lots more and stuff and more stuff and x is wy and z is x and fred is dead and gus is alive an yes we have to go now'
# exit

## print out version information for -V/--version
print_version_info()
{
	# if not in PATH could be either . or directory name, no slash starting
	local script_path=$SELF_PATH script_symbolic_start=''
	if [[ $script_path == '.' ]];then
		script_path=$( pwd )
	elif [[ -z $( grep '^/' <<< "$script_path" ) ]];then
		script_path="$( pwd )/$script_path"
	fi
	# handle if it's a symbolic link, rare, but can happen with script directories in irc clients
	# which would only matter if user starts inxi with -! 30 override in irc client
	if [[ -L $script_path/$SELF_NAME ]];then
		script_symbolic_start=$script_path/$SELF_NAME
		script_path=$( readlink $script_path/$SELF_NAME )
		script_path=$( dirname $script_path )
	fi
	print_screen_output "$SELF_NAME $SELF_VERSION-$SELF_PATCH ($SELF_DATE)"
	if [[ $B_IRC == 'false' ]];then
		print_screen_output "Program Location: $script_path"
		if [[ -n $script_symbolic_start ]];then
			print_screen_output "Started via symbolic link: $script_symbolic_start"
		fi
		print_lines_basic "0" "" "Website:^https://github.com/smxi/inxi^or^http://smxi.org/"
		print_lines_basic "0" "" "IRC:^irc.oftc.net channel:^#smxi"
		print_lines_basic "0" "" "Forums:^http://techpatterns.com/forums/forum-33.html"
		print_screen_output " "
		print_lines_basic "0" "" "$SELF_NAME - the universal, portable, system information tool for console and irc."
		print_screen_output " "
		print_lines_basic "0" "" "This program started life as a fork of Infobash 3.02: Copyright^(C)^2005-2007^Michiel^de^Boer^a.k.a.^locsmif."
		print_lines_basic "0" "" "Subsequent changes and modifications (after Infobash 3.02): Copyright^(C)^2008-${SELF_DATE%%-*}^Harald^Hope^aka^h2. CPU/Konversation^fixes:^Scott^Rogers^aka^trash80. USB^audio^fixes:^Steven^Barrett^aka^damentz."
		print_screen_output " "
		print_lines_basic "0" "" "This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; either version 3 of the License, or (at your option) any later version. (http://www.gnu.org/licenses/gpl.html)"
	fi
}

########################################################################
#### MAIN FUNCTIONS
########################################################################

#### -------------------------------------------------------------------
#### initial startup stuff
#### -------------------------------------------------------------------

# Determine where inxi was run from, set IRC_CLIENT and IRC_CLIENT_VERSION
get_start_client()
{
	eval $LOGFS
	local Irc_Client_Path='' irc_client_path_lower='' non_native_konvi='' i=''
	local B_Non_Native_App='false' pppid='' App_Working_Name=''
	local b_qt4_konvi='false' ps_parent=''

	if [[ $B_IRC == 'false' ]];then
		IRC_CLIENT='Shell'
		unset IRC_CLIENT_VERSION
	# elif [[ -n $PPID ]];then
	elif [[ -n $PPID && -f /proc/$PPID/exe ]];then
		if [[ $B_OVERRIDE_FILTER != 'true' ]];then
			B_OUTPUT_FILTER='true'
		fi
		Irc_Client_Path=$( readlink /proc/$PPID/exe )
		# Irc_Client_Path=$( ps -p $PPID | gawk '!/[[:space:]]*PID/ {print $5}'  )
		# echo $( ps -p $PPID )
		if (( "$BASH" >= 4 ));then
			irc_client_path_lower=${Irc_Client_Path,,}
		else 
			irc_client_path_lower=$( tr '[A-Z]' '[a-z]' <<< "$Irc_Client_Path" )
		fi
		
		App_Working_Name=${irc_client_path_lower##*/}
		# handles the xchat/sh/bash/dash cases, and the konversation/perl cases, where clients
		# report themselves as perl or unknown shell. IE:  when konversation starts inxi
		# from inside itself, as a script, the parent is konversation/xchat, not perl/bash etc
		# note: perl can report as: perl5.10.0, so it needs wildcard handling
		case $App_Working_Name in
			# bsd will never use this section
			bash|dash|sh|python*|perl*)	# We want to know who wrapped it into the shell or perl.
				if [[ $BSD_TYPE != 'bsd' ]];then
					pppid=$( ps -p $PPID -o ppid --no-headers 2>/dev/null | gawk '{print $NF}' )
				else
					# without --no-headers we need the second line
					pppid=$( ps -p $PPID -o ppid 2>/dev/null | gawk '$1 ~ /^[0-9]+/ {print $5}' )
				fi
				if [[ -n $pppid && -f /proc/$pppid/exe ]];then
					Irc_Client_Path="$( readlink /proc/$pppid/exe )"
					if (( "$BASH" >= 4 ));then
						irc_client_path_lower=${Irc_Client_Path,,}
					else 
						irc_client_path_lower=$( tr '[A-Z]' '[a-z]' <<< "$Irc_Client_Path" )
					fi
					App_Working_Name=${irc_client_path_lower##*/}
					B_Non_Native_App='true'
				fi
				;;
		esac
		# sets version number if it can find it
		get_irc_client_version
	else
		## lets look to see if qt4_konvi is the parent.  There is no direct way to tell, so lets infer it.
		## because $PPID does not work with qt4_konvi, the above case does not work
		if [[ $B_OVERRIDE_FILTER != 'true' ]];then
			B_OUTPUT_FILTER='true'
		fi
		b_qt4_konvi=$( is_this_qt4_konvi )
		if [[ $b_qt4_konvi == 'true' ]];then
			KONVI=3
			IRC_CLIENT='Konversation'
			IRC_CLIENT_VERSION=" $( konversation -v | gawk '
				/Konversation:/ {
					for ( i=2; i<=NF; i++ ) {
						if (i == NF) {
							print $i
						}
						else {
							printf $i" "
						}
					}
					exit
				}' )"
		else
			# this should handle certain cases where it's ssh or some other startup tool
			# that falls through all the other tests. Also bsd irc clients will land here
			if [[ $BSD_TYPE != 'bsd' ]];then
				App_Working_Name=$(ps -p $PPID --no-headers 2>/dev/null | gawk '{print $NF}' )
			else
				# without --no-headers we need the second line
				App_Working_Name=$(ps -p $PPID 2>/dev/null | gawk '$1 ~ /^[0-9]+/ {print $5}' )
			fi
			
			if [[ -n $App_Working_Name ]];then
				Irc_Client_Path=$App_Working_Name
				if (( "$BASH" >= 4 ));then
					irc_client_path_lower=${Irc_Client_Path,,}
				else 
					irc_client_path_lower=$( tr '[A-Z]' '[a-z]' <<< "$Irc_Client_Path" )
				fi
				App_Working_Name=${irc_client_path_lower##*/}
				B_Non_Native_App='false'
				get_irc_client_version
				if [[ -z $IRC_CLIENT ]];then
					IRC_CLIENT=$App_Working_Name
				fi
			else
				IRC_CLIENT="PPID=\"$PPID\" - empty?"
				unset IRC_CLIENT_VERSION
			fi
		fi
	fi

	log_function_data "IRC_CLIENT: $IRC_CLIENT :: IRC_CLIENT_VERSION: $IRC_CLIENT_VERSION :: PPID: $PPID"
	eval $LOGFE
}
# note: all variables set in caller so no need to pass
get_irc_client_version()
{
	local file_data=''
	# replacing loose detection with tight detection, bugs will be handled with app names
	# as they appear.
	case $App_Working_Name in
		# check for shell first
		bash|dash|sh)
			unset IRC_CLIENT_VERSION
			IRC_CLIENT="Shell wrapper"
			;;
		# now start on irc clients, alphabetically
		bitchx)
			IRC_CLIENT_VERSION=" $( $Irc_Client_Path -v | gawk '
			/Version/ {
				a=tolower($2)
				gsub(/[()]|bitchx-/,"",a)
				print a
				exit
			}
			$2 == "version" {
				a=tolower($3)
				sub(/bitchx-/,"",a)
				print a
				exit
			}' )"
			B_CONSOLE_IRC='true'
			IRC_CLIENT="BitchX"
			;;
		finch)
			IRC_CLIENT_VERSION=" $( $Irc_Client_Path -v | gawk 'NR == 1 {
				print $2
			}' )"
			B_CONSOLE_IRC='true'
			IRC_CLIENT="Finch"
			;;
		gaim)
			IRC_CLIENT_VERSION=" $( $Irc_Client_Path -v | gawk 'NR == 1 {
				print $2
			}' )"
			IRC_CLIENT="Gaim"
			;;
		hexchat)
			# the hexchat author decided to make --version/-v return a gtk dialogue box, lol...
			# so we need to read the actual config file for hexchat. Note that older hexchats
			# used xchat config file, so test first for default, then legacy. Because it's possible
			# for this file to be use edited, doing some extra checks here.
			if [[ -f ~/.config/hexchat/hexchat.conf ]];then
				file_data="$( cat ~/.config/hexchat/hexchat.conf )"
			elif [[ -f  ~/.config/hexchat/xchat.conf ]];then
				file_data="$( cat ~/.config/hexchat/xchat.conf )"
			fi
			if [[ -n $file_data ]];then
				IRC_CLIENT_VERSION=$( gawk '
				BEGIN {
					IGNORECASE=1
					FS="="
				}
				/^[[:space:]]*version/ {
					# get rid of the space if present
					gsub(/[[:space:]]*/, "", $2 )
					print $2
					exit # usually this is the first line, no point in continuing
				}' <<< "$file_data" )
				
				IRC_CLIENT_VERSION=" $IRC_CLIENT_VERSION"
			else
				IRC_CLIENT_VERSION=' N/A'
			fi
			IRC_CLIENT="HexChat"
			;;
		ircii)
			IRC_CLIENT_VERSION=" $( $Irc_Client_Path -v | gawk 'NR == 1 {
				print $3
			}' )"
			B_CONSOLE_IRC='true'
			IRC_CLIENT="ircII"
			;;
		irssi|irssi-text)
			IRC_CLIENT_VERSION=" $( $Irc_Client_Path -v | gawk 'NR == 1 {
				print $2
			}' )"
			B_CONSOLE_IRC='true'
			IRC_CLIENT="Irssi"
			;;
		konversation) ## konvi < 1.2 (qt4)
			# this is necessary to avoid the dcop errors from starting inxi as a /cmd started script
			if [[ $B_Non_Native_App == 'true' ]];then  ## true negative is confusing
				KONVI=2
			else # if native app
				KONVI=1
			fi
			IRC_CLIENT_VERSION=" $( $Irc_Client_Path -v | gawk '
			/Konversation:/ {
				for ( i=2; i<=NF; i++ ) {
					if (i == NF) {
						print $i
					}
					else {
						printf $i" "
					}
				}
				exit
			}' )"
			T=($IRC_CLIENT_VERSION)
			if [[ ${T[0]} == *+* ]];then
				# < Sho_> locsmif: The version numbers of SVN versions look like this:
				#         "<version number of last release>+ #<build number", i.e. "1.0+ #3177" ...
				#         for releases we remove the + and build number, i.e. "1.0" or soon "1.0.1"
				IRC_CLIENT_VERSION=" CVS $IRC_CLIENT_VERSION"
				T2="${T[0]/+/}"
			else
				IRC_CLIENT_VERSION=" ${T[0]}"
				T2="${T[0]}"
			fi
			# Remove any dots except the first, and make sure there are no trailing zeroes,
			T2=$( echo "$T2" | gawk '{
				sub(/\./, " ")
				gsub(/\./, "")
				sub(/ /, ".")
				printf("%g\n", $0)
			}' )
			# Since Konversation 1.0, the DCOP interface has changed a bit: dcop "$DCPORT" Konversation ..etc
			# becomes : dcop "$DCPORT" default ... or dcop "$DCPORT" irc ..etc. So we check for versions smaller
			# than 1 and change the DCOP parameter/object accordingly.
			if [[ $T2 -lt 1 ]];then
				DCOPOBJ="Konversation"
			fi
			IRC_CLIENT="Konversation"
			;;
		kopete)
			IRC_CLIENT_VERSION=" $( kopete -v | gawk '
			/Kopete:/ {
				print $2
				exit
			}' )"
			IRC_CLIENT="Kopete"
			;;
		kvirc)
			IRC_CLIENT_VERSION=" $( $Irc_Client_Path -v 2>&1 | gawk '{
				for ( i=2; i<=NF; i++) {
					if ( i == NF ) {
						print $i
					}
					else {
						printf $i" "
					}
				}
				exit
				}' )"
			IRC_CLIENT="KVIrc"
			;;
		pidgin)
			IRC_CLIENT_VERSION=" $( $Irc_Client_Path -v | gawk 'NR == 1 {
				print $2
			}' )"
			IRC_CLIENT="Pidgin"
			;;
		# possible failure of wildcard so make it explicit
		quassel*)
			# sample: quassel -v
			## Qt: 4.5.0 - in Qt4 the output came from src/common/quassel.cpp
			# KDE: 4.2.65 (KDE 4.2.65 (KDE 4.3 >= 20090226))
			# Quassel IRC: v0.4.0 [+60] (git-22effe5)
			# note: early < 0.4.1 quassels do not have -v
			## Qt: 5: sample: quassel -v
			# quassel v0.13-pre (0.12.0+5 git-8e2f578)
			# because in Qt5 the internal CommandLineParser is used 
			IRC_CLIENT_VERSION=" $( $Irc_Client_Path -v 2>/dev/null | gawk '
			BEGIN {
				IGNORECASE=1
				clientVersion=""
			}
			# qt 4 -v syntax
			/^Quassel IRC:/ {
				clientVersion = $3
			}
			# qt 5 -v syntax
			/^quassel\s[v]?[0-9]/ {
				clientVersion = $2
			}
			END {
				# this handles pre 0.4.1 cases with no -v
				if ( clientVersion == "" ) {
					clientVersion = "(pre v0.4.1)?"
				}
				print clientVersion
			}' )"
			# now handle primary, client, and core. quasselcore doesn't actually
			# handle scripts with exec, but it's here just to be complete
			case $App_Working_Name in
				quassel)
					IRC_CLIENT="Quassel [M]"
					;;
				quasselclient)
					IRC_CLIENT="Quassel"
					;;
				quasselcore)
					IRC_CLIENT="Quassel (core)"
					;;
			esac
			;;
		gribble|limnoria|supybot)
			IRC_CLIENT_VERSION=" $( get_program_version 'supybot' '^Supybot' '2' )"
			if [[ -n $IRC_CLIENT_VERSION ]];then
				if [[ -n ${IRC_CLIENT_VERSION/*gribble*/} || $App_Working_Name == 'gribble' ]];then
					IRC_CLIENT="Gribble"
				elif [[ -n ${IRC_CLIENT_VERSION/*limnoria*/} || $App_Working_Name == 'limnoria' ]];then
					IRC_CLIENT="Limnoria"
				else
					IRC_CLIENT="Supybot"
				fi
			fi
			;;
		weechat|weechat-curses)
			IRC_CLIENT_VERSION=" $( $Irc_Client_Path -v ) "
			B_CONSOLE_IRC='true'
			IRC_CLIENT="WeeChat"
			;;
		xchat-gnome)
			IRC_CLIENT_VERSION=" $( $Irc_Client_Path -v | gawk 'NR == 1 {
				print $2
			}' )"
			IRC_CLIENT="X-Chat-Gnome"
			;;
		xchat)
			IRC_CLIENT_VERSION=" $( $Irc_Client_Path -v | gawk 'NR == 1 {
				print $2
			}' )"
			IRC_CLIENT="X-Chat"
			;;
		# then do some perl type searches, do this last since it's a wildcard search
		perl*|ksirc|dsirc)
			unset IRC_CLIENT_VERSION
			# KSirc is one of the possibilities now. KSirc is a wrapper around dsirc, a perl client
			get_cmdline $PPID
			for (( i=0; i <= $CMDL_MAX; i++ ))
			do
				case ${A_CMDL[i]} in
					*dsirc*)
					IRC_CLIENT="KSirc"
					# Dynamic runpath detection is too complex with KSirc, because KSirc is started from
					# kdeinit. /proc/<pid of the grandparent of this process>/exe is a link to /usr/bin/kdeinit
					# with one parameter which contains parameters separated by spaces(??), first param being KSirc.
					# Then, KSirc runs dsirc as the perl irc script and wraps around it. When /exec is executed,
					# dsirc is the program that runs inxi, therefore that is the parent process that we see.
					# You can imagine how hosed I am if I try to make inxi find out dynamically with which path
					# KSirc was run by browsing up the process tree in /proc. That alone is straightjacket material.
					# (KSirc sucks anyway ;)
					IRC_CLIENT_VERSION=" $( ksirc -v | gawk '
					/KSirc:/ {
						print $2
						exit
					}' )"
					break
					;;
				esac
			done
			B_CONSOLE_IRC='true'
			set_perl_python_client_data "$App_Working_Name"
			;;
		python*)
			# B_CONSOLE_IRC='true' # are there even any python type console irc clients? check.
			set_perl_python_client_data "$App_Working_Name"
			;;
		# then unset, set unknown data
		*)	
			IRC_CLIENT="Unknown : ${Irc_Client_Path##*/}"
			unset IRC_CLIENT_VERSION
			;;
	esac
	if [[ $SHOW_IRC -lt 2 ]];then
		unset IRC_CLIENT_VERSION
	fi
}

# args: $1 - App_Working_Name
set_perl_python_client_data()
{
	if [[ -z $IRC_CLIENT_VERSION ]];then
		local version=''
		# this is a hack to try to show konversation if inxi is running but started via /cmd
		# OR via script shortcuts, both cases in fact now
		if [[  $B_RUNNING_IN_DISPLAY == 'true' && -z ${Ps_aux_Data/*konversation*/} ]];then
			IRC_CLIENT='Konversation'
			version=$( get_program_version 'konversation' '^konversation' '2' )
			B_CONSOLE_IRC='false'
		## NOTE: supybot only appears in ps aux using 'SHELL' command; the 'CALL' command
		## gives the user system irc priority, and you don't see supybot listed, so use SHELL
		elif [[ $B_RUNNING_IN_DISPLAY == 'false' && -z ${Ps_aux_Data/*supybot*/} ]];then
			version=$( get_program_version 'supybot' '^Supybot' '2' )
			if [[ -n $version ]];then
				IRC_CLIENT_VERSION=" $version"
				if [[ -z ${version/*gribble*/} ]];then
					IRC_CLIENT='Gribble'
				elif [[ -z ${version/*limnoria*/} ]];then
					IRC_CLIENT='Limnoria'
				else
					IRC_CLIENT='Supybot'
				fi
			else
				IRC_CLIENT='Supybot'
			# currently all use the same actual app name, this will probably change.
			fi
			B_CONSOLE_IRC='true'
		else
			IRC_CLIENT="Unknown $1 client"
		fi
		if [[ -n $version ]];then
			IRC_CLIENT_VERSION=" $version"
		fi
	fi
}

## try to infer the use of Konversation >= 1.2, which shows $PPID improperly
## no known method of finding Kovni >= 1.2 as parent process, so we look to see if it is running,
## and all other irc clients are not running. As of 2014-03-25 this isn't used in my cases
is_this_qt4_konvi()
{
	local konvi_qt4_client='' konvi_dbus_exist='' konvi_pid='' konvi_home_dir='' 
	local konvi='' b_is_qt4=''
	
	# fringe cases can throw error, always if untested app, use 2>/dev/null after testing if present
	if [[ $B_QDBUS == 'true' ]];then
		konvi_dbus_exist=$( qdbus 2>/dev/null | grep "org.kde.konversation" )
	fi
	# sabayon uses /usr/share/apps/konversation as path
	if [[ -n $konvi_dbus_exist ]] && [[ -e /usr/share/kde4/apps/konversation || -e  /usr/share/apps/konversation ]]; then
		konvi_pid=$( ps -A | gawk 'BEGIN{IGNORECASE=1} /konversation/ { print $1 }' ) 
		konvi_home_dir=$( readlink /proc/$konvi_pid/exe )
		konvi=$( echo $konvi_home_dir | sed "s/\// /g" )
		konvi=($konvi)

		if [[ ${konvi[2]} == 'konversation' ]];then
			# note: we need to change this back to a single dot number, like 1.3, not 1.3.2
			konvi_qt4_client=$( konversation -v | grep -i 'konversation' | \
			gawk '{ print $2 }' | cut -d '.' -f 1,2 )
			if [[ $konvi_qt4_client > 1.1 ]]; then
				b_is_qt4='true'
			fi
		fi
	else
		konvi_qt4="qt3"
		b_is_qt4='false'
	fi
	log_function_data "b_is_qt4: $b_is_qt4"
	echo $b_is_qt4
	## for testing this module
	#qdbus org.kde.konversation /irc say $1 $2 "getpid_dir: $konvi_qt4  qt4_konvi: $konvi_qt4_ver   verNum: $konvi_qt4_ver_num  pid: $konvi_pid ppid: $PPID  konvi_home_dir: ${konvi[2]}"
}

# This needs some cleanup and comments, not quite understanding what is happening, although generally output is known
# Parse the null separated commandline under /proc/<pid passed in $1>/cmdline
# args: $1 - $PPID
get_cmdline()
{
	eval $LOGFS
	local i=0 ppid=$1

	if [[ ! -e /proc/$ppid/cmdline ]];then
		echo 0
		return
	fi
	##print_screen_output "Marker"
	##print_screen_output "\$ppid='$ppid' -=- $(< /proc/$ppid/cmdline)"
	unset A_CMDL
	## note: need to figure this one out, and ideally clean it up and make it readable
	while read -d $'\0' L && [[ $i -lt 32 ]]
	do
		A_CMDL[i++]="$L" ## note: make sure this is valid - What does L mean? ##
	done < /proc/$ppid/cmdline
	##print_screen_output "\$i='$i'"
	if [[ $i -eq 0 ]];then
		A_CMDL[0]=$(< /proc/$ppid/cmdline)
		if [[ -n ${A_CMDL[0]} ]];then
			i=1
		fi
	fi
	CMDL_MAX=$i
	log_function_data "CMDL_MAX: $CMDL_MAX"
	eval $LOGFE
}

#### -------------------------------------------------------------------
#### get data types
#### -------------------------------------------------------------------
## create array of sound cards installed on system, and if found, use asound data as well
get_audio_data()
{
	eval $LOGFS
	local i='' alsa_data='' audio_driver='' device_count='' a_temp=''

	IFS=$'\n'
	# this first step handles the drivers for cases where the second step fails to find one
	device_count=$( echo "$LSPCI_V_DATA" | grep -iEc '(multimedia audio controller|audio device)' )
	if [[ $device_count -eq 1 ]] && [[ $B_ASOUND_DEVICE_FILE == 'true' ]];then
		audio_driver=$( gawk -F ']: ' '
		BEGIN {
			IGNORECASE=1
		}
		# filtering out modems and usb devices like webcams, this might get a
		# usb audio card as well, this will take some trial and error
		$0 !~ /modem|usb|webcam/ {
			driver=gensub( /^(.+)( - )(.+)$/, "\\1", 1, $2 )
			gsub(/^ +| +$/,"",driver)
			if ( driver != "" ){
				print driver
			}
		}' $FILE_ASOUND_DEVICE ) 
		log_function_data 'cat' "$FILE_ASOUND_DEVICE"
	fi

	# this is to safeguard against line breaks from results > 1, which if inserted into following
	# array will create a false array entry. This is a hack, not a permanent solution.
	audio_driver=$( echo $audio_driver )
	# now we'll build the main audio data, card name, driver, and port. If no driver is found,
	# and if the first method above is not null, and one card is found, it will use that instead.
	A_AUDIO_DATA=( $( echo "$LSPCI_V_DATA" | gawk -F ': ' -v audioDriver="$audio_driver" '
	BEGIN {
		IGNORECASE=1
	}
	/multimedia audio controller|audio device/ {
		audioCard=gensub(/^[0-9a-f:\.]+ [^:]+: (.+)$/,"\\1","g",$0)
		# The doublequotes are necessary because of the pipes in the variable.
		gsub(/'"$BAN_LIST_NORMAL"'/, "", audioCard)
		gsub(/'"$BAN_LIST_ARRAY"'/, " ", audioCard)
		if ( '$COLS_INNER' < 100 ){
			sub(/Series Family/,"Series", audioCard)
			sub(/High Definition/,"High Def.", audioCard)
		}
		gsub(/^ +| +$/, "", audioCard)
		gsub(/ [ \t]+/, " ", audioCard)
		aPciBusId[audioCard] = gensub(/(^[0-9a-f:\.]+) [^:]+: .+$/,"\\1","g",$0)
		cards[audioCard]++

		# loop until you get to the end of the data block
		while (getline && !/^$/) {
			gsub(/'"$BAN_LIST_ARRAY"'/, "", $0 )
			if (/driver in use/) {
				drivers[audioCard] = drivers[audioCard] gensub( /(.*): (.*)/ ,"\\2", "g" ,$0 ) ""
			}
			else if (/kernel modules:/) {
				modules[audioCard] = modules[audioCard] gensub( /(.*): (.*)/ ,"\\2" ,"g" ,$0 ) ""
			}
			else if (/^[[:space:]]*I\/O/) {
				portsTemp = gensub(/\t*I\/O ports at ([a-z0-9]+)(| \[.*\])/,"\\1","g",$0)
				ports[audioCard] = ports[audioCard] portsTemp " "
			}
		}
	}

	END {
		j=0
		for (i in cards) {
			useDrivers=""
			useModules=""
			usePorts=""
			usePciBusId=""
			 
			if (cards[i]>1) {
				a[j]=cards[i]"x "i
				if (drivers[i] != "") {
					useDrivers=drivers[i]
				}
			}
			else {
				a[j]=i
				# little trick here to try to catch the driver if there is
				# only one card and it was null, from the first test of asound/cards
				if (drivers[i] != "") {
					useDrivers=drivers[i]
				}
				else if ( audioDriver != "" ) {
					useDrivers=audioDriver
				}
			}
			if (ports[i] != "") {
				usePorts = ports[i]
			}
			if (modules[i] != "" ) {
				useModules = modules[i]
			}
			if ( aPciBusId[i] != "" ) {
				usePciBusId = aPciBusId[i]
			}
			# create array primary item for master array
			sub( / $/, "", usePorts ) # clean off trailing whitespace
			print a[j] "," useDrivers "," usePorts "," useModules "," usePciBusId
			j++
		}
	}') )

	# in case of failure of first check do this instead
	if [[ ${#A_AUDIO_DATA[@]} -eq 0 ]] && [[ $B_ASOUND_DEVICE_FILE == 'true' ]];then
		A_AUDIO_DATA=( $( gawk -F ']: ' '
		BEGIN {
			IGNORECASE=1
		}
		$1 !~ /modem/ && $2 !~ /modem/ {
			card=gensub( /^(.+)( - )(.+)$/, "\\3", 1, $2 )
			driver=gensub( /^(.+)( - )(.+)$/, "\\1", 1, $2 )
			if ( card != "" ){
				print card","driver
			}
		}' $FILE_ASOUND_DEVICE ) )
	fi
	IFS="$ORIGINAL_IFS"
	get_audio_usb_data
	# handle cases where card detection fails, like in PS3, where lspci gives no output, or headless boxes..
	if [[ ${#A_AUDIO_DATA[@]} -eq 0 ]];then
		A_AUDIO_DATA[0]='Failed to Detect Sound Card!'
	fi
	a_temp=${A_AUDIO_DATA[@]}
	log_function_data "A_AUDIO_DATA: $a_temp"

	eval $LOGFE
}
# alsa usb detection by damentz

get_audio_usb_data()
{
	eval $LOGFS
	local usb_proc_file='' array_count='' usb_data='' usb_id='' lsusb_data=''
	local a_temp=''
	
	IFS=$'\n'
	if type -p lsusb &>/dev/null;then
		lsusb_data=$( lsusb 2>/dev/null )
	fi
	log_function_data 'raw' "usb_data:\n$lsusb_data"
	if [[ -n $lsusb_data && -d /proc/asound/ ]];then
		# for every sound card symlink in /proc/asound - display information about it
		for usb_proc_file in /proc/asound/*
		do
			# If the file is a symlink, and contains an important usb exclusive file: continue
			if [[ -L $usb_proc_file && -e $usb_proc_file/usbid  ]]; then
				# find the contents of usbid in lsusb and print everything after the 7th word on the
				# corresponding line. Finally, strip out commas as they will change the driver :)
				usb_id=$( cat $usb_proc_file/usbid )
				usb_data=$( grep "$usb_id" <<< "$lsusb_data" )
				if [[ -n $usb_data && -n $usb_id ]];then
					usb_data=$( gawk '
					BEGIN {
						IGNORECASE=1
						string=""
						separator=""
					}
					{
						gsub(/'"$BAN_LIST_ARRAY"'/, " ", $0 )
						gsub(/'"$BAN_LIST_NORMAL"'/, "", $0)
						gsub(/ [ \t]+/, " ", $0)
						for ( i=7; i<= NF; i++ ) {
							string = string separator $i
							separator = " "
						}
						if ( $2 != "" ){
							sub(/:/,"", $4)
							print string ",USB Audio,,," $2 "-" $4 "," $6
						}
					}' <<< "$usb_data" )
				fi
				# this method is interesting, it shouldn't work but it does
				#A_AUDIO_DATA=( "${A_AUDIO_DATA[@]}" "$usb_data,USB Audio,," )
				# but until we learn why the above worked, I'm using this one, which is safer
				if [[ -n $usb_data ]];then
					array_count=${#A_AUDIO_DATA[@]}
					A_AUDIO_DATA[$array_count]="$usb_data"
				fi
			fi
		done
	fi
	IFS="$ORIGINAL_IFS"
	a_temp=${A_AUDIO_DATA[@]}
	log_function_data "A_AUDIO_DATA: $a_temp"
	
	eval $LOGFE
}

get_audio_alsa_data()
{
	eval $LOGFS
	local alsa_data='' a_temp=''

	# now we'll get the alsa data if the file exists
	if [[ $B_ASOUND_VERSION_FILE == 'true' ]];then
		IFS=","
		A_ALSA_DATA=( $( 
		gawk '
			BEGIN {
				IGNORECASE=1
				alsa=""
				version=""
			}
			# some alsa strings have the build date in (...)
			# remove trailing . and remove possible second line if compiled by user
			$0 !~ /compile/ {
				gsub(/Driver | [(].*[)]|\.$/,"",$0 )
				gsub(/'"$BAN_LIST_ARRAY"'/, " ", $0)
				gsub(/^ +| +$/, "", $0)
				gsub(/ [ \t]+/, " ", $0)
				sub(/Advanced Linux Sound Architecture/, "ALSA", $0)
				if ( $1 == "ALSA" ){
					alsa=$1
				}
				version=$NF
				print alsa "," version
			}' $FILE_ASOUND_VERSION ) )
		IFS="$ORIGINAL_IFS"
		log_function_data 'cat' "$FILE_ASOUND_VERSION"
	fi
	a_temp=${A_ALSA_DATA[@]}
	log_function_data "A_ALSA_DATA: $a_temp"
	eval $LOGFE
}

get_battery_data()
{
	eval $LOGFS
	local a_temp='' id_file='' count=0
	local id_dir='/sys/class/power_supply/' 
	local ids=$( ls $id_dir 2>/dev/null )  battery_file='' 
	
	# ids='BAT0 BAT1 BAT2'
	if [[ -n $ids && $B_FORCE_DMIDECODE == 'false' ]];then
		for idx in $ids
		do
			battery_file=$id_dir$idx'/uevent'
			if [[ -r $battery_file ]];then
				#  echo $battery_file
				count=$(( $count + 1 ))
				IFS=$'\n'
				battery_data=$( 
				gawk -F '=' '
				BEGIN {
					IGNORECASE=1
					name=""
					status=""
					present=""
					chemistry=""
					cycles=""
					voltage_min_design=""
					voltage_now=""
					power_now=""
					# charge: mAh
					charge_full_design=""
					charge_full=""
					charge_now=""
					# energy: Wh
					energy_full_design=""
					energy_full=""
					energy_now=""
					capacity=""
					capacity_level=""
					model=""
					company=""
					serial=""
					of_orig=""
					location=""
					b_ma="false" # trips ma x voltage
				}
				{
					gsub(/'"$BAN_LIST_NORMAL"'|,|battery|unknown/, "", $2)
					gsub(/^ +| +$/, "", $2)
				}
				$1 ~ /^POWER_SUPPLY_NAME$/ {
					name=$NF
				}
				$1 ~ /^POWER_SUPPLY_STATUS$/ {
					status=$NF
				}
				$1 ~ /^POWER_SUPPLY$/ {
					present=$NF
				}
				$1 ~ /^POWER_SUPPLY_TECHNOLOGY$/ {
					chemistry=$NF
				}
				$1 ~ /^POWER_SUPPLY_CYCLE_COUNT$/ {
					cycles=$NF
				}
				$1 ~ /^POWER_SUPPLY_VOLTAGE_MIN_DESIGN$/ {
					voltage_min_design = $NF / 1000000
					voltage_min_design = sprintf( "%.1f", voltage_min_design )
				}
				$1 ~ /^POWER_SUPPLY_VOLTAGE_NOW$/ {
					voltage_now = $NF / 1000000
					voltage_now = sprintf( "%.1f", voltage_now )
				}
				$1 ~ /^POWER_SUPPLY_POWER_NOW$/ {
					power_now=$NF
				}
				$1 ~ /^POWER_SUPPLY_ENERGY_FULL_DESIGN$/ {
					energy_full_design = $NF / 1000000
				}
				$1 ~ /^POWER_SUPPLY_ENERGY_FULL$/ {
					energy_full = $NF / 1000000
				}
				$1 ~ /^POWER_SUPPLY_ENERGY_NOW$/ {
					energy_now = $NF / 1000000
					energy_now = sprintf( "%.1f", energy_now )
				}
				# note: the following 3 were off, 100000 instead of 1000000
				# why this is, I do not know. I did not document any reason for that
				# so going on assumption it is a mistake. CHARGE is mAh, which are converted
				# to Wh by: mAh x voltage. Note: voltage fluctuates so will make results vary slightly.
				$1 ~ /^POWER_SUPPLY_CHARGE_FULL_DESIGN$/ {
					charge_full_design = $NF / 1000000
					b_ma="true"
				}
				$1 ~ /^POWER_SUPPLY_CHARGE_FULL$/ {
					charge_full = $NF / 1000000
					b_ma="true"
				}
				$1 ~ /^POWER_SUPPLY_CHARGE_NOW$/ {
					charge_now = $NF / 1000000
					b_ma="true"
				}
				$1 ~ /^POWER_SUPPLY_CAPACITY$/ {
					if ( $NF != "" ){
						capacity=$NF "%"
					}
				}
				$1 ~ /^POWER_SUPPLY_CAPACITY_LEVEL$/ {
					capacity_level=$NF
				}
				$1 ~ /^POWER_SUPPLY_MODEL_NAME$/ {
					model=$NF
				}
				$1 ~ /^POWER_SUPPLY_MANUFACTURER$/ {
					company=$NF
				}
				$1 ~ /^POWER_SUPPLY_SERIAL_NUMBER$/ {
					serial=$NF
				}
				END {
					# note:voltage_now fluctuates, which will make capacity numbers change a bit
					# if any of these values failed, the math will be wrong, but no way to fix that
					# tests show more systems give right capacity/charge with voltage_min_design 
					# than with voltage_now
					if (b_ma == "true" && voltage_min_design != ""){
						if (charge_now != ""){
							energy_now=charge_now*voltage_min_design
						}
						if (charge_full != ""){
							energy_full=charge_full*voltage_min_design
						}
						if (charge_full_design != ""){
							energy_full_design=charge_full_design*voltage_min_design
						}
					}
					if (energy_now != "" && energy_full != "" ){
						capacity = 100*energy_now/energy_full
						capacity = sprintf( "%.1f%", capacity )
					}
					if (energy_full_design != "" && energy_full != "" ){
						of_orig=100*energy_full/energy_full_design
						of_orig = sprintf( "%.0f%", of_orig )
					}
					if (energy_now != "" ){
						energy_now = sprintf( "%.1f", energy_now )
					}
					if (energy_full_design != "" ){
						energy_full_design = sprintf( "%.1f", energy_full_design )
					}
					if ( energy_full != "" ){
						energy_full = sprintf( "%.1f", energy_full )
					}
					entry = name "," status "," present "," chemistry "," cycles "," voltage_min_design "," voltage_now "," 
					entry = entry power_now "," energy_full_design "," energy_full "," energy_now "," capacity "," 
					entry = entry capacity_level "," of_orig "," model "," company "," serial "," location
					print entry
				}' < $battery_file )
				# <<< "$data" )
				# < $battery_file ) 
				A_BATTERY_DATA[$count]=$battery_data
				IFS="$ORIGINAL_IFS"
			fi
		done
	elif [[ $B_FORCE_DMIDECODE == 'true'  ]] || [[ ! -d $id_dir && -z $ids ]];then
		get_dmidecode_data
		if [[ -n $DMIDECODE_DATA ]];then
			if [[ $DMIDECODE_DATA == 'dmidecode-error-'* ]];then
				A_BATTERY_DATA[0]=$DMIDECODE_DATA
			# please note: only dmidecode version 2.11 or newer supports consistently the -s flag
			else
				IFS=$'\n'
				# NOTE: this logic has a flaw, which is multiple batteries, which won't work without
				# gawk arrays, but sorry, too much of a pain given how little useful data from dmidecode
				A_BATTERY_DATA=( $( gawk -F ':' '
				BEGIN {
					IGNORECASE=1
					name=""
					status=""
					present=""
					chemistry=""
					cycles=""
					voltage_min_design=""
					voltage_now=""
					power_now=""
					charge_full_design=""
					charge_full=""
					charge_now=""
					capacity=""
					capacity_level=""
					model=""
					company=""
					serial=""
					of_orig=""
					location=""
					bItemFound="false"
				}
				{
					gsub(/'"$BAN_LIST_NORMAL"'|,|battery|unknown/, "", $2)
					gsub(/^ +| +$/, "", $1)
					gsub(/^ +| +$/, "", $2)
				}
				/^Portable Battery/ {
					while ( getline && !/^$/ ) {
						if ( $1 ~ /^Location/ ) { location=$2 }
						if ( $1 ~ /^Manufacturer/ ) { company=$2 }
						if ( $1 ~ /^Serial/ ) { serial=$2 }
						if ( $1 ~ /^Name/ ) { model=$2 }
						if ( $1 ~ /^Design Capacity/ ) { 
							sub(/^[[:space:]]*mwh/, "", $2)
							charge_full_design = $NF / 1000
							charge_full_design = sprintf( "%.1f", charge_full_design )
						}
						if ( $1 ~ /^Design Voltage/ ) { 
							sub(/^[[:space:]]*mv/, "", $2)
							voltage_min_design = $NF / 1000
							voltage_min_design = sprintf( "%.1f", voltage_min_design )
						}
						if ( $1 ~ /^SBDS Chemistry/ ) { chemistry=$2 }
					}
					testString=company serial model charge_full_design voltage_min_design
					if ( testString != ""  ) {
						bItemFound="true"
						exit # exit loop, we are not handling > 1 batteries
					}
				}
				END {
					if ( bItemFound == "true" ) {
						name="BAT-1"
						if (charge_now != "" && charge_full != "" ){
							capacity = 100*charge_now/charge_full
							capacity = sprintf( "%.1f%", capacity )
						}
						if (charge_full_design != "" && charge_full != "" ){
							of_orig=100*charge_full/charge_full_design
							of_orig = sprintf( "%.0f%", of_orig )
						}
						entry = name "," status "," present "," chemistry "," cycles "," voltage_min_design "," voltage_now "," 
						entry = entry power_now "," charge_full_design "," charge_full "," charge_now "," capacity "," 
						entry = entry capacity_level "," of_orig "," model "," company "," serial "," location
						print entry
					}
				}' <<< "$DMIDECODE_DATA" ) )
				IFS="$ORIGINAL_IFS"
			fi
		fi
	fi
	# echo $array_string
	
	#echo ${#A_BATTERY_DATA[@]}
	a_temp=${A_BATTERY_DATA[@]}
	
 	# echo $a_temp
	log_function_data "A_BATTERY_DATA: $a_temp"
	eval $LOGFE
}

## args: $1 type [intel|amd|centaur|arm]; $2 family [hex]; $3 model id [hex]; 
get_cpu_architecture()
{
	eval $LOGFS
	case $1 in
		# https://en.wikipedia.org/wiki/List_of_AMD_CPU_microarchitectures
		amd)
			case $2 in
				4)
					case $3 in
						3|7|8|9|A)ARCH='Am486';;
						E|F)ARCH='Am5x86';;
					esac
					;;
				5)
					case $3 in
						0|1|2|3)ARCH='K5';;
						6|7)ARCH='K6';;
						8)ARCH='K6-2';;
						9|D)ARCH='K6-3';;
						A)ARCH='Geode';;
					esac
					;;
				6)
					case $3 in
						1|2)ARCH='K7';;
						3|4)ARCH='K7 Thunderbird';;
						6|7|8|A)ARCH='K7 Palomino+';;
						*)ARCH='K7';;
					esac
					;;
				F)
					case $3 in
						4|5|7|8|B|C|E|F|14|15|17|18|1B|1C|1F)ARCH='K8';;
						21|23|24|25|27|28|2C|2F)ARCH='K8 rev.E';;
						41|43|48|4B|4C|4F|5D|5F|68|6B|6C|6F|7C|7F|C1)ARCH='K8 rev.F+';;
						*)ARCH='K8';;
					esac
					;;
				10)
					case $3 in
						2|4|5|6|8|9|A)ARCH='K10';;
						*)ARCH='K10';;
					esac
					;;
				11)
					case $3 in
						3)ARCH='Turion X2 Ultra';;
					esac
					;;
				12) # might also need cache handling like 14/16
					case $3 in
						1)ARCH='Fusion';;
						*)ARCH='Fusion';;
					esac
					;;
				14) # SOC, apu
					case $3 in
						1|2)ARCH='Bobcat';;
						*)ARCH='Bobcat';;
					esac
					;;
				15)
					case $3 in
						0|1|2|3|4|5|6|7|8|9|A|B|C|D|E|F)ARCH='Bulldozer';;
						10|11|12|13|14|15|16|17|18|19|1A|1B|1C|1D|1E|1F)ARCH='Piledriver';;
						30|31|32|33|34|35|36|37|38|39|3A|3B|3C|3D|3E|3F)ARCH='Steamroller';;
						60|61|62|63|64|65|66|67|68|69|6A|6B|6C|6D|6E|6F|70|71|72|73|74|75|76|77|78|79|7A|7B|7C|7D|7E|7F)ARCH='Excavator';;
						*)ARCH='Bulldozer';;
					esac
					;;
				16) # SOC, apu
					case $3 in
						0|1|2|3|4|5|6|7|8|9|A|B|C|D|E|F)ARCH='Jaguar';;
						30|31|32|33|34|35|36|37|38|39|3A|3B|3C|3D|3E|3F)ARCH='Puma';;
						*)ARCH='Jaguar';;
					esac
					;;
				17)
					case $3 in
						1)ARCH='Zen';;
						*)ARCH='Zen';;
					esac
					;;
			esac
			;;
		arm)
			if [[ "$2" != '' ]];then
				ARCH="ARMv$2"
			else
				ARCH='ARM'
			fi
			;;
		centaur) # aka VIA
			case $2 in
				5)
					case $3 in
						4)ARCH='WinChip C6';;
						8)ARCH='WinChip 2';;
						9)ARCH='WinChip 3';;
					esac
					;;
				6)
					case $3 in
						6)ARCH='WinChip-based';;
						7|8)ARCH='C3';;
						9)ARCH='C3-2';;
						A|D)ARCH='C7';;
						F)ARCH='Isaiah';;
					esac
					;;
			esac
			;;
		intel)
			case $2 in
				4)
					case $3 in
						0|1|2|3|4|5|6|7|8|9)ARCH='486';;
					esac
					;;
				5)
					case $3 in
						1|2|3|7)ARCH='P5';;
						4|8)ARCH='P5';; # MMX
						9)ARCH='Quark';;
					esac
					;;
				6)
					case $3 in
						1)ARCH='P6 Pro';;
						3|5|6)ARCH='P6 II';;
						7|8|A|B)ARCH='P6 III';;
						9)ARCH='Banias';; # pentium M
						15)ARCH='Dothan Tolapai';; # pentium M system on chip
						D)ARCH='Dothan';; # Pentium M
						E)ARCH='Yonah';;
						F|16)ARCH='Conroe';;
						17|1D)ARCH='Penryn';;
						1A|1E|1F|2E|25|2C|2F)ARCH='Nehalem';;
						1C|26)ARCH='Bonnell';;
						27|35|36)ARCH='Saltwell';;
						25|2C|2F)ARCH='Westmere';;
						26|27)ARCH='Bonnell';;
						2A|2D)ARCH='Sandy Bridge';;
						37|4A|4D|5A)ARCH='Silvermont';;
						3A|3E)ARCH='Ivy Bridge';;
						3C|3F|45|46)ARCH='Haswell';;
						3D|47|4F|56)ARCH='Broadwell';;
						4E|55|9E)ARCH='Skylake';;
						5E)ARCH='Skylake-S';;
						4C|5D)ARCH='Airmont';;
						8E|9E)ARCH='Kaby Lake';;
						57)ARCH='Knights Landing';;
						85)ARCH='Knights Mill';;
						# product codes: https://en.wikipedia.org/wiki/List_of_Intel_microprocessors
						# coming: coffee lake; cannonlake; icelake; tigerlake
					esac
					;;
				B)
					case $3 in
						1)ARCH='Knights Corner';;
					esac
					;;
				F)
					case $3 in
						0|1|2)ARCH='Netburst Willamette';;
						3|4|6)ARCH='Netburst Prescott';; # Nocona
						*)ARCH='Netburst';;
					esac
					;;
			esac
			;;
		
	esac
	log_function_data "ARCH: $ARCH"
	eval $LOGFE
}

## create A_CPU_CORE_DATA, currently with two values: integer core count; core string text
## return value cpu core count string, this helps resolve the multi redundant lines of old style output
get_cpu_core_count()
{
	eval $LOGFS
	local cpu_physical_count='' cpu_core_count='' cpu_type='' cores_per_cpu=''
	local array_data=''
	
	if [[ $B_CPUINFO_FILE == 'true' ]]; then
		# load the A_CPU_TYPE_PCNT_CCNT core data array
		get_cpu_ht_multicore_smp_data
		## Because of the upcoming release of cpus with core counts over 6, a count of cores is given after Deca (10)
		# count the number of processors given
		cpu_physical_count=${A_CPU_TYPE_PCNT_CCNT[1]}
		cpu_core_count=${A_CPU_TYPE_PCNT_CCNT[2]}
		cpu_type=${A_CPU_TYPE_PCNT_CCNT[0]}

		# match the numberic value to an alpha value
		get_cpu_core_count_alpha "$cpu_core_count"
		
		# create array, core count integer; core count string
		# A_CPU_CORE_DATA=( "$cpu_core_count" "$CPU_COUNT_ALPHA Core$cpu_type" )
		array_data="$cpu_physical_count,$CPU_COUNT_ALPHA,$cpu_type,$cpu_core_count"
		IFS=','
		A_CPU_CORE_DATA=( $array_data )
		IFS="$ORIGINAL_IFS"
	elif [[ -n $BSD_TYPE ]];then
		local gawk_fs=': '
	
		if [[ $BSD_VERSION == 'openbsd' ]];then
			gawk_fs='='
		fi
		cpu_core_count=$( gawk -F "$gawk_fs" -v bsdVersion="$BSD_VERSION" '
		# note: on openbsd can also be hw.ncpufound so exit after first
		BEGIN {
			coreCount=""
		}
		$1 ~ /^hw.ncpu$/ {
			coreCount=$NF
		}
		/^machdep.cpu.core_count/ {
			coreCount=$NF
		}
		END {
			print coreCount
		}' <<< "$SYSCTL_A_DATA" )
		cores_per_cpu=$( gawk -F "$gawk_fs" '
		/^machdep.cpu.cores_per_package/ {
			print $NF
		}' <<< "$SYSCTL_A_DATA" )
		
		if [[ -n $( grep -E '^[0-9]+$' <<< "$cpu_core_count" ) ]];then
			get_cpu_core_count_alpha "$cpu_core_count"
			if [[ $cpu_core_count -gt 1 ]];then
				cpu_type='-SMP-'
			else
				cpu_type='-UP-'
			fi
		fi
		if [[ -n $cores_per_cpu ]];then
			cpu_physical_count=$(( $cpu_core_count / $cores_per_cpu ))
			if [[ $cores_per_cpu -gt 1 ]];then
				cpu_type='-MCP-'
			fi
		# do not guess here, only use phys count if it actually exists, otherwise handle in print_cpu..
		# this 1 value should not be used for output, and is just to avoid math errors
		else
			cpu_physical_count=1
		fi
		array_data="$cpu_physical_count,$CPU_COUNT_ALPHA,$cpu_type,$cpu_core_count"
		IFS=','
		A_CPU_CORE_DATA=( $array_data )
		IFS="$ORIGINAL_IFS"
	fi
	a_temp=${A_CPU_CORE_DATA[@]}
	# echo $a_temp :: ${#A_CPU_CORE_DATA[@]}
	log_function_data "A_CPU_CORE_DATA: $a_temp"
	eval $LOGFE
}

# args: $1 - integer core count
get_cpu_core_count_alpha()
{
	eval $LOGFS

	case $1 in
		1) CPU_COUNT_ALPHA='Single';;
		2) CPU_COUNT_ALPHA='Dual';;
		3) CPU_COUNT_ALPHA='Triple';;
		4) CPU_COUNT_ALPHA='Quad';;
		5) CPU_COUNT_ALPHA='Penta';;
		6) CPU_COUNT_ALPHA='Hexa';;
		7) CPU_COUNT_ALPHA='Hepta';;
		8) CPU_COUNT_ALPHA='Octa';;
		9) CPU_COUNT_ALPHA='Ennea';;
		10) CPU_COUNT_ALPHA='Deca';;
		*) CPU_COUNT_ALPHA='Multi';;
	esac
	log_function_data "CPU_COUNT_ALPHA: $CPU_COUNT_ALPHA"
	
	eval $LOGFE
}

## main cpu data collector
get_cpu_data()
{
	eval $LOGFS
	local i='' j='' cpu_array_nu='' a_cpu_working='' multi_cpu='' bits='' a_temp=''
	local bsd_cpu_flags='' min_speed='' max_speed=''
	
	if [[ -f  /sys/devices/system/cpu/cpu0/cpufreq/cpuinfo_max_freq ]];then
		max_speed=$(cat /sys/devices/system/cpu/cpu0/cpufreq/cpuinfo_max_freq)
		if [[ -f  /sys/devices/system/cpu/cpu0/cpufreq/cpuinfo_min_freq ]];then
			min_speed=$(cat /sys/devices/system/cpu/cpu0/cpufreq/cpuinfo_min_freq)
		fi
	fi

	if [[ $B_CPUINFO_FILE == 'true' ]];then
		# stop script for a bit to let cpu slow down before parsing cpu /proc file
		sleep $CPU_SLEEP
		IFS=$'\n'
		A_CPU_DATA=( $( 
		gawk -v cpuMin="$min_speed" -v cpuMax="$max_speed" -F': ' '
		BEGIN {
			IGNORECASE=1
			# need to prime nr for arm cpus, which do not have processor number output in some cases
			nr = 0
			count = 0
			bArm = "false"
			bProcInt = "false" # this will avoid certain double counts with processor/Processor lines
			# ARM cpus are erratic in /proc/cpuinfo this hack can sometimes resolve it. Linux only.
			sysSpeed="'$(get_cpu_speed_hack)'"
			speed = 0
			max = 0
			min = 0
			type=""
			family=""
			model_nu=""
			rev=""
		}
		# TAKE STRONGER NOTE: \t+ does NOT always work, MUST be [ \t]+
		# TAKE NOTE: \t+ will work for $FILE_CPUINFO, but SOME ARBITRARY FILE used for TESTING might contain SPACES!
		# Therefore PATCH to use [ \t]+ when TESTING!
		/^processor[ \t]+:/ {
			gsub(/'"$BAN_LIST_ARRAY"'/, " ", $NF)
			gsub(/^ +| +$/, "", $NF)
			if ( $NF ~ "^[0-9]+$" ) {
				nr = $NF
				bProcInt = "true"
			}
			else {
				# this protects against double processor lines, one int, one string
				if ( bProcInt == "false" ){
					count += 1
					nr = count - 1
				}
				# note: alternate: 
				# Processor	: AArch64 Processor rev 4 (aarch64)
				# but no model name type
				if ( $NF ~ "(ARM|AArch)" ) {
					bArm = "true"
					if ( type=""){
						type="arm"
					}
				}
				gsub(/'"$BAN_LIST_NORMAL"'/, "", $NF )
				gsub(/'"$BAN_LIST_CPU"'/, "", $NF )
				gsub(/^ +| +$/, "", $NF)
				gsub(/ [ \t]+/, " ", $NF)
				cpu[nr, "model"] = $NF
			}
		}
		# arm 
		/^cpu architecture/ && (family = "") {
			gsub(/^ +| +$/, "", $NF)
			family=$NF
		}
		/^cpu family/ && ( family == ""){
			gsub(/^ +| +$/, "", $NF)
			family=toupper( sprintf("%x", $NF) )
		}
		/^(stepping|cpu revission)/ && ( rev == "" ){
			gsub(/^ +| +$/, "", $NF)
			rev=$NF
		}
		/^model[ \t]*:/ && ( model_nu == ""){
			gsub(/^ +| +$/, "", $NF)
			model_nu=toupper( sprintf("%x", $NF) )
		}
		/^model name|^cpu\t+:/ {
			gsub(/'"$BAN_LIST_NORMAL"'/, "", $NF )
			gsub(/'"$BAN_LIST_CPU"'/, "", $NF )
			gsub(/'"$BAN_LIST_ARRAY"'/, " ", $NF)
			gsub(/^ +| +$/, "", $NF)
			gsub(/ [ \t]+/, " ", $NF)
			cpu[nr, "model"] = $NF
			if ( $NF ~ "^(ARM|AArch)" ) {
				bArm = "true"
			}
		}
		/^cpu MHz|^clock\t+:/ {
			if (speed == 0) {
				speed = $NF
			}
			else {
				if ($NF < speed) {
					speed = $NF
				}
			}
			if ($NF > max) {
				max = $NF
			}
			gsub(/MHZ/,"",$NF) ## clears out for cell cpu
			gsub(/.00[0]+$/,".00",$NF) ## clears out excessive zeros
			cpu[nr, "speed"] = $NF
		}
		/^cache size/ {
			cpu[nr, "cache"] = $NF
		}
		/^flags|^features/ {
			cpu[nr, "flags"] = $NF
			# not all ARM cpus show ARM in model name
			if ( $1 ~ /^features/ ) {
				bArm = "true"
			}
		}
		/^bogomips/ {
			cpu[nr, "bogomips"] = $NF
			# print nr " " cpu[nr, "bogomips"] > "/dev/tty"
		}
		/vendor_id/ {
			gsub(/genuine|authentic/,"",$NF)
			cpu[nr, "vendor"] = tolower( $NF )
			if ( type == ""){
				if ( $NF ~ /.*intel.*/ ) {
					type="intel"
				}
				else if ($NF ~ /.*amd.*/){
					type="amd"
				}
				# via
				else if ($NF ~ /.*centaur.*/){
					type="centaur"
				}
			}
		}
		END {
			#if (!nr) { print ",,,"; exit } # <- should this be necessary or should bash handle that
			for ( i = 0; i <= nr; i++ ) {
				# note: assuming bogomips for arm at 1 x clock
				# http://en.wikipedia.org/wiki/BogoMips ARM could change so watch this
				# maybe add:  && bArm == "true" but I think most of the bogomips roughly equal cpu speed if not amd/intel
				# 2014-04-08: trying to use sysSpeed hack first, that is more accurate anyway.
				if ( ( cpu[i, "speed"] == "" && sysSpeed != "" ) || \
				( cpu[i, "speed"] == "" && cpu[i, "bogomips"] != "" && cpu[i, "bogomips"] < 50  ) ) {
					cpu[i, "speed"] = sysSpeed
				}
				else if ( cpu[i, "bogomips"] != "" && cpu[i, "speed"] == "" ) {
					cpu[i, "speed"] = cpu[i, "bogomips"]
					
				}
				print cpu[i, "model"] "," cpu[i, "speed"] "," cpu[i, "cache"] "," cpu[i, "flags"] "," cpu[i, "bogomips"] ","  cpu[nr, "vendor"] "," bArm
			}
			if (cpuMin != "") {
				min=cpuMin/1000
			}
			if (cpuMax != "") {
				max=cpuMax/1000
			}
			# create last array index, to be used for min/max output
			sub(/\.[0-9]+$/,"",max)
			sub(/\.[0-9]+$/,"",speed)
			sub(/\.[0-9]+$/,"",min)
			if ( bArm == "true" ){
				type = "arm"
			}
			if (speed == 0) {
				print "N/A," min "," max "," type "," family "," model_nu
			}
			else {
				# print speed "," min "," max  "," type "," family "," model_nu "," rev > "/dev/tty"
				print speed "," min "," max  "," type "," family "," model_nu "," rev
			}
		} 
		' $FILE_CPUINFO ) )
		
 		IFS="$ORIGINAL_IFS"
		log_function_data 'cat' "$FILE_CPUINFO"
	elif [[ -n $BSD_TYPE ]];then
		get_cpu_data_bsd
	fi
	
	a_temp=${A_CPU_DATA[@]}
	log_function_data "A_CPU_DATA: $a_temp"
# 	echo ta: ${a_temp[@]}
	eval $LOGFE
# 	echo getMainCpu: ${[@]}
}
# this triggers in one and only one case, ARM cpus that have fake bogomips data
get_cpu_speed_hack()
{
	local speed=$( cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_cur_freq 2>/dev/null )
	
	if [[ -n $speed ]];then
		speed=${speed%[0-9][0-9][0-9]} # trim off last 3 digits
	fi
	echo $speed
}

get_cpu_data_bsd()
{
	eval $LOGFS

	local bsd_cpu_flags=$( get_cpu_flags_bsd )
	local gawk_fs=': ' cpu_max=''
	
	if [[ $BSD_VERSION == 'openbsd' ]];then
		gawk_fs='='
	fi
	# avoid setting this for systems where you have no read/execute permissions
	# might be cases where the dmesg boot file was readable but sysctl perms failed
	if [[ -n $SYSCTL_A_DATA || -n $bsd_cpu_flags ]];then
		if [[ -n $DMESG_BOOT_DATA ]];then
			cpu_max=$( gawk -F ':' '
			BEGIN {
				IGNORECASE=1
			}
			# NOTE: freebsd may say: 2300-MHz, so check for dash as well
			$1 ~ /^(CPU|cpu0)$/ {
				if ( $NF ~ /[^0-9\.][0-9\.]+[\-[:space:]]*[MG]Hz/) {
					max=gensub(/.*[^0-9\.]([0-9\.]+[\-[:space:]]*[MG]Hz).*/,"\\1",1,$NF)
					if (max ~ /MHz/) {
						sub(/[-[:space:]]*MHz/,"",max)
					}
					if (max ~ /GHz/) {
						sub(/[-[:space:]]*GHz/,"",max)
						max=max*1000
					}
					print max
					exit
				}
			}' <<< "$DMESG_BOOT_DATA" )
		fi
		IFS=$'\n'
		A_CPU_DATA=( $( 
		gawk -F "$gawk_fs" -v bsdVersion=$BSD_VERSION -v cpuFlags="$bsd_cpu_flags" -v cpuMax="$cpu_max" '
		BEGIN {
			IGNORECASE=1
			cpuModel=""
			cpuClock=""
			cpuCache=""
			cpuBogomips=""
			cpuVendor=""
			bSwitchFs="false"
			min=0
			max=0
			# these can be found in dmesg.boot just like in cpuinfo except all in one row
			type="" 
			family=""
			model_nu=""
			rev=""
		}
		/^hw.model/ && ( bsdVersion != "darwin" ) {
			gsub(/'"$BAN_LIST_NORMAL"'/, "", $NF )
			gsub(/'"$BAN_LIST_CPU"'/, "", $NF )
			gsub(/'"$BAN_LIST_ARRAY"'/," ",$NF)
			sub(/[a-z]+-core/, "", $NF )
			gsub(/^ +| +$|\"/, "", $NF)
			gsub(/ [ \t]+/, " ", $NF)
			# cut L2 cache/cpu max speed out of model string, if available
			if ( $NF ~ /[0-9]+[[:space:]]*[KM]B[[:space:]]+L2 cache/) {
				cpuCache=gensub(/.*[^0-9]([0-9]+[[:space:]]*[KM]B)[[:space:]]+L2 cach.*/,"\\1",1,$NF)
			}
			if ( $NF ~ /[^0-9\.][0-9\.]+[\-[:space:]]*[MG]Hz/) {
				max=gensub(/.*[^0-9\.]([0-9\.]+[\-[:space:]]*[MG]Hz).*/,"\\1",1,$NF)
				if (max ~ /MHz/) {
					sub(/[\-[:space:]]*MHz/,"",max)
				}
				if (max ~ /GHz/) {
					sub(/[\-[:space:]]*GHz/,"",max)
					max=max*1000
				}
			}
			if ( $NF ~ /\)$/ ){
				sub(/[[:space:]]*\(.*\)$/,"",$NF)
			}
			cpuModel=$NF
# 			if ( cpuClock != "" ) {
# 				exit
# 			}
		}
		/^hw.clock/ {
			cpuClock=$NF
# 			if ( cpuModel != "" ) {
# 				exit
# 			}
		}
		/^hw.cpufrequency/ {
			cpuClock = $NF / 1000000
		}
		/^hw.cpuspeed/ {
			cpuClock=$NF
		}
		/^hw.l2cachesize/ {
			cpuCache=$NF/1024
			cpuCache=cpuCache " kB"
		}
		/^machdep.cpu.vendor/ {
			cpuVendor=$NF
		}
		# Freebsd does some voltage hacking to actually run at lowest listed frequencies.
		# The cpu does not actually support all the speeds output here but works in freebsd. 
		/^dev.cpu.0.freq_levels/ {
			gsub(/^[[:space:]]+|\/[0-9]+|[[:space:]]+$/,"",$NF)
			if ( $NF ~ /[0-9]+[[:space:]]+[0-9]+/ ) {
				min=gensub(/.*[[:space:]]([0-9]+)$/,"\\1",1,$NF)
				max=gensub(/^([0-9]+)[[:space:]].*/,"\\1",1,$NF)
			}
		}
		/^machdep.cpu.brand_string/ {
			gsub(/'"$BAN_LIST_NORMAL"'/, "", $NF )
			gsub(/'"$BAN_LIST_CPU"'/, "", $NF )
			gsub(/'"$BAN_LIST_ARRAY"'/," ",$NF)
			sub(/[a-z]+-core/, "", $NF )
			gsub(/^ +| +$|\"/, "", $NF)
			gsub(/ [ \t]+/, " ", $NF)
			sub(/[[:space:]]*@.*/,"",$NF)
			cpuModel=$NF
		}
		END {
			if ( max == 0 && cpuMax != "" ) {
				max=cpuMax
			}
			if ( cpuClock == "" ) {
				cpuClock="N/A"
			}
			sub(/\.[0-9]+/,"",cpuClock)
			sub(/\.[0-9]+/,"",min)
			sub(/\.[0-9]+/,"",max)
			print cpuModel "," cpuClock "," cpuCache "," cpuFlags "," cpuBogomips ","  cpuVendor
			# triggers print case, for architecture, check source for syntax
			print cpuClock "," min "," max ",,,," 
		}' <<< "$SYSCTL_A_DATA" ) )
		IFS="$ORIGINAL_IFS"
	fi
	
	eval $LOGFE
}

get_cpu_flags_bsd()
{
	eval $LOGFS
	
	local cpu_flags=''
	local gawk_fs=':'
	
	if [[ -n $DMESG_BOOT_DATA ]];then
		cpu_flags=$( gawk -v bsdVersion="$BSD_VERSION" -F ":" '
		BEGIN {
			IGNORECASE=1
			cpuFlags=""
		}
		/^(CPU:|cpu0:)/ {
			while ( getline && !/memory|real mem/  ) {
				if ( $1 ~ /Features/ || ( bsdVersion == "openbsd" && $0 ~ /^cpu0.*[[:space:]][a-z][a-z][a-z][[:space:]][a-z][a-z][a-z][[:space:]]/ ) ) {
					# clean up odd stuff like <b23>
					gsub(/<[a-z0-9]+>/,"", $2)
					# all the flags are contained within < ... > on freebsd at least
					gsub(/.*<|>.*/,"", $2)
					gsub(/'"$BAN_LIST_ARRAY"'/," ", $2)
					cpuFlags = cpuFlags " " $2
				}
			}
			cpuFlags=tolower(cpuFlags)
			print cpuFlags
			exit
		}' <<< "$DMESG_BOOT_DATA" )
	elif [[ -n $SYSCTL_A_DATA ]];then
		if [[ $BSD_VERSION == 'openbsd' ]];then
			gawk_fs=':'
		fi
		cpu_flags=$( gawk -F "$gawk_fs" '
		BEGIN {
			cpuFlags=""
		}
		/^machdep.cpu.features/ {
			cpuFlags=tolower($NF)
			print cpuFlags
			exit
		}' <<< "$SYSCTL_A_DATA" )
	fi
	echo $cpu_flags
	log_function_data "$cpu_flags"
	eval $LOGFE
}

## this is for counting processors and finding HT types
get_cpu_ht_multicore_smp_data()
{
	eval $LOGFS
	# in /proc/cpuinfo
	local a_temp=''
	
	# note: known bug with xeon intel, they show a_core_id/physical_id as 0 for ht 4 core
	if [[ $B_CPUINFO_FILE == 'true' ]]; then
		A_CPU_TYPE_PCNT_CCNT=( $(
		gawk '
		BEGIN {
			FS=": "
			IGNORECASE = 1
			num_of_cores = 0
			num_of_processors = 0
			num_of_physical_cpus = 0
			cpu_core_count = 0
			siblings = 0
			# these 3 arrays cannot be declared because that sets the first element
			# but leaving this here so that we avoid doing that in the future
			# a_core_id = ""
			# a_processor_id = ""
			# a_physical_id = ""
			cpu_type = "-"
			# note: we need separate iterators because some cpuinfo data has only
			# processor, no core id or phys id
			proc_iter = 0
			core_iter = "" # set from actual NF data
			phys_iter = "" # set from actual NF data
			# needed to handle arm cpu, no processor number cases
			arm_count = 0
			nr = 0
			bArm = "false"
			bProcInt = "false" # this will avoid certain double counts with processor/Processor lines
			bXeon = "false"
		}
		# hack to handle xeons which can have buggy /proc/cpuinfo files
		/^model name/ && ( $0 ~ /Xeon/ ) {
			bXeon = "true"
		}
		# only do this once since sibling count does not change. 
		/^siblings/ && ( bXeon == "true" ) && ( siblings == 0 ) {
			gsub(/[^0-9]/,"",$NF)
			if ( $NF != "" ) {
				siblings = $NF
			}
		}
		# array of logical processors, both HT and physical
		# IMPORTANT: some variants have two lines, one the actual cpu id number,
		# the other a misnamed model name line.
		# processor : 0 
		# Processor : AArch64 Processor rev 4 (aarch64)
		/^processor/ {
			gsub(/'"$BAN_LIST_ARRAY"'/, " ", $NF)
			gsub(/^ +| +$/, "", $NF)
			if ( $NF ~ "^[0-9]+$" ) {
				a_processor_id[proc_iter] = $NF
				proc_iter++
				bProcInt = "true"
			}
			else {
				# note, for dual core, this can be off by one because the first
				# line says: Processor : Arm.. but subsequent say: processor : 0 and so on as usual
				# Processor	: AArch64 Processor rev 4 (aarch64)
				if ( $NF ~ "^(ARM|AArch)" ) {
					bArm = "true"
				}
				# this protects against double processor lines, one int, one string
				if ( bProcInt == "false" ){
					arm_count += 1
					nr = arm_count - 1
					# note: do not iterate because new ARM syntax puts cpu in processsor : 0 syntax
					a_processor_id[proc_iter] = nr
				}
			}
		}
		# array of physical cpu ids, note, this will be unset for vm cpus in many cases
		# because they have no physical cpu, so we cannot assume this will be here.
		/^physical/ {
			phys_iter = $NF
			a_physical_id[phys_iter] = $NF
		}
		# array of core ids, again, here we may have HT, so we need to create an array of the
		# actual core ids. As With physical, we cannot assume this will be here in a vm
		/^core id/ {
			core_iter = $NF
			a_core_id[core_iter] = $NF
		}
		# this will be used to fix an intel glitch if needed, cause, intel
		# sometimes reports core id as the same number for each core, 
		# so if cpu cores shows greater value than number of cores, use this. 
		/^cpu cores/ {
			cpu_core_count = $NF
		}
		END {
			## 	Look thru the array and filter same numbers.
			##	only unique numbers required
			## 	this is to get an accurate count
			##	we are only concerned with array length
			i = 0
			## count unique processors ##
			# note, this fails for intel cpus at times
			for ( i in a_processor_id ) {
				num_of_processors++
			}
			i = 0
			## count unique physical cpus ##
			for ( i in a_physical_id ) {
				num_of_physical_cpus++
			}
			i = 0
			## count unique cores ##
			for ( i in a_core_id ) {
				num_of_cores++
			}
			# xeon may show wrong core / physical id count, if it does, fix it. A xeon
			# may show a repeated core id : 0 which gives a fake num_of_cores=1
			if ( bXeon == "true" && num_of_cores == 1 && siblings > 1 ) {
				num_of_cores = siblings/2
			}
			# final check, override the num of cores value if it clearly is wrong
			# and use the raw core count and synthesize the total instead of real count
			if ( ( num_of_cores == 0 ) && ( cpu_core_count * num_of_physical_cpus > 1 ) ) {
				num_of_cores = cpu_core_count * num_of_physical_cpus
			}
			# last check, seeing some intel cpus and vms with intel cpus that do not show any
			# core id data at all, or siblings.
			if ( num_of_cores == 0 && num_of_processors > 0 ) {
				num_of_cores = num_of_processors
			}
			# ARM/vm cpu fix, if no physical or core found, use count of 1 instead
			if ( num_of_physical_cpus == 0 ) {
				num_of_physical_cpus = 1
			}
# 			print "NoCpu: " num_of_physical_cpus
# 			print "NoCores: " num_of_cores
# 			print "NoProc:" num_of_processors
# 			print "CpuCoreCount:" cpu_core_count
			####################################################################
			# 				algorithm
			# if > 1 processor && processor id (physical id) == core id then Hyperthreaded (HT)
			# if > 1 processor && processor id (physical id) != core id then Multi-Core Processors (MCP)
			# if > 1 processor && processor ids (physical id) > 1 then Multiple Processors (SMP)
			# if = 1 processor then single core/processor Uni-Processor (UP)
			if ( num_of_processors > 1 || ( bXeon == "true" && siblings > 0 ) ) {
				# non-multicore HT
				if ( num_of_processors == (num_of_cores * 2) ) {
					cpu_type = cpu_type "HT-"
				}
				else if ( bXeon == "true" && siblings > 1 ) {
					cpu_type = cpu_type "HT-"
				}
				# non-HT multi-core or HT multi-core
				if (( num_of_processors == num_of_cores) || ( num_of_physical_cpus < num_of_cores)) {
					cpu_type = cpu_type "MCP-"
				}
				# >1 cpu sockets active
				if ( num_of_physical_cpus > 1 ) {
					cpu_type = cpu_type "SMP-"
				}
			} 
			else {
				cpu_type = cpu_type "UP-"
			}			
			
			print cpu_type " " num_of_physical_cpus " " num_of_cores 
		}
		' $FILE_CPUINFO ) )
	fi
	a_temp=${A_CPU_TYPE_PCNT_CCNT[@]}
	log_function_data "A_CPU_TYPE_PCNT_CCNT: $a_temp"
	eval $LOGFE
}

# Detect desktop environment in use, initial rough logic from: compiz-check
# http://forlong.blogage.de/entries/pages/Compiz-Check
# NOTE $XDG_CURRENT_DESKTOP envvar is not reliable, but it shows certain desktops better.
# most desktops are not using it as of 2014-01-13 (KDE, UNITY, LXDE. Not Gnome)
get_desktop_environment()
{
	eval $LOGFS
	
	# set the default, this function only runs in X, if null, don't print data out
	local desktop_environment='' xprop_root='' version2=''
	local version='' version_data='' version2_data='' toolkit=''

	# works on 4, assume 5 will id the same, why not, no need to update in future
	# KDE_SESSION_VERSION is the integer version of the desktop
	# NOTE: as of plasma 5, the tool: about-distro MAY be available, that will show
	# actual desktop data, so once that's in debian/ubuntu, if it gets in, add that test
	if [[ $XDG_CURRENT_DESKTOP == 'KDE' || -n $KDE_SESSION_VERSION ]]; then
		# note the command is actually like, kded4 --version, so we construct it
		# this was supposed to extend to 5, but 5 changed it, so it uses the more reliable way
		if [[ $KDE_SESSION_VERSION -le 4 ]];then
			version_data=$( kded$KDE_SESSION_VERSION --version 2>/dev/null )
			version=$( grep -si '^KDE Development Platform:' <<< "$version_data" | gawk '{print $4}' )
		else
			# NOTE: this command string is almost certain to change, and break, with next major plasma desktop, ie, 6
			# version=$( qdbus org.kde.plasmashell /MainApplication org.qtproject.Qt.QCoreApplication.applicationVersion 2>/dev/null )
			#Qt: 5.4.2
			#KDE Frameworks: 5.11.0
			#kf5-config: 1.0
			# for QT, and Frameworks if we use it
			if type -p kf$KDE_SESSION_VERSION-config &>/dev/null;then
				version_data=$( kf$KDE_SESSION_VERSION-config --version 2>/dev/null )
				# version=$( grep -si '^KDE Frameworks:' <<< "$version_data" | gawk '{print $NF}' )
			fi
			# plasmashell 5.3.90
			if type -p plasmashell &>/dev/null;then
				version2_data=$( plasmashell --version 2>/dev/null )
				version=$( grep -si '^plasmashell' <<< "$version2_data" | gawk '{print $NF}' )
			fi
		fi
		if [[ -z $version ]];then
			version=$KDE_SESSION_VERSION
		fi
		if [[ $B_EXTRA_DATA == 'true' && -n $version_data ]];then
			toolkit=$( grep -si '^Qt:' <<< "$version_data" | gawk '{print $2}' )
			if [[ -n $toolkit ]];then
				version="$version (Qt $toolkit)"
			fi
		fi
		desktop_environment="KDE Plasma"
	# KDE_FULL_SESSION property is only available since KDE 3.5.5.
	# src: http://humanreadable.nfshost.com/files/startkde
	elif [[ $KDE_FULL_SESSION == 'true' ]]; then
		version_data=$( kded --version 2>/dev/null )
		version=$( grep -si '^KDE:' <<< "$version_data" | gawk '{print $2}' )
		# version=$( get_program_version 'kded' '^KDE:' '2' )
		if [[ -z $version ]];then
			version='3.5'
		fi
		if [[ $B_EXTRA_DATA == 'true' ]];then
			toolkit=$( grep -si '^Qt:' <<< "$version_data" | gawk '{print $2}' )
			if [[ -n $toolkit ]];then
				version="$version (Qt $toolkit)"
			fi
		fi
		desktop_environment="KDE"
	elif [[ $XDG_CURRENT_DESKTOP == 'Unity' ]];then
		version=$( get_program_version 'unity' '^unity' '2' )
		# not certain will always have version, so keep output right if not
		if [[ -n $version ]];then
			version="$version "
		fi
		if [[ $B_EXTRA_DATA == 'true' ]];then
			toolkit=$( get_de_gtk_data )
			if [[ -n $toolkit ]];then
				version="$version(Gtk $toolkit)"
			fi
		fi
		desktop_environment="Unity"
	elif [[ $XDG_CURRENT_DESKTOP == *Budgie* ]];then
		version=$( get_program_version 'budgie-desktop' '^budgie-desktop' '2' )
		# not certain will always have version, so keep output right if not
		if [[ -n $version ]];then
			version="$version "
		fi
		if [[ $B_EXTRA_DATA == 'true' ]];then
			toolkit=$( get_de_gtk_data )
			if [[ -n $toolkit ]];then
				version="$version(Gtk $toolkit)"
			fi
		fi
		desktop_environment="Budgie"
	elif [[ $XDG_CURRENT_DESKTOP == 'LXQt' ]];then
# 		if type -p lxqt-about &>/dev/null;then
# 			version=$( get_program_version 'lxqt-about' '^lxqt-about' '2' )
# 		fi
		if [[ $B_EXTRA_DATA == 'true' ]];then
			if kded$KDE_SESSION_VERSION &>/dev/null;then
				version_data=$( kded$KDE_SESSION_VERSION --version 2>/dev/null )
				toolkit=$( grep -si '^Qt:' <<< "$version_data" | gawk '{print $2}' )
			elif type -p qtdiag &>/dev/null;then
				toolkit=$( get_program_version 'qtdiag' '^qt' '2' )
			fi
			if [[ -n $toolkit ]];then
				version="$version (Qt $toolkit)"
			fi
		fi
		desktop_environment='LXQt'
	# note, X-Cinnamon value strikes me as highly likely to change, so just search for the last part
	elif [[ -n $XDG_CURRENT_DESKTOP && -z ${XDG_CURRENT_DESKTOP/*innamon*/} ]];then
		version=$( get_program_version 'cinnamon' '^cinnamon' '2' )
		# not certain cinn will always have version, so keep output right if not
		if [[ -n $version ]];then
			version="$version "
		fi
		if [[ $B_EXTRA_DATA == 'true' ]];then
			toolkit=$( get_de_gtk_data )
			if [[ -n $toolkit ]];then
				version="$version(Gtk $toolkit)"
			fi
		fi
		desktop_environment="Cinnamon"
	fi
	# did we find it? If not, start the xprop tests
	if [[ -z $desktop_environment ]];then
		if type -p xprop &>/dev/null;then
			xprop_root="$( xprop -root $DISPLAY_OPT 2>/dev/null | tr '[:upper:]' '[:lower:]' )"
		fi
		# note that cinnamon split from gnome, and and can now be id'ed via xprop,
		# but it will still trigger the next gnome true case, so this needs to go before gnome test
		# eventually this needs to be better organized so all the xprop tests are in the same
		# section, but this is good enough for now.
		if [[ -n $xprop_root && -z ${xprop_root/*_muffin*/} ]];then
			version=$( get_program_version 'cinnamon' '^cinnamon' '2' )
			# not certain cinn will always have version, so keep output right if not
			if [[ -n $version ]];then
				version="$version "
			fi
			if [[ $B_EXTRA_DATA == 'true' ]];then
				toolkit=$( get_de_gtk_data )
				if [[ -n $toolkit ]];then
					version="$version(Gtk $toolkit)"
				fi
			fi
			desktop_environment="Cinnamon"
		elif [[ $XDG_CURRENT_DESKTOP == 'MATE' ]] || [[ -n $xprop_root && -z ${xprop_root/*_marco*/} ]];then
			version=$( get_program_version 'mate-about' '^MATE[[:space:]]DESKTOP' 'NF' )
			# not certain cinn/mate will always have version, so keep output right if not
			if [[ -n $version ]];then
				version="$version "
			fi
			if [[ $B_EXTRA_DATA == 'true' ]];then
				toolkit=$( get_de_gtk_data )
				if [[ -n $toolkit ]];then
					version="$version(Gtk $toolkit)"
				fi
			fi
			desktop_environment="MATE"
		# note, GNOME_DESKTOP_SESSION_ID is deprecated so we'll see how that works out
		# https://bugzilla.gnome.org/show_bug.cgi?id=542880
		elif [[ -n $GNOME_DESKTOP_SESSION_ID || $XDG_CURRENT_DESKTOP == 'GNOME' ]]; then
			if type -p gnome-shell &>/dev/null;then
				version=$( get_program_version 'gnome-shell' 'gnome' '3' )
			elif type -p gnome-about &>/dev/null;then
				version=$( get_program_version 'gnome-about' 'gnome' '3' )
			fi
			if [[ $B_EXTRA_DATA == 'true' ]];then
				toolkit=$( get_de_gtk_data )
				if [[ -n $toolkit ]];then
					version="$version (Gtk $toolkit)"
				fi
			fi
			desktop_environment="Gnome"
		fi
		if [[ -z $desktop_environment ]];then
		# now that the primary ones have been handled, next is to find the ones with unique
		# xprop detections possible
			if [[ -n $xprop_root ]];then
				# String: "This is xfdesktop version 4.2.12"
				# alternate: xfce4-about --version > xfce4-about 4.10.0 (Xfce 4.10)
				if [[ -z ${xprop_root/*\"xfce4\"*/} ]];then
					version=$( get_program_version 'xfdesktop' 'xfdesktop[[:space:]]version' '5' )
					# arch linux reports null, so use alternate if null
					if [[ -z $version ]];then
						version=$( get_program_version 'xfce4-panel' '^xfce4-panel' '2' )
						if [[ -z $version ]];then
							version='4'
						fi
					fi
					if [[ $B_EXTRA_DATA == 'true' ]];then
						toolkit=$( get_program_version 'xfdesktop' 'Built[[:space:]]with[[:space:]]GTK' '4' )
						if [[ -n $toolkit ]];then
							version="$version (Gtk $toolkit)"
						fi
					fi
					desktop_environment="Xfce"
				# when 5 is released, the string may need updating
				elif [[ -z ${xprop_root/*\"xfce5\"*/} ]];then
					version=$( get_program_version 'xfdesktop' 'xfdesktop[[:space:]]version' '5' )
					# arch linux reports null, so use alternate if null
					if [[ -z $version ]];then
						version=$( get_program_version 'xfce5-panel' '^xfce5-panel' '2' )
						if [[ -z $version ]];then
							version='5'
						fi
					fi
					if [[ $B_EXTRA_DATA == 'true' ]];then
						toolkit=$( get_program_version 'xfdesktop' 'Built[[:space:]]with[[:space:]]GTK' '4' )
						if [[ -n $toolkit ]];then
							version="$version (Gtk $toolkit)"
						fi
					fi
					desktop_environment="Xfce"
				# case where no xfce number exists, just xfce
				elif [[ -z ${xprop_root/*xfce*/} ]];then
					version=$( get_program_version 'xfdesktop' 'xfdesktop[[:space:]]version' '5' )
					# arch linux reports null, so use alternate if null
					if [[ -z $version ]];then
						version=$( get_program_version 'xfce4-panel' '^xfce5-panel' '2' )
						if [[ -z $version ]];then
							# version=$( get_program_version 'xfce5-panel' '^xfce5-panel' '2' )
							#if [[ -z $version ]];then
							#	version='5'
							#fi
							version='4'
						fi
					fi
					if [[ $B_EXTRA_DATA == 'true' ]];then
						toolkit=$( get_program_version 'xfdesktop' 'Built[[:space:]]with[[:space:]]GTK' '4' )
						if [[ -n $toolkit ]];then
							version="$version (Gtk $toolkit)"
						fi
					fi
					desktop_environment="Xfce"
				elif [[ -z ${xprop_root/*blackbox_pid*/} ]];then
					if [[ -z "${Ps_aux_Data/*fluxbox*/}" ]];then
						version=$( get_program_version 'fluxbox' '^fluxbox' '2' )
						desktop_environment='Fluxbox'
					else
						desktop_environment='Blackbox'
					fi
				elif [[ -z ${xprop_root/*openbox_pid*/}  ]];then
					# note: openbox-lxde --version may be present, but returns openbox data
					version=$( get_program_version 'openbox' '^openbox' '2' )
					if [[ $XDG_CURRENT_DESKTOP == 'LXDE' || -z "${Ps_aux_Data/*\/lxsession*/}" ]];then
						if [[ -n $version ]];then
							version="(Openbox $version)"
						fi
						desktop_environment='LXDE'
					elif [[  $XDG_CURRENT_DESKTOP == 'Razor' || $XDG_CURRENT_DESKTOP == 'LXQt' ]] || \
						[[ -n $( grep -Es '(razor-desktop|lxqt-session)' <<< "$Ps_aux_Data" ) ]];then
						if [[ -z "${Ps_aux_Data/*lxqt-session*/}" ]];then
							desktop_environment='LXQt'
						elif [[ -z "${Ps_aux_Data/*razor-desktop*/}" ]];then
							desktop_environment='Razor-Qt'
						else
							desktop_environment='LX-Qt-Variant'
						fi
						if [[ -n $version ]];then
							version="(Openbox $version)"
						fi
					else
						desktop_environment='Openbox' 
					fi
				elif [[ -z ${xprop_root/*icewm*/} ]];then
					version=$( get_program_version 'icewm' '^icewm' '2' )
					desktop_environment='IceWM'
				elif [[ -z ${xprop_root/*enlightenment*/} ]];then
					# no -v or --version but version is in xprop -root
					# ENLIGHTENMENT_VERSION(STRING) = "Enlightenment 0.16.999.49898"
					version=$( grep -is 'ENLIGHTENMENT_VERSION' <<< "$xprop_root" | cut -d '"' -f 2 | gawk '{print $2}' )
					desktop_environment='Enlightenment'
				# need to check starts line because it's so short
				elif [[ -n $( grep -s '^i3_' <<< "$xprop_root" ) ]];then
					version=$( get_program_version 'i3' '^i3' '3' )
					desktop_environment='i3'
				elif [[ -z ${xprop_root/*windowmaker*/} ]];then
					version=$( get_program_version 'wmaker' '^Window[[:space:]]*Maker' 'NF' )
					if [[ -n $version ]];then
						version="$version "
					fi
					desktop_environment="WindowMaker"
				# need to check starts line because it's so short
				elif [[ -n $( grep -s '^_wm2' <<< "$xprop_root" ) ]];then
					# note; there isn't actually a wm2 version available but error handling should cover it and return null
					# maybe one day they will add it?
					version=$( get_program_version 'wm2' '^wm2' 'NF' )
					# not certain will always have version, so keep output right if not
					if [[ -n $version ]];then
						version="$version "
					fi
					desktop_environment="WM2"
				elif [[ -z "${xprop_root/*herbstluftwm*/}" ]];then
					version=$( get_program_version 'herbstluftwm' '^herbstluftwm' 'NF' )
					if [[ -n $version ]];then
						version="$version "
					fi
					desktop_environment="herbstluftwm"
				fi
			fi
			# a few manual hacks for things that don't id with xprop, these are just good guesses
			# note that gawk is going to exit after first occurrence of search string, so no need for extra
			# http://www.xwinman.org/ for more possible wm
			if [[ -z $desktop_environment ]];then
				if [[ -z "${Ps_aux_Data/*fvwm-crystal*/}" ]];then
					version=$( get_program_version 'fvwm' '^fvwm' '2' )
					desktop_environment='FVWM-Crystal'
				elif [[ -z "${Ps_aux_Data/*fvwm*/}" ]];then
					version=$( get_program_version 'fvwm' '^fvwm' '2' )
					desktop_environment='FVWM'
				elif [[ -z "${Ps_aux_Data/*pekwm*/}" ]];then
					version=$( get_program_version 'pekwm' '^pekwm' '3' )
					desktop_environment='pekwm'
				elif [[ -z "${Ps_aux_Data/*awesome*/}" ]];then
					version=$( get_program_version 'awesome' '^awesome' '2' )
					desktop_environment='Awesome'
				elif [[ -z "${Ps_aux_Data/*scrotwm*/}" ]];then
					version=$( get_program_version 'scrotwm' '^welcome.*scrotwm' '4' )
					desktop_environment='Scrotwm' # no --version for this one
				elif [[ -z "${Ps_aux_Data/*spectrwm*/}" ]];then
					version=$( get_program_version 'spectrwm' '^spectrwm.*welcome.*spectrwm' '5' )
					desktop_environment='Spectrwm' # no --version for this one
				elif [[ -n $( grep -Es '([[:space:]]|/)twm' <<< "$Ps_aux_Data" ) ]];then
					desktop_environment='Twm' # no --version for this one
				elif [[ -n $( grep -Es '([[:space:]]|/)dwm' <<< "$Ps_aux_Data" ) ]];then
					version=$( get_program_version 'dwm' '^dwm' '1' )
					desktop_environment='dwm'
				elif [[ -z "${Ps_aux_Data/*wmii2*/}" ]];then
					version=$( get_program_version 'wmii2' '^wmii2' '1' )
					desktop_environment='wmii2'
				# note: in debian at least, wmii is actuall wmii3
				elif [[ -z "${Ps_aux_Data/*wmii*/}" ]];then
					version=$( get_program_version 'wmii' '^wmii' '1' )
					desktop_environment='wmii'
				elif [[ -n $( grep -Es '([[:space:]]|/)jwm' <<< "$Ps_aux_Data" ) ]];then
					version=$( get_program_version 'jwm' '^jwm' '2' )
					desktop_environment='JWM'
				elif [[ -z "${Ps_aux_Data/*sawfish*/}" ]];then
					version=$( get_program_version 'sawfish' '^sawfish' '3' )
					desktop_environment='Sawfish'
				elif [[ -z "${Ps_aux_Data/*afterstep*/}" ]];then
					version=$( get_program_version 'afterstep' '^afterstep' '3' )
					desktop_environment='AfterStep'
				fi
			fi
		fi
	fi
	if [[ -n $version ]];then
		version=" $version"
	fi
	log_function_data "desktop_environment version: $desktop_environment$version"
	echo "$desktop_environment$version"
	eval $LOGFE
}

# note: gawk doesn't support white spaces in search string, gave errors, so use [[:space:]] instead
# args: $1 - desktop/app command for --version; $2 - search string; $3 - gawk print number
get_program_version()
{
	local version_data='' version='' get_version='--version' 
	
	# mate-about -v = MATE Desktop Environment 1.4.0
	case $1 in
		# legacy fluxbox had no --version, and current -v works
		dwm|fluxbox|jwm|mate-about|wmii|wmii2)
			get_version='-v'
			;;
		epoch)
			get_version='version'
			;;
	esac
	
	case $1 in
		# note, some wm/apps send version info to stderr instead of stdout
		dwm|ksh|scrotwm|spectrwm)
			version_data="$( $1 $get_version 2>&1 )"
			;;
		csh)
			version_data="$( tcsh $get_version 2>/dev/null )"
			;;
		# quick debian/buntu hack until I find a universal way to get version for these
		dash)
			if type -p dpkg &>/dev/null;then
				version_data="$( dpkg -l $1 2>/dev/null )"
			fi
			;;
		*)
			version_data="$( $1 $get_version 2>/dev/null )"
			;;
	esac
	log_function_data "version data: $version_data"
	if [[ -n $version_data ]];then
		version=$( gawk '
		BEGIN {
			IGNORECASE=1
		}
		/'$2'/ {
			# sample: dwm-5.8.2, ©.. etc, why no space? who knows. Also get rid of v in number string
			# xfce, and other, output has , in it, so dump all commas and parentheses
			gsub(/(,|dwm-|wmii2-|wmii-|v|V|\(|\))/, "",$'$3') 
			print $'$3'
			exit # quit after first match prints
		}' <<< "$version_data" )
	fi
	log_function_data "program version: $version"
	echo $version
}

get_desktop_extra_data()
{
	eval $LOGFS
	local de_data=$( ps -A | gawk '
	BEGIN {
		IGNORECASE=1
		desktops=""
		separator=""
	}
	/(gnome-shell|gnome-panel|kicker|lxpanel|mate-panel|plasma-desktop|plasma-netbook|xfce4-panel)$/ {
		# only one entry per type, can be multiple
		if ( desktops !~ $NF ) {
			desktops = desktops separator $NF
			separator = ","
		}
	}
	END {
		print desktops
	}
	' )
	log_function_data "de_data: $de_data"
	echo $de_data
	
	eval $LOGFE
}

get_de_gtk_data()
{
	eval $LOGFS
	
	local toolkit=''
	
	# this is a hack, and has to be changed with every toolkit version change, and only dev systems
	# have this installed, but it's a cross distro command so let's test it first
	if type -p pkg-config &>/dev/null;then
		toolkit=$( pkg-config --modversion gtk+-4.0 2>/dev/null )
		# note: opensuse gets null output here, we need the command to get version and output sample
		if [[ -z $toolkit ]];then
			toolkit=$( pkg-config --modversion gtk+-3.0 2>/dev/null )
		fi
		if [[ -z $toolkit ]];then
			toolkit=$( pkg-config --modversion gtk+-2.0 2>/dev/null )
		fi
	fi
	# now let's go to more specific version tests, this will never cover everything and that's fine.
	if [[ -z $toolkit ]];then
		# we'll try some known package managers next. dpkg will handle a lot of distros 
		# this is the most likely order as of: 2014-01-13. Not going to try to support all package managers
		# too much work, just the very biggest ones.
		if type -p dpkg &>/dev/null;then
			toolkit=$( dpkg -s libgtk-3-0 2>/dev/null | gawk -F ':' '/^[[:space:]]*Version/ {print $2}' )
			# just guessing on gkt 4 package name
			if [[ -z $toolkit ]];then
				toolkit=$( dpkg -s libgtk-4-0 2>/dev/null | gawk -F ':' '/^[[:space:]]*Version/ {print $2}' )
			fi
			if [[ -z $toolkit ]];then
				toolkit=$( dpkg -s libgtk2.0-0 2>/dev/null | gawk -F ':' '/^[[:space:]]*Version/ {print $2}' )
			fi
		elif type -p pacman &>/dev/null;then
			toolkit=$(  pacman -Qi gtk3 2>/dev/null | gawk -F ':' '/^[[:space:]]*Version/ {print $2}' )
			# just guessing on gkt 4 package name
			if [[ -z $toolkit ]];then
				toolkit=$( pacman -Qi gtk4 2>/dev/null | gawk -F ':' '/^[[:space:]]*Version/ {print $2}' )
			fi
			if [[ -z $toolkit ]];then
				toolkit=$( pacman -Qi gtk2 2>/dev/null | gawk -F ':' '/^[[:space:]]*Version/ {print $2}' )
			fi
		# Name        : libgtk-3-0
		# Version     : 3.12.2
		elif type -p rpm &>/dev/null;then
			toolkit=$( rpm -qi libgtk-3-0 2>/dev/null | gawk -F ':' '
			/^[[:space:]]*Version/ { 
				gsub(/^[[:space:]]+|[[:space:]]+$/,"",$2)
				print $2 
			}' )
			if [[ -z $toolkit ]];then
				toolkit=$( rpm -qi libgtk-4-0 2>/dev/null | gawk -F ':' '
				/^[[:space:]]*Version/ {
					gsub(/^[[:space:]]+|[[:space:]]+$/,"",$2)
					print $2
				}' )
			fi
			if [[ -z $toolkit ]];then
				toolkit=$( rpm -qi libgtk-2-0 2>/dev/null | gawk -F ':' '
				/^[[:space:]]*Version/ {
					gsub(/^[[:space:]]+|[[:space:]]+$/,"",$2)
					print $2
				}' )
			fi
		fi
	fi
	log_function_data "toolkit: $toolkit"
	echo $toolkit
	
	eval $LOGFE
}

get_device_data()
{
	eval $LOGFS
	
	local device='un-determined'
	local chasis_id='' dmi_device=''
	
	# first: linked version
	if [[ -e /sys/class/dmi/id/chassis_type ]];then
		chasis_id=$(cat /sys/class/dmi/id/chassis_type)
	elif [[ -e /sys/devices/virtual/dmi/id/chassis_type ]];then
		chasis_id=$(cat /sys/devices/virtual/dmi/id/chassis_type)
	fi
	# src: http://www.dmtf.org/sites/default/files/standards/documents/DSP0134_2.7.0.pdf
	# https://www.404techsupport.com/2012/03/pizza-box-lunch-box-and-other-pc-case-form-factors-identified-by-wmi/
	if [[ $chasis_id != '' ]];then
		case $chasis_id in
			1)
				device=$(get_device_vm)
				;;
			2)
				device='unknown'
				;;
			# note: 13 is all-in-one which we take as a mac type system
			3|4|6|7|13|15|24)
				device='desktop'
				;;
			# 5 - pizza box was a 1 U desktop enclosure, but some old laptops also id this way
			5)
				device='pizza-box'
				;;
			# note: lenovo T420 shows as 10, notebook,  but it's not a notebook
			9|10|16)
				device='laptop'
				;;
			14)
				device='notebook'
				;;
			8|11)
				device='portable'
				;;
			17|23|25)
				device='server'
				;;
			27|28|29)
				device='blade'
				;;
			12)
				device='docking-station'
				;;
			18)
				device='expansion-chassis'
				;;
			19)
				device='sub-chassis'
				;;
			20)
				device='bus-expansion'
				;;
			21)
				device='peripheral'
				;;
			22)
				device='RAID'
				;;
			26)
				device='compact-PCI'
				;;
		esac
	else
		if ! type -p dmidecode &>/dev/null;then
			device='dmidecode-missing'
		elif [[ $B_ROOT == 'false' ]];then
			device='dmidecode-use-root'
		else 
			get_dmidecode_data
			if [[ -n $DMIDECODE_DATA ]];then
				if [[ $DMIDECODE_DATA == 'dmidecode-error-'* ]];then
					device='dmidecode-no-info'
				else
					dmi_device=$( gawk '
					BEGIN {
						IGNORECASE=1
						device="test"
					}
					/^Chassis Information/ {
						device= $1
						while (getline && !/^$/ ) {
							if ( $1 ~ /^Type/ ) {
								sub(/Type:\s*/,"",$0)
								device = $0
								break
							}
						}
					}
					END {
						print device
					}' <<< "$DMIDECODE_DATA" )
					if [[ -n $dmi_device ]];then
						device=$dmi_device
					fi
					if [[ $device == 'Other' ]];then
						device=$(get_device_vm)
					fi
				fi
			fi
		fi
	fi
	echo $device
	
	eval $LOGFE
}

get_device_vm()
{
	eval $LOGFS
	
	local vm='other-vm?' vm_data='' vm_test=''
	
	# https://www.freedesktop.org/software/systemd/man/systemd-detect-virt.html
	# note: returns bosh for qemu-kvm so if that's the result, let the other tests 
	# run
	if type -p systemd-detect-virt &>/dev/null;then
		vm_test=$(systemd-detect-virt 2>/dev/null | sed 's/none//' )
		if [[ -n $vm_test && $vm_test != 'none' ]];then
			vm=$vm_test
		fi
	fi
	# some simple to detect linux vm id's
	if [[ $vm == 'other-vm?' || $vm == 'bochs' ]];then
		if [[ -e /proc/vz ]];then
			vm='openvz'
		elif [[ -e /proc/xen ]];then
			vm='xen'
		elif [[ -e /dev/vzfs ]];then
			vm='virtuozzo'
		elif type -p lsmod &>/dev/null;then
			vm_data="$( lsmod 2>/dev/null )"
			if [[  -n $( grep -i 'kqemu' <<< "$vm_data" ) ]];then
				vm='kqemu'
			elif [[ -n $( grep -i 'kvm' <<< "$vm_data" ) ]];then
				vm='kvm'
			elif [[ -n $( grep -i 'qemu' <<< "$vm_data" ) ]];then
				vm='qemu'
			fi
			vm_data=''
		fi
	fi
	# this will catch many Linux systems and some BSDs
	if [[ $vm == 'other-vm?' || $vm == 'bochs' ]];then
		vm_data=$vm_data$LSPCI_V_DATA
		vm_data=$vm_data$SYSCTL_A_DATA
		vm_data=$vm_data$DMESG_BOOT_DATA
		if [[ -e /dev/disk/by-id ]];then
			vm_data=$vm_data$(ls -l /dev/disk/by-id 2>/dev/null )
		fi
		if [[ -n $( grep -iEs 'innotek|vbox|virtualbox' <<< $vm_data ) ]];then
			vm='virtualbox'
		elif [[ -n $( grep -is 'vmware' <<< $vm_data ) ]];then
			vm='vmware'
		elif [[ -n $( grep -is 'qemu' <<< $vm_data ) ]];then
			vm='qemu-or-kvm'
		elif [[ -n $( grep -s 'Virtual HD' <<< $vm_data ) ]];then
			vm='hyper-v'
		elif [[ -e /proc/cpuinfo && -n $( grep -is '^flags.*hypervisor' /proc/cpuinfo ) ]];then
			vm='virtual-machine'
		elif [[ -e /dev/vda || -e /dev/vdb || -e /dev/xvda || -e /dev/xvdb ]];then
			vm='virtual-machine'
		fi
	fi
	# this may catch some BSD and fringe Linux cases
	if [[ $vm == 'other-vm?' && $B_ROOT == 'true' ]];then
		if [[ -n $DMIDECODE_DATA && $DMIDECODE_DATA != 'dmidecode-error-'* ]];then
			product_name=$(dmidecode -s system-product-name 2>/dev/null )
			system_manufacturer=$( dmidecode -s system-manufacturer 2>/dev/null )
			if [[ $product_name == 'VMware'* ]];then
				vm='vmware'
			elif [[ $product_name == 'VirtualBox'* ]];then
				vm='virtualbox'
			elif [[ $product_name == 'KVM'* ]];then
				vm='kvm'
			elif [[ $product_name == 'Bochs'* ]];then
				vm='qemu'
			elif [[ $system_manufacturer == 'Xen' ]];then
				vm='xen'
			elif [[ -n $( grep -i 'hypervisor' <<< "$DMIDECODE_DATA" ) ]];then
				vm='virtual-machine'
			fi
		fi
	fi
	
	echo $vm
	
	eval $LOGFE
}

# see which dm has started if any
get_display_manager()
{
	eval $LOGFS
	# ldm - LTSP display manager. Note that sddm does not appear to have a .pid extension in Arch
	# note: to avoid positives with directories, test for -f explicitly, not -e
	local dm_id_list='entranced.pid gdm.pid gdm3.pid kdm.pid ldm.pid lightdm.pid lxdm.pid mdm.pid nodm.pid sddm.pid sddm slim.lock tint2.pid wdm.pid xdm.pid' 
	local dm_id='' dm='' separator=''
	# note we don't need to filter grep if we do it this way
	local x_is_running=$( grep '/usr.*/X' <<< "$Ps_aux_Data" | grep -iv '/Xprt' )

	for dm_id in $dm_id_list
	do
		# note: ${dm_id%.*}/$dm_id will create a dir name out of the dm id, then test if pid is in that
		# note: sddm, in an effort to be unique and special, do not use a pid/lock file, but rather a random
		# string inside a directory called /run/sddm/ so assuming the existence of the pid inside a directory named
		# from the dm. Hopefully this change will not have negative results.
		if [[ -f /run/$dm_id || -d /run/${dm_id%.*}/ || -f /var/run/$dm_id || \
		      -d /var/run/${dm_id%.*}/ ]];then
			# just on the off chance that two dms are running, good info to have in that case, if possible
			dm=$dm$separator${dm_id%.*}
			separator=','
		fi
	done
	# might add this in, but the rate of new dm's makes it more likely it's an unknown dm, so
	# we'll keep output to N/A
	if [[ -n $x_is_running && -z $dm ]];then
		if [[ -z "${Ps_aux_Data/*startx*/}" ]];then
			dm='(startx)'
		fi
	fi
	echo $dm

	log_function_data "display manager: $dm"

	eval $LOGFE
}

# for more on distro id, please reference this python thread: http://bugs.python.org/issue1322
## return distro name/id if found
get_distro_data()
{
	eval $LOGFS
	local i='' j='' distro='' distro_file='' a_distro_glob='' a_temp='' b_osr='false'
	
	# may need modification if archbsd / debian can be id'ed with /etc files
	if [[ -n $BSD_TYPE ]];then
		if [[ $BSD_VERSION != 'darwin' ]];then
			distro=$( uname -sr )
		else
			if [[ -f /System/Library/CoreServices/SystemVersion.plist ]];then
				distro=$( grep -A1 -E '(ProductName|ProductVersion)' /System/Library/CoreServices/SystemVersion.plist  | grep '<string>' | sed -E 's/<[\/]?string>//g' )
				distro=$( echo $distro )
			fi
			if [[ -z $distro ]];then
				distro='Mac OS X'
			fi
		fi
		echo "$distro"
		log_function_data "distro: $distro"
		eval $LOGFE
		return 0
	fi

	# get the wild carded array of release/version /etc files if present
	shopt -s nullglob
	cd /etc
	# note: always exceptions, so wild card after release/version: /etc/lsb-release-crunchbang
	# wait to handle since crunchbang file is one of the few in the world that uses this method
	a_distro_glob=(*[-_]{release,version})
	cd "$OLDPWD"
	shopt -u nullglob
	
	a_temp=${a_distro_glob[@]}
	log_function_data "a_distro_glob: $a_temp"

	if [[ ${#a_distro_glob[@]} -eq 1 ]];then
		distro_file="$a_distro_glob"
	# use the file if it's in the known good lists
	elif [[ ${#a_distro_glob[@]} -gt 1 ]];then
		for i in $DISTROS_DERIVED $DISTROS_PRIMARY
		do
			# Only echo works with ${var[@]}, not print_screen_output() or script_debugger()
			# This is a known bug, search for the word "strange" inside comments
			# echo "i='$i' a_distro_glob[@]='${a_distro_glob[@]}'"
			if [[ " ${a_distro_glob[@]} " == *" $i "* ]];then
				# Now lets see if the distro file is in the known-good working-lsb-list
				# if so, use lsb-release, if not, then just use the found file
				# this is for only those distro's with self named release/version files
				# because Mint does not use such, it must be done as below 
				## this if statement requires the spaces and * as it is, else it won't work
				##
				if [[ " $DISTROS_LSB_GOOD " == *" $i "* ]] && [[ $B_LSB_FILE == 'true' ]];then
					distro_file='lsb-release'
				elif [[ " $DISTROS_OS_RELEASE_GOOD " == *" $i "* ]] && [[ $B_OS_RELEASE_FILE == 'true' ]];then
					distro_file='os-release'
				else
					distro_file="$i"
				fi
				break
			fi
		done
	fi
	log_function_data "distro_file: $distro_file"
	# first test for the legacy antiX distro id file
	if [[ -e /etc/antiX ]];then
		distro="$( grep -Eoi 'antix.*\.iso' <<< $( remove_erroneous_chars '/etc/antiX' ) | sed 's/\.iso//' )"
	# this handles case where only one release/version file was found, and it's lsb-release. This would
	# never apply for ubuntu or debian, which will filter down to the following conditions. In general
	# if there's a specific distro release file available, that's to be preferred, but this is a good backup.
	elif [[ -n $distro_file && $B_LSB_FILE == 'true' && " $DISTROS_LSB_GOOD" == *" $distro_file "* ]];then
		distro=$( get_distro_lsb_os_release_data 'lsb-file' )
	elif [[ $distro_file == 'lsb-release' ]];then
		distro=$( get_distro_lsb_os_release_data 'lsb-file' )
	elif [[ $distro_file == 'os-release' ]];then
		distro=$( get_distro_lsb_os_release_data 'os-release-file' )
		b_osr='true'
	# then if the distro id file was found and it's not in the exluded primary distro file list, read it
	elif [[ -n $distro_file && -s /etc/$distro_file && " $DISTROS_EXCLUDE_LIST " != *" $distro_file "* ]];then
		# new opensuse uses os-release, but older ones may have a similar syntax, so just use the first line
		if [[ $distro_file == 'SuSE-release' ]];then
			# leaving off extra data since all new suse have it, in os-release, this file has line breaks, like os-release
			# but in case we  want it, it's: CODENAME = Mantis  | VERSION = 12.2 
			# for now, just take first occurrence, which should be the first line, which does not use a variable type format
			distro=$( grep -i -m 1 'suse' /etc/$distro_file )
		else
			distro=$( remove_erroneous_chars "/etc/$distro_file" )
		fi
	# otherwise try  the default debian/ubuntu /etc/issue file
	elif [[ -f /etc/issue ]];then
		# os-release/lsb gives more manageable and accurate output than issue, but mint should use issue for now
		# some bashism, boolean must be in parenthesis to work correctly, ie [[ $(boolean) ]] not [[ $boolean ]]
		if [[ $B_OS_RELEASE_FILE == 'true' ]] && [[ -z $( grep -i 'mint' /etc/issue ) ]];then
			distro=$( get_distro_lsb_os_release_data 'os-release-file' )
			b_osr='true'
		elif [[ $B_LSB_FILE == 'true' ]] && [[ -z $( grep -i 'mint' /etc/issue ) ]];then
			distro=$( get_distro_lsb_os_release_data 'lsb-file' )
		else
			distro=$( gawk '
			BEGIN {
				RS=""
			}
			{
				gsub(/\\[a-z]/, "")
				gsub(/'"$BAN_LIST_ARRAY"'/, " ")
				gsub(/^ +| +$/, "")
				gsub(/ [ \t]+/, " ")
				print
			}' /etc/issue )
			
			# this handles an arch bug where /etc/arch-release is empty and /etc/issue is corrupted
			# only older arch installs that have not been updated should have this fallback required, new ones use
			# os-release
			if [[ -n $( grep -i 'arch linux' <<< $distro ) ]];then
				distro='Arch Linux'
			fi
		fi
	fi
	# a final check. If a long value, before assigning the debugger output, if os-release
	# exists then let's use that if it wasn't tried already. Maybe that will be better.
	if [[ ${#distro} -gt 80 ]] && [[ $B_HANDLE_CORRUPT_DATA != 'true' ]];then
		if [[ $B_OS_RELEASE_FILE == 'true' && $b_osr == 'false' ]];then
			distro=$( get_distro_lsb_os_release_data 'os-release-file' )
		fi
		if [[ ${#distro} -gt 80 ]];then
			distro="${RED}/etc/$distro_file corrupted, use -% to override${NORMAL}"
		fi
	fi
	## note: would like to actually understand the method even if it's not used
	# : ${distro:=Unknown distro o_O}
	## test for /etc/lsb-release as a backup in case of failure, in cases where > one version/release file
	## were found but the above resulted in null distro value
	# Because os-release is now more common, we'll test for it first.
	if [[ -z $distro ]] && [[ $B_OS_RELEASE_FILE == 'true' ]];then
		distro=$( get_distro_lsb_os_release_data 'os-release-file' )
	fi
	if [[ -z $distro ]] && [[ $B_LSB_FILE == 'true' ]];then
		distro=$( get_distro_lsb_os_release_data 'lsb-file' )
	fi
	
	# now some final null tries
	if [[ -z $distro ]];then
		# if the file was null but present, which can happen in some cases, then use the file name itself to 
		# set the distro value. Why say unknown if we have a pretty good idea, after all?
		if [[ -n $distro_file ]] && [[ " $DISTROS_DERIVED $DISTROS_PRIMARY " == *" $distro_file "* ]];then
			distro=$( sed $SED_RX -e 's/[-_]//' -e 's/(release|version)//' <<< $distro_file | sed $SED_RX 's/^([a-z])/\u\1/' )
		fi
		## finally, if all else has failed, give up
		if [[ -z $distro ]];then
			distro='unknown'
		fi
	fi
	# final step cleanup of unwanted information
	# opensuse has the x86 etc type string in names, not needed as redundant since -S already shows that
	distro=$( gawk '
	BEGIN {
		IGNORECASE=1
	}
	{
		sub(/ *\(*(x86_64|i486|i586|i686|686|586|486)\)*/, "", $0)
		print $0
	}' <<< $distro )
	echo "$distro"
	log_function_data "distro: $distro"
	eval $LOGFE
}

# args: $1 - lsb-file/lsb-app/os-release-file
get_distro_lsb_os_release_data()
{
	eval $LOGFS
	local distro=''
	
	case $1 in
		lsb-file)
			if [[ $B_LSB_FILE == 'true' ]];then
				distro=$( gawk -F '=' '
				BEGIN {
					IGNORECASE=1
				}
				# clean out unwanted characters
				{ 
					gsub(/\\|\"|[:\47]/,"", $0 )
					gsub(/^[[:space:]]+|[[:space:]]+$/, "", $2 )
					gsub(/^[[:space:]]+|[[:space:]]+$/, "", $1 )
				}
				# note: adding the spacing directly to variable to make sure distro output is null if not found
				/^DISTRIB_ID/ {
					# this is needed because grep for "arch" is too loose to be safe
					if ( $2 == "arch" ) {
						distroId = "Arch Linux"
					}
					else if ( $2 != "n/a" ) {
						distroId = $2 " "
					}
				}
				/^DISTRIB_RELEASE/ {
					if ( $2 != "n/a" ) {
						distroRelease = $2 " "
					}
				}
				/^DISTRIB_CODENAME/ {
					if ( $2 != "n/a" ) {
						distroCodename = $2 " "
					}
				}
				# sometimes some distros cannot do their lsb-release files correctly, so here is
				# one last chance to get it right.
				/^DISTRIB_DESCRIPTION/ {
					if ( $2 != "n/a" ) {
						distroDescription = $2
					}
				}
				END {
					fullString=""
					if ( distroId == "" && distroRelease == "" && distroCodename == "" && distroDescription != "" ){
						fullString = distroDescription
					}
					else {
						fullString = distroId distroRelease distroCodename
					}
					print fullString
				}
				' $FILE_LSB_RELEASE )
				log_function_data 'cat' "$FILE_LSB_RELEASE"
			fi
			;;
		lsb-app)
			# this is HORRIBLY slow, not using
			if type -p lsb_release &>/dev/null;then
				distro=$( echo "$( lsb_release -irc )" | gawk -F ':' '
				BEGIN { 
					IGNORECASE=1 
				}
				# clean out unwanted characters
				{ 
					gsub(/\\|\"|[:\47]/,"", $0 )
					gsub(/^[[:space:]]+|[[:space:]]+$/, "", $2 )
					gsub(/^[[:space:]]+|[[:space:]]+$/, "", $1 )
				}
				/^Distributor ID/ {
					distroId = $2
				}
				/^Release/ {
					distroRelease = $2
				}
				/^Codename/ {
					distroCodename = $2
				}
				END {
					print distroId " " distroRelease " (" distroCodename ")"
				}' )
			fi
			;;
		os-release-file)
			if [[ $B_OS_RELEASE_FILE == 'true' ]];then
				distro=$( gawk -F '=' '
				BEGIN {
					IGNORECASE=1
					prettyName=""
					regularName=""
					versionName=""
					versionId=""
					distroName=""
				}
				# clean out unwanted characters
				{ 
					gsub(/\\|\"|[:\47]/,"", $0 )
					gsub(/^[[:space:]]+|[[:space:]]+$/, "", $2 )
					gsub(/^[[:space:]]+|[[:space:]]+$/, "", $1 )
				}
				# note: adding the spacing directly to variable to make sure distro output is null if not found
				/^PRETTY_NAME/ {
					if ( $2 != "n/a"  ) {
						prettyName = $2
					}
				}
				/^NAME/ {
					if ( $2 != "n/a" ) {
						regularName = $2
					}
				}
				/^VERSION/ {
					if ( $2 != "n/a" && $1 == "VERSION" ) {
						versionName = $2
					}
					else if ( $2 != "n/a" && $1 == "VERSION_ID" ) {
						versionId = $2
					}
				}
				END {
					# NOTE: tumbleweed has pretty name but pretty name does not have version id
					if ( prettyName != "" && regularName !~ /tumbleweed/ ) {
						distroName = prettyName
					}
					else if ( regularName != "" ) {
						distroName = regularName
						if ( versionName != "" ) {
							distroName = distroName " " versionName
						}
						else if ( versionId != "" ) {
							distroName = distroName " " versionId
						}
						
					}
					print distroName
				}
				' $FILE_OS_RELEASE )
				log_function_data 'cat' "$FILE_OS_RELEASE"
			fi
			;;
	esac
	echo $distro
	log_function_data "distro: $distro"
	eval $LOGFE
}

get_dmidecode_data()
{
	eval $LOGFS
	
	local dmiData="" b_debugger='false'

	if [[ $B_DMIDECODE_SET != 'true' ]];then
		dmidecodePath=$( type -p dmidecode 2>/dev/null )
		if [[ -z $dmidecodePath ]];then
			DMIDECODE_DATA='dmidecode-error-not-installed'
		else
			# note stripping out these lines: Handle 0x0016, DMI type 17, 27 bytes
			# but NOT deleting them, in case the dmidecode data is missing empty lines which will be
			# used to separate results. Then we remove the doubled empty lines to keep it clean and
			# strip out all the stuff we don't want to see in the results. We want the error data in 
			# stdout for error handling
			if [[ $b_debugger == 'true' && $HOSTNAME == 'yawn' ]];then
				dmiData="$( cat ~/bin/scripts/inxi/svn/misc/data/dmidecode/dmidecode-memory-variants-2.txt )"
			else 
				dmiData="$( $dmidecodePath 2>&1 )"
			fi
			# these tests first, because bsd error messages like this (note how many : are in the string)
			# inxi: line 4928: /usr/local/sbin/dmidecode: Permission denied
			if [[ ${#dmiData} -lt 200  ]];then
				if [[ -z ${dmiData/*Permission denied*/} ]];then
				# if [[ -n $( grep -i 'Permission denied' <<< "$dmiData" ) ]];then
					DMIDECODE_DATA='dmidecode-error-requires-root'
				# this handles very old systems, like Lenny 2.6.26, with dmidecode, but no data
				elif [[ -n $( grep -i 'no smbios ' <<< "$dmiData" ) ]];then
					DMIDECODE_DATA='dmidecode-error-no-smbios-dmi-data'
				else
					DMIDECODE_DATA='dmidecode-error-unknown-error'
				fi
			else
				DMIDECODE_DATA="$( echo "$dmiData" | gawk -F ':' '
				BEGIN {
					IGNORECASE=1
					cutExtraTab="false"
					twoData=""
					oneData=""
				}
				{
					# no idea why, but freebsd gawk does not do this right
					oneData=$1
					twoData=$2
					if ( twoData != "" ) {
						twoHolder="true"
					}
					else {
						twoHolder="false"
					}
					if ( $0 ~ /^\tDMI type/ ) {
						sub(/^\tDMI type.*/, "", $0)
						cutExtraTab="true"
					}
					gsub(/'"$BAN_LIST_NORMAL"'/, "", twoData)
					gsub(/'"$BAN_LIST_ARRAY"'/, " ", twoData)
					# clean out Handle line
					# sub(/^Handle.*/,"", $0)
					sub(/^[[:space:]]*Inactive.*/,"",twoData)
					# yes, there is a typo in a user data set, unknow
					# Base Board Version|Base Board Serial Number
					# Chassis Manufacturer|Chassis Version|Chassis Serial Number
					# System manufacturer|System Product Name|System Version
					# To Be Filled By O.E.M.
					# strip out starting white space so that the following stuff will clear properly
					sub(/^[[:space:]]+/, "", twoData)
					sub(/^Base Board .*|^Chassis .*|empty|.*O\.E\.M\..*|.*OEM.*|^Not .*|^System .*|.*unknow.*|.*N\/A.*|none|^To be filled.*|^0x[0]+$|\[Empty\]|<Bad Index>|Default string|^\.\.$/, "", twoData) 
					sub(/.*(AssetTagNum|Manufacturer| Or Motherboard|PartNum.*|SerNum).*/, "", twoData)
					gsub(/\ybios\y|\yacpi\y/, "", twoData) # note: biostar
					sub(/http:\/\/www.abit.com.tw\//, "Abit", twoData)
					
					# for double indented values replace with ~ so later can test for it, we are trusting that
					# indentation will be tabbed in this case
					# special case, dmidecode 2.2 has an extra tab and a DMI type line
					if ( cutExtraTab == "true" ) {
						sub(/^\t\t\t+/, "~", oneData)
					}
					else {
						sub(/^\t\t+/, "~", oneData)
					}
					gsub(/ [ \t]+/, " ", twoData)
					gsub(/^[[:space:]]+|[[:space:]]+$/, "", twoData)
					gsub(/^[[:space:]]+|[[:space:]]+$/, "", oneData)
					
					# reconstructing the line for processing so gawk can use -F : again
					if ( oneData != "" && twoHolder == "true" ) {
						print oneData ":" twoData
					}
					else {
						# make sure all null lines have no spaces in them!
						gsub(/^[[:space:]]+|[[:space:]]+$/,"",$0)
						print $0
					}
				}' \
				| sed '/^$/{
N
/^\n$/D
}' \
				)"
			fi
			# echo ":${DMIDECODE_DATA}:"
			log_function_data "DMIDECODE_DATA (PRE): $DMIDECODE_DATA"
			
		fi
		B_DMIDECODE_SET='true'
		log_function_data "DMIDECODE_DATA (POST): $DMIDECODE_DATA"
	fi

	eval $LOGFE
}
# get_dmidecode_data;echo "$DMIDECODE_DATA";exit

# BSD only
get_dmesg_boot_data()
{
	eval $LOGFS
	
	local dmsg_boot_data=''
	
	if [[ $B_DMESG_BOOT_FILE == 'true' ]];then
		# replace all indented items with ~ so we can id them easily while processing
		# note that if user, may get error of read permissions
		# for some weird reason, real mem and avail mem are use a '=' separator, who knows why, the others are ':'
		dmsg_boot_data="$( cat $FILE_DMESG_BOOT 2>/dev/null | gawk '
		{
			sub(/[[:space:]]*=[[:space:]]*|:[[:space:]]*/,":", $0)
			gsub(/'"$BAN_LIST_ARRAY"'/," ", $0)
			gsub(/\"/, "", $0)
			gsub(/[[:space:]][[:space:]]/, " ", $0)
			print $0
		}' )"
	fi
	DMESG_BOOT_DATA="$dmsg_boot_data"
	log_function_data "$dmsg_boot_data"
	eval $LOGFE
}

get_gcc_system_version()
{
	eval $LOGFS
	local separator='' gcc_installed='' gcc_list='' gcc_others='' a_temp=''
	local gcc_version=$( 
	gcc --version 2>/dev/null | sed $SED_RX 's/\([^\)]*\)//g' | gawk '
	BEGIN {
		IGNORECASE=1
	}
	/^gcc/ {
		print $2
		exit
	}' )
	# can't use xargs -L basename because not all systems support thats
	if [[ $B_EXTRA_EXTRA_DATA == 'true' ]];then
		gcc_others=$( ls /usr/bin/gcc-* 2>/dev/null )
		if [[ -n $gcc_others ]];then
			for item in $gcc_others
			do
				item=${item##*/}
				gcc_installed=$( gawk -F '-' '
				$2 ~ /^[0-9\.]+$/ {
					print $2
				}' <<< $item )
				if [[ -n $gcc_installed && -z $( grep "^$gcc_installed" <<< $gcc_version ) ]];then
					gcc_list=$gcc_list$separator$gcc_installed
					separator=','
				fi
			done
		fi
	fi
	if [[ -n $gcc_version ]];then
		A_GCC_VERSIONS=( "$gcc_version" $gcc_list )
	fi
	a_temp=${A_GCC_VERSIONS[@]}
	log_function_data "A_GCC_VERSIONS: $a_temp"
	eval $LOGFE
}

get_gpu_temp_data()
{
	local gpu_temp='' gpu_fan='' screens='' screen_nu='' gpu_temp_looper=''

	# we'll try for nvidia/ati, then add if more are shown
	if type -p nvidia-settings &>/dev/null;then
		# first get the number of screens. This only work if you are in X
		if [[ $B_RUNNING_IN_DISPLAY == 'true' ]];then
			screens=$( nvidia-settings -q screens | gawk '
			/:[0-9]\.[0-9]/ {
				screens=screens gensub(/(.*)(:[0-9]\.[0-9])(.*)/, "\\2", "1", $0) " "
			}
			END {
				print screens
			}
			' )
		else
			# do a guess, this will work for most users, it's better than nothing for out of X
			screens=':0.0'
		fi
		# now we'll get the gpu temp for each screen discovered. The print out function
		# will handle removing screen data for single gpu systems
		for screen_nu in $screens
		do
			gpu_temp_looper=$( nvidia-settings -c $screen_nu -q GPUCoreTemp 2>/dev/null | gawk -F ': ' '
			BEGIN {
				IGNORECASE=1
				gpuTemp=""
				gpuTempWorking=""
			}
			/Attribute (.*)[0-9]+\.$/ {
				gsub(/\./, "", $2)
				if ( $2 ~ /^[0-9]+$/ ) {
					gpuTemp=gpuTemp $2 "C "
				}
			}
			END {
				print gpuTemp
			}' 	)
			screen_nu=$( cut -d ':' -f 2 <<< $screen_nu )
			gpu_temp="$gpu_temp$screen_nu:$gpu_temp_looper "
		done
	elif type -p aticonfig &>/dev/null;then
# 		gpu_temp=$( aticonfig --adapter=0 --od-gettemperature | gawk -F ': ' '
		gpu_temp=$( aticonfig --adapter=all --od-gettemperature | gawk -F ': ' '
		BEGIN {
			IGNORECASE=1
			gpuTemp=""
			gpuTempWorking=""
		}
		/Sensor (.*)[0-9\.]+ / {
			gpuTempWorking=gensub(/(.*) ([0-9\.]+) (.*)/, "\\2", "1", $2)
			if ( gpuTempWorking ~ /^[0-9\.]+$/ ) {
				gpuTemp=gpuTemp gpuTempWorking "C "
			}
		}
		END {
			print gpuTemp
		}' 	)
	# this handles some newer cases of free driver temp readouts, will require modifications as
	# more user data appears.
	elif [[ -n $Sensors_Data ]];then
		gpu_temp=$( 
		gawk '
		BEGIN {
			IGNORECASE=1
			gpuTemp=""
			separator=""
		}
		/^('"$SENSORS_GPU_SEARCH"')-pci/ {
			while ( getline && !/^$/  ) {
				if ( /^temp/ ) {
					sub(/^[[:alnum:]]*.*:/, "", $0 ) # clear out everything to the :
					gsub(/[\+ \t°]/, "", $1) # ° is a special case, like a space for gawk
					gpuTemp=gpuTemp separator $1
					separator=","
				}	
			}
		}
		END {
			print gpuTemp
		}' <<< "$Sensors_Data" )
	fi
	
	if [[ -n $gpu_temp ]];then
		echo $gpu_temp
	fi
}

## for possible future data, not currently used
get_graphics_agp_data()
{
	eval $LOGFS
	local agp_module=''

	if [[ $B_MODULES_FILE == 'true' ]];then
		## not used currently
		agp_module=$( gawk '
		/agp/ && !/agpgart/ && $3 > 0 {
			print(gensub(/(.*)_agp.*/,"\\1","g",$1))
		}' $FILE_MODULES )
		log_function_data 'cat' "$FILE_MODULES"
	fi
	log_function_data "agp_module: $agp_module"
	eval $LOGFE
}

## create array of gfx cards installed on system
get_graphics_card_data()
{
	eval $LOGFS
	local i='' a_temp=''

	IFS=$'\n'
	A_GRAPHICS_CARD_DATA=( $( gawk -F': ' '
	BEGIN {
		IGNORECASE=1
		busId=""
		trueCard=""
		card=""
		driver=""
	}
	# not using 3D controller yet, needs research: |3D controller |display controller
	# note: this is strange, but all of these can be either a separate or the same
	# card. However, by comparing bus id, say: 00:02.0 we can determine that the
	# cards are  either the same or different. We want only the .0 version as a valid
	# card. .1 would be for example: Display Adapter with bus id x:xx.1, not the right one
	/vga compatible controller|3D controller|Display controller/ {
		driver=""
		gsub(/'"$BAN_LIST_NORMAL"'/, "", $NF)
		gsub(/'"$BAN_LIST_ARRAY"'/, " ", $NF)
		if ( '$COLS_INNER' < 100 ){
			sub(/Core Processor Family/,"Core", $NF)
		}
		gsub(/^ +| +$/, "", $NF)
		gsub(/ [ \t]+/, " ", $NF)
		card=$NF
		busId=gensub(/^([0-9a-f:\.]+) (.+)$/,"\\1",1,$1)
		trueCard=gensub(/(.*)\.([0-9]+)$/,"\\2",1,busId)
		while ( getline && !/^$/) {
			if ( $1 ~ /Kernel driver in use/ ){
				driver=$2
			}
		}
		if ( trueCard == 0 ) {
			print card "," busId "," driver
			# print card "," busId "," driver > "/dev/tty"
		}
	}' <<< "$LSPCI_V_DATA" ) )
	IFS="$ORIGINAL_IFS"
# 	for (( i=0; i < ${#A_GRAPHICS_CARD_DATA[@]}; i++ ))
# 	do
# 		A_GRAPHICS_CARD_DATA[i]=$( sanitize_characters BAN_LIST_NORMAL "${A_GRAPHICS_CARD_DATA[i]}" )
# 	done

	# GFXMEM is UNUSED at the moment, because it shows AGP aperture size, which is not necessarily equal to GFX memory..
	# GFXMEM="size=[$(echo "$LSPCI_V_DATA" | gawk '/VGA/{while (!/^$/) {getline;if (/size=[0-9][0-9]*M/) {size2=gensub(/.*\[size=([0-9]+)M\].*/,"\\1","g",$0);if (size<size2){size=size2}}}}END{print size2}')M]"
	a_temp=${A_GRAPHICS_CARD_DATA[@]}
	log_function_data "A_GRAPHICS_CARD_DATA: $a_temp"
	eval $LOGFE
}

get_graphics_driver()
{
	eval $LOGFS
	
	# list is from sgfxi plus non-free drivers
	local driver_list='amdgpu|apm|ark|ati|chips|cirrus|cyrix|fbdev|fglrx|glint|i128|i740|i810|iftv|imstt|intel|ivtv|mach64|mesa|mga|modesetting|neomagic|newport|nouveau|nsc|nvidia|nv|openchrome|radeonhd|radeon|rendition|s3virge|s3|savage|siliconmotion|sisimedia|sisusb|sis|tdfx|tga|trident|tseng|unichrome|v4l|vboxvideo|vesa|vga|via|vmware|voodoo'
	local driver='' driver_string='' xorg_log_data='' status='' a_temp=''

	if [[ $B_XORG_LOG == 'true' ]];then
		A_GRAPHIC_DRIVERS=( $(
		gawk '
		BEGIN {
			driver=""
			bLoaded="false"
			IGNORECASE=1
		}
		# note that in file names, driver is always lower case
		/[[:space:]]Loading.*('"$driver_list"')_drv.so$/ {
			driver=gensub(/.*[[:space:]]Loading.*('"$driver_list"')_drv.so/, "\\1", 1, $0 )
			# we get all the actually loaded drivers first, we will use this to compare the
			# failed/unloaded, which have not always actually been truly loaded
 			aDrivers[driver]="loaded" 
		}
		# openbsd uses UnloadModule: 
		/(Unloading[[:space:]]|UnloadModule).*('"$driver_list"')(\"||_drv.so)$/ {
			gsub(/\"/,"",$0)
			driver=gensub(/(.*)(Unloading[[:space:]]|UnloadModule).*('"$driver_list"')(\"||_drv.so)$/, "\\3", 1, $0 )
			# we need to make sure that the driver has already been truly loaded, not just discussed
			if ( driver in aDrivers ) {
				aDrivers[driver]="unloaded"
			}
		}
		/Failed.*('"$driver_list"')_drv.so|Failed.*\"('"$driver_list"')\"/ {
 			driver=gensub(/(.*)Failed.*('"$driver_list"')_drv.so/, "\\2", 1, $0 )
			if ( driver == $0 ) {
				driver=gensub(/(.*)Failed.*\"('"$driver_list"')\".*|fred/, "\\2", 1, $0 )
			}
			# we need to make sure that the driver has already been truly loaded, not just discussed
			if ( driver != $0 && driver in aDrivers ) {
				aDrivers[driver]="failed"
			}
		}
		# verify that the driver actually started the desktop, even with false failed messages which can occur
		# this is the driver that is actually driving the display
		/.*\([0-9]+\):[[:space:]]Depth.*framebuffer/ {
			driver=gensub(/.*('"$driver_list"')\([0-9]+\):[[:space:]]Depth.*framebuffer.*/, "\\1", 1, $0 )
			# we need to make sure that the driver has already been truly loaded, not just discussed, also
			# set driver to lower case because sometimes it will show as RADEON or NVIDIA in the actual x start
			driver=tolower(driver)
			if ( driver != $0 && driver in aDrivers ) {
				aDrivers[driver]="loaded"
			}
		}
		END {
			for ( driver in aDrivers ) {
				print driver "," aDrivers[driver]
			}
		}' < $FILE_XORG_LOG ) )
	fi
	a_temp=${A_GRAPHIC_DRIVERS[@]}
	log_function_data "A_GRAPHIC_DRIVERS: $a_temp"
	
	eval $LOGFE
}

## create array of glx data
get_graphics_glx_data()
{
	eval $LOGFS
	local a_temp=''
	# if [[ $B_SHOW_DISPLAY_DATA == 'true' && $B_ROOT != 'true' ]];then
	if [[ $B_SHOW_DISPLAY_DATA == 'true' ]];then
		IFS='^'
		# NOTE: glxinfo -B is not always available, unforunately
		A_GLX_DATA=( $( eval glxinfo $DISPLAY_OPT 2>/dev/null | gawk -F ': ' '
		# handle > 1 cases of detections
		function join( arr, sep ) {
			s=""
			i=flag=0
			for ( i in arr ) {
				if ( flag++ ) {
					s = s sep
				}
				s = s i
			}
			return s
		}

		BEGIN {
			IGNORECASE=1
			compatVersion=""
			# create empty arrays
			split("", a)
			split("", b)
			split("", c)
			split("", d)
		}
		/opengl renderer/ {
			gsub(/'"$BAN_LIST_NORMAL"'/, "", $2)
			gsub(/ [ \t]+/, " ", $2) # get rid of the created white spaces
			gsub(/^ +| +$/, "", $2)
			if ( $2 ~ /mesa/ ) {
				# Allow all mesas
# 				if ( $2 ~ / r[3-9][0-9][0-9] / ) {
					a[$2]
					# this counter failed in one case, a bug, and is not needed now
# 					f++
# 				}
				next
			}
			
			$2 && a[$2]
		}
		# dropping all conditions from this test to just show full mesa information
		# there is a user case where not f and mesa apply, atom mobo
		# /opengl version/ && ( f || $2 !~ /mesa/ ) {
		/opengl version/ {
			# fglrx started appearing with this extra string, does not appear to communicate anything of value
			sub(/(Compatibility Profile Context|\(Compatibility Profile\))/, "", $2 )
			gsub(/ [ \t]+/, " ", $2) # get rid of the created white spaces
			gsub(/^ +| +$/, "", $2)
			$2 && b[$2]
			# note: this is going to be off if ever multi opengl versions appear, never seen one
			compatVersion=gensub(/^([^ \t]+)[ \t].*/,"\\1","g",$2)
		}
		/opengl core profile version/ {
			gsub(/'"$BAN_LIST_NORMAL"'/, "", $2)
			# fglrx started appearing with this extra string, does not appear to communicate anything of value
			sub(/(Core Profile Context|\(Core Profile\))/, "", $2 )
			gsub(/ [ \t]+/, " ", $2) # get rid of the created white spaces
			gsub(/^ +| +$/, "", $2)
			$2 && d[$2]
		}
		/direct rendering/ {
			$2 && c[$2]
		}
		# if -B was always available, we could skip this, but it is not
		/GLX Visuals/ {
			exit
		}
		END {
			dr = join( c, ", " )
			oglr = join( a, ", " )
			oglv = join( b, ", " )
			oglcpv = join( d, ", " )
			# output processing done in print functions, important! do not use \n IFS 
			# because Bash treats an empty value surrounded by \n\n as nothing, not an empty array key!
			# this came up re oglcpv being empty and compatVersion being used instead
			printf( "%s^%s^%s^%s^%s", oglr, oglv, dr, oglcpv, compatVersion )
		}' ) )
		IFS="$ORIGINAL_IFS"

		# GLXR=$(glxinfo | gawk -F ': ' 'BEGIN {IGNORECASE=1} /opengl renderer/ && $2 !~ /mesa/ {seen[$2]++} END {for (i in seen) {printf("%s ",i)}}')
		#    GLXV=$(glxinfo | gawk -F ': ' 'BEGIN {IGNORECASE=1} /opengl version/ && $2 !~ /mesa/ {seen[$2]++} END {for (i in seen) {printf("%s ",i)}}')
	fi
	a_temp=${A_GLX_DATA[@]}
	log_function_data "A_GLX_DATA: $a_temp"
	eval $LOGFE
}

## return screen resolution / tty resolution
## args: $1 - reg/tty
get_graphics_res_data()
{
	eval $LOGFS
	local screen_resolution='' xdpy_data='' screens_count=0 tty_session='' option=$1
	
	# if [[ $B_SHOW_DISPLAY_DATA == 'true' && $B_ROOT != 'true' ]];then
	if [[ $B_SHOW_DISPLAY_DATA == 'true' && $option != 'tty' ]];then
		# Added the two ?'s , because the resolution is now reported without spaces around the 'x', as in
		# 1400x1050 instead of 1400 x 1050. Change as of X.org version 1.3.0
		xdpy_data="$( xdpyinfo $DISPLAY_OPT 2>/dev/null )"
		xdpy_count=$( grep -c 'dimensions' <<< "$xdpy_data" )
		# we get a bit more info from xrandr than xdpyinfo, but xrandr fails to handle
		# multiple screens from different video cards
		if [[ $xdpy_count -eq 1 ]];then
			screen_resolution=$( xrandr $DISPLAY_OPT 2>/dev/null | gawk '
			/\*/ {
				res[++m] = gensub(/^.* ([0-9]+) ?x ?([0-9]+)[_ ].* ([0-9\.]+)\*.*$/,"\\1x\\2@\\3hz","g",$0)
			}
			END {
				for (n in res) {
					if (res[n] ~ /^[[:digit:]]+x[[:digit:]]+/) {
						line = line ? line ", " res[n] : res[n]
					}
				}
				if (line) {
					print(line)
				}
			}' )
		fi
		if [[ -z $screen_resolution || $xdpy_count -gt 1 ]];then
			screen_resolution=$( gawk '
			BEGIN {
				IGNORECASE=1
				screens = ""
				separator = ""
			}
			/dimensions/ {
				screens = screens separator # first time, this is null, next, has comma last
				screens = screens $2 # then tack on the new value for nice comma list
				separator = ", "
			}
			END {
				print screens
			}' <<< "$xdpy_data" )
		fi
	else
		if [[ $B_PROC_DIR == 'true' && -z $BSD_TYPE ]];then
			screen_resolution=$( stty -F $( readlink /proc/$PPID/fd/0 ) size | gawk '{
				print $2"x"$1
			}' )
			# really old systems may not support the above method
			if [[ -z $screen_resolution ]];then
				screen_resolution=$( stty -a | gawk -F ';' '
				/^speed/ {
					gsub(/[[:space:]]*(rows|columns)[[:space:]]*/,"",$0)
					gsub(/[[:space:]]*/,"",$2)
					gsub(/[[:space:]]*/,"",$3)
					print $3"x"$2
				}' )
			fi
		# note: this works fine for all systems but keeping the above for now since
		# the above is probably more accurate for linux systems.
		else
			if [[ $B_CONSOLE_IRC != 'true' ]];then
				screen_resolution=$( stty -a | gawk -F ';' '
					/^speed/ {
						gsub(/[[:space:]]*(rows|columns)[[:space:]]*/,"",$0)
						gsub(/[[:space:]]*/,"",$2)
						gsub(/[[:space:]]*/,"",$3)
						print $3"x"$2
					}' )
			else
				if [[ -n $BSD_TYPE ]];then
					tty_session=$( get_tty_console_irc )
					# getting information for tty that owns the irc client
					screen_resolution="$( stty -f /dev/pts/$tty_session size | gawk '{print $2"x"$1}' )"
				fi
			fi
		fi
	fi
	echo "$screen_resolution"
	log_function_data "screen_resolution: $screen_resolution"
	eval $LOGFE
}

## create array of display server vendor/version data
get_graphics_display_server_data()
{
	eval $LOGFS
	local vendor='' vendor_version='' a_temp='' xdpy_info='' a_display_vendor_working='' 
	# note: this may not always be set, it won't be out of X, for example
	local server="$XDG_SESSION_TYPE" compositor='' compositor_version=''
	
	if [[ $B_EXTRA_EXTRA_DATA == 'true' ]];then
		compositor="$(get_graphics_display_compositor)" compositor_version=''
	fi
	
	if [[ $server == '' ]];then
		if [[ -n "$WAYLAND_DISPLAY" ]];then
			server='wayland'
		fi
	fi
	# if [[ $B_SHOW_DISPLAY_DATA == 'true' && $B_ROOT != 'true' ]];then
	if [[ $B_SHOW_DISPLAY_DATA == 'true' ]];then
		# X vendor and version detection.
		# new method added since radeon and X.org and the disappearance of <X server name> version : ...etc
		# Later on, the normal textual version string returned, e.g. like: X.Org version: 6.8.2
		# A failover mechanism is in place. (if $version is empty, the release number is parsed instead)
		# xdpy_info="$( xdpyinfo )"
		IFS=","
		a_display_vendor_working=( $( xdpyinfo $DISPLAY_OPT 2>/dev/null | gawk -F': +' '
		BEGIN {
			IGNORECASE=1
			vendorString=""
			version=""
			vendorRelease=""
		}
		/vendor string/ {
			gsub(/\ythe\y|\yinc\y|foundation|project|corporation/, "", $2)
			gsub(/'"$BAN_LIST_ARRAY"'/, " ", $2)
			gsub(/^ +| +$/, "", $2)
			gsub(/ [ \t]+/, " ", $2)
			vendorString = $2
		}
		/version:/ {
			version = $NF
		}
		/vendor release number/ {
			gsub(/0+$/, "", $2)
			gsub(/0+/, ".", $2)
			vendorRelease = $2
		}
		/(supported pixmap|keycode range|number of extensions|^screen)/ {
			exit # we are done with the info we want, no reason to read the rest
		}
		END {
			print vendorString "," version "," vendorRelease
		}' ) )
		vendor=${a_display_vendor_working[0]}
		vendor_version=${a_display_vendor_working[1]}

		# this gives better output than the failure last case, which would only show:
		# for example: X.org: 1.9 instead of: X.org: 1.9.0
		if [[ -z $vendor_version ]];then
			vendor_version=$( get_graphics_display_x_version )
		fi
		if [[ -z $vendor_version ]];then
			vendor_version=${a_display_vendor_working[2]}
		fi
		
		# some distros, like fedora, report themselves as the xorg vendor, so quick check
		# here to make sure the vendor string includes Xorg in string
		if [[ -z $( grep -E '(X|xorg|x\.org)' <<< $vendor ) ]];then
			vendor="$vendor X.org"
		fi
		IFS="$ORIGINAL_IFS"
		A_DISPLAY_SERVER_DATA[0]="$vendor"
		A_DISPLAY_SERVER_DATA[1]="$vendor_version"
		A_DISPLAY_SERVER_DATA[2]="$server"
		A_DISPLAY_SERVER_DATA[3]="$compositor"
		A_DISPLAY_SERVER_DATA[4]="$compositor_version"
	else
		vendor_version=$( get_graphics_display_x_version )
		if [[ -n $vendor_version ]];then
			vendor='X.org'
			A_DISPLAY_SERVER_DATA[0]="$vendor"
			A_DISPLAY_SERVER_DATA[1]="$vendor_version"
			A_DISPLAY_SERVER_DATA[2]="$server"
			A_DISPLAY_SERVER_DATA[3]="$compositor"
			A_DISPLAY_SERVER_DATA[4]="$compositor_version"
		fi
	fi
	a_temp=${A_DISPLAY_SERVER_DATA[@]}
	log_function_data "A_DISPLAY_SERVER_DATA: $a_temp"
	eval $LOGFE
}
get_graphics_display_compositor()
{
	eval $LOGFS
	local compositor=''
	
	if [[ -z "${Ps_aux_Data/*mutter*/}" ]];then
		compositor='mutter'
	elif [[ -z "${Ps_aux_Data/*gnome-shell*/}" ]];then
		compositor='gnome-shell'
	elif [[ -z "${Ps_aux_Data/*kwin*/}" ]];then
		compositor='kwin'
	elif [[ -z "${Ps_aux_Data/*moblin*/}" ]];then
		compositor='moblin'
	elif [[ -z "${Ps_aux_Data/*kmscon*/}" ]];then
		compositor='kmscon'
	elif [[ -z "${Ps_aux_Data/*sway*/}" ]];then
		compositor='sway'
	elif [[ -z "${Ps_aux_Data/*grefson*/}" ]];then
		compositor='grefson'
	elif [[ -z "${Ps_aux_Data/*westford*/}" ]];then
		compositor='westford'
	elif [[ -z "${Ps_aux_Data/*rustland*/}" ]];then
		compositor='rustland'
	elif [[ -z "${Ps_aux_Data/*fireplace*/}" ]];then
		compositor='fireplace'
	elif [[ -z "${Ps_aux_Data/*wayhouse*/}" ]];then
		compositor='wayhouse'
	elif [[ -z "${Ps_aux_Data/*weston*/}" ]];then
		compositor='weston'
	elif [[ -z "${Ps_aux_Data/*compton*/}" ]];then
		compositor='compton'
	elif [[ -z "${Ps_aux_Data/*compiz*/}" ]];then
		compositor='compiz'
	elif [[ -z "${Ps_aux_Data/*swc*/}" ]];then
		compositor='swc'
	elif [[ -z "${Ps_aux_Data/*dwc*/}" ]];then
		compositor='dwc'
	fi
	
	log_function_data "compositor: $compositor"
	echo $compositor
	eval $LOGFE
}
# $1 - compositor
get_graphics_display_wayland_version()
{
	eval $LOGFS
	
	local version=''
	
	case $1 in
		mutter)
			:
			;;
	esac
	log_function_data "version: $version"
	echo $version
	
	eval $LOGFE
}

# if other tests fail, try this one, this works for root, out of X also
get_graphics_display_x_version()
{
	eval $LOGFS
	local version='' x_data=''
	# note that some users can have /usr/bin/Xorg but not /usr/bin/X
	if type -p X &>/dev/null;then
		# note: MUST be this syntax: X -version 2>&1
		# otherwise X -version overrides everything and this comes out null.
		# two knowns id strings: X.Org X Server 1.7.5 AND X Window System Version 1.7.5
		#X -version 2>&1 | gawk '/^X Window System Version/ { print $5 }'
		x_data="$( X -version 2>&1 )"
	elif type -p Xorg &>/dev/null;then
		x_data="$( Xorg -version 2>&1)"
	fi
	if [[ -n $x_data ]];then
		version=$( 
		gawk '
		BEGIN {
			IGNORECASE=1
		}
		/^x.org x server/ {
			print $4
			exit
		}
		/^X Window System Version/ {
			print $5
			exit
		}' <<< "$x_data" )
	fi
	echo $version
	log_function_data " version: $version"
	eval $LOGFE
}

# this gets just the raw data, total space/percent used and disk/name/per disk capacity
get_hdd_data_basic()
{
	eval $LOGFS
	local hdd_used='' a_temp='' df_string=''
	local hdd_data='' df_test='' swap_size=0
	
	if [[ -z $BSD_TYPE ]];then
		## NOTE: older df do not have --total (eg: v: 6.10 2008)
		## keep in mind the only value of use with --total is 'used' in blocks, which
		## we can use later to calculate the real percentags based on disk sizes, not
		## mounted partitions. Not using --total because it's more reliable to exclude non /dev
		df_string="df -P -T --exclude-type=aufs --exclude-type=devfs --exclude-type=devtmpfs 
		--exclude-type=fdescfs --exclude-type=iso9660 --exclude-type=linprocfs --exclude-type=nfs
		--exclude-type=nfs3 --exclude-type=nfs4 --exclude-type=nfs5 --exclude-type=procfs  --exclude-type=smbfs
		--exclude-type=squashfs --exclude-type=sysfs --exclude-type=tmpfs --exclude-type=unionfs"
		if swapon -s &>/dev/null;then
			swap_size=$( swapon -s 2>/dev/null | gawk '
			BEGIN { 
			swapSize=0
			total=0
			}
			( $2 == "partition" ) && ( $3 ~ /^[0-9]+$/ ) {
				total += ( 1000 / 1024 ) * $3
			}
			END {
				# result in kB, change to 1024 Byte blocks
				total = total * 1000 / 1024
				total = sprintf( "%.1f", total )
				print total
			}' )
		fi
	else
		# default size is 512, , so use -k for 1024 -H only for size in human readable format
		# older bsds don't support -T, pain, so we'll use partial output there
		if df -k -T &>/dev/null;then
			df_string='df -k -T'
		else
			df_string='df -k'
		fi
		if swapctl -l -k &>/dev/null;then
			swap_size=$( swapctl -l -k 2>/dev/null | gawk '
			BEGIN { 
			swapSize=0
			total=0
			}
			( $1 ~ /^\/dev/ ) && ( $2 ~ /^[0-9]+$/ ) {
				total += $2
			}
			END {
				# result in blocks already
				print total
			}' )
		fi
	fi
	# echo ss: $swap_size
	hdd_data="$( eval $df_string )"
	
	# eval $df_string | awk 'BEGIN{tot=0} !/total/ {tot+=$4} END{print tot}'
	log_function_data 'raw' "hdd_data:\n$hdd_data"
	hdd_used=$( echo "$hdd_data" | gawk -v bsdType="$BSD_TYPE" -v swapSize="$swap_size" '
	BEGIN {
		# this is used for specific cases where bind, or incorrect multiple mounts to same partitions,
		# is present. The value is searched for an earlier appearance of that partition and if it is 
		# present, the data is not added into the partition used size.
		partitionsSet=""
		# this handles a case where the same dev item is mounted twice to different points
		devSet=""
		devWorking=""
		mountWorking=""
		used=0
	}
	# using $1, not $2, because older bsd df do not have -T, filesystem type
	( bsdType != "" ) && $1 ~ /^(aufs|devfs|devtmpfs|fdescfs|filesystem|iso9660|linprocfs|nfs|nfs3|nfs4|nfs5|procfs|squashfs|smbfs|sysfs|tmpfs|type|unionfs)$/ {
		# note use next, not getline or it does not work right
		next 
	}
	# also handles odd dm-1 type, from lvm, and mdraid, and some other bsd partition syntax
	# note that linux 3.2.45-grsec-9th types kernels have this type of partition name: /dev/xvdc (no number, letter)
	# note: btrfs does not seem to use partition integers, just the primary /dev/sdx identifier
	# df can also show /dev/disk/(by-label|by-uuid etc)
	/^\/dev\/(disk\/|mapper\/|[hsv]d[a-z]+[0-9]*|dm[-]?[0-9]+|(ada|mmcblk|nvme[0-9]+n)[0-9]+p[0-9]+.*|(ad|sd|wd)[0-9]+[a-z]|md[0-9]+|[aw]d[0-9]+s.*|xvd[a-z]+)|^ROOT/ {
		# this handles the case where the first item is too long
		# and makes df wrap output to next line, so here we advance
		# it to the next line for that single case. Using df -P should
		# make this unneeded but leave it in just in case
		if ( NF < 6 && $0 !~ /.*%/ ) {
			devSet = devSet "~" $1 "~"
			getline
		}
		# if the first item caused a wrap, use one less than standard
		# testing for the field with % in it, ie: 34%, then go down from there
		# this also protects against cases where the mount point has a space in the
		# file name, thus breaking going down from $NF directly.
		# some bsds will also have only 6 items
		if ( $5 ~ /.*%/ ) {
			devWorking="~" $1 "~"
			mountWorking="~" $6 "~"
			if ( partitionsSet !~ mountWorking && devSet !~ devWorking ) {
				used += $3
			}
			partitionsSet = partitionsSet mountWorking
			# make sure to only include bsd real lines here, ie, short df output
			if ( $1 ~ /^\/dev\// ) {
				devSet = devSet devWorking
			}
		}
		# otherwise use standard
		else if ( $6 ~ /.*%/ ) {
			devWorking="~" $1 "~"
			mountWorking="~" $7 "~"
			if ( partitionsSet !~ mountWorking && devSet !~ devWorking ) {
				used += $4
			}
			partitionsSet = partitionsSet mountWorking
			devSet = devSet devWorking
		}
		# and if this is not detected, give up, we need user data to debug
		else {
			next
		}
	}
	END {
		used=used + swapSize
		used = sprintf( "%.1f", used )
		print used 
	}' )
	# echo hdu:$hdd_used
	if [[ -z $hdd_used ]];then
		hdd_used='na'
	fi
	log_function_data "hdd_used: $hdd_used"
	# create the initial array strings:
	# disk-dev, capacity, name, usb or not
	# final item is the total of the disk
	IFS=$'\n'

	if [[ $B_PARTITIONS_FILE == 'true' ]];then
		A_HDD_DATA=( $(
		gawk -v hddUsed=$hdd_used '
		/([hsv]d[a-z]+|(ada|mmcblk|nvme[0-9]+n)[0-9]+)$/ {
			driveSize = $(NF - 1)*1024/1000**3
			gsub(/'"$BAN_LIST_ARRAY"'/, " ", driveSize)
			gsub(/^ +| +$/, "", driveSize)
			printf( $NF",%.1fGB,,\n", driveSize )
		}
		# See http://lanana.org/docs/device-list/devices-2.6+.txt for major numbers used below
		# See https://www.mjmwired.net/kernel/Documentation/devices.txt for kernel 4.x device numbers
		# $1 ~ /^(3|22|33|8)$/ && $2 % 16 == 0  {
		#	size += $3
		# }
		# special case from this data: 8     0  156290904 sda
		# note: known starters: vm: 252/253/254; grsec: 202; nvme: 259
		$1 ~ /^(3|8|22|33|202|252|253|254|259)$/ && $NF ~ /(nvme[0-9]+n[0-9]+|[hsv]d[a-z]+)$/ && ( $2 % 16 == 0 || $2 % 16 == 8 ) {
			size += $3
		}
		END {
			size = size*1024/1000**3                   # calculate size in GB size
			workingUsed = hddUsed*1024/1000**3         # calculate workingUsed in GB used
			# this handles a special case with livecds where no hdd_used is detected
			if ( size > 0 && hddUsed == "na" ) {
				size = sprintf( "%.1f", size )
				print size "GB,-,,.."
			}
			else if ( size > 0 && workingUsed > 0 ) {
				diskUsed = workingUsed*100/size  # calculate used percentage
				diskUsed = sprintf( "%.1f", diskUsed )
				if ( int(diskUsed) > 100 ) {
					diskUsed = "Used Error!"
				}
				else {
					diskUsed = diskUsed "% used"
				}
				size = sprintf( "%.1f", size )
				print size "GB," diskUsed ",,.." 
			}
			else {
				print "NA,-,,.." # print an empty array, this will be further handled in the print out function
			}
		}' $FILE_PARTITIONS ) )
		log_function_data 'cat' "$FILE_PARTITIONS"
	else
		if [[ -n $BSD_TYPE ]];then
			get_hard_drive_data_bsd "$hdd_used"
		fi
	fi
	IFS="$ORIGINAL_IFS"
	a_temp=${A_HDD_DATA[@]}
	# echo ${a_temp[@]}
	log_function_data "A_HDD_DATA: $a_temp"
	eval $LOGFE
}

## fills out the A_HDD_DATA array with disk names
get_hard_drive_data_advanced()
{
	eval $LOGFS
	local a_temp_working='' a_temp_scsi='' temp_holder='' temp_name='' i='' j=''
	local sd_ls_by_id='' ls_disk_by_id='' ls_disk_by_path='' usb_exists='' a_temp=''
	local firewire_exists='' thunderbolt_exists='' thunderbolt_exists='' hdd_temp hdd_serial=''
	local firmware_rev='' working_path='' block_type=''

	## check for all ide type drives, non libata, only do it if hdx is in array
	## this is now being updated for new /sys type paths, this may handle that ok too
	if [[ -n $( grep -Es 'hd[a-z]' <<< ${A_HDD_DATA[@]} ) ]];then
		# remember, we're using the last array item to store the total size of disks
		for (( i=0; i < ${#A_HDD_DATA[@]} - 1; i++ ))
		do
			IFS=","
			a_temp_working=( ${A_HDD_DATA[i]} )
			IFS="$ORIGINAL_IFS"
			if [[ -z ${a_temp_working[0]/*hd[a-z]*/} ]];then
				if [[ -e /proc/ide/${a_temp_working[0]}/model ]];then
					a_temp_working[2]="$( remove_erroneous_chars /proc/ide/${a_temp_working[0]}/model )"
				else
					a_temp_working[2]=''
				fi
				# these loops are to easily extend the cpu array created in the gawk script above with more fields per cpu.
				for (( j=0; j < ${#a_temp_working[@]}; j++ ))
				do
					if [[ $j -gt 0 ]];then
						A_HDD_DATA[i]="${A_HDD_DATA[i]},${a_temp_working[$j]}"
					else
						A_HDD_DATA[i]="${a_temp_working[$j]}"
					fi
				done
			fi
		done
	fi

	## then handle libata names
	# first get the ata device names, put them into an array
	IFS=$'\n'
	if [[ $B_SCSI_FILE == 'true' ]]; then
		a_temp_scsi=( $( gawk  '
		BEGIN {
			IGNORECASE=1
		}
		/host/ {
			getline a[$0]
			getline b[$0]
		}
		END {
			for (i in a) {
				if (b[i] ~ / *type: *direct-access.*/) {
					#c=gensub(/^ *vendor: (.+) +model: (.+) +rev: (.+)$/,"\\1 \\2 \\3","g",a[i])
					#c=gensub( /^ *vendor: (.+) +model: (.+) +rev:.*$/,"\\1 \\2","g",a[i] )
					# the vendor: string is useless, and is a bug, ATA is not a vendor for example
					c=gensub( /^ *vendor: (.+) +model: (.+) +rev:.*$/, "\\2", "g", a[i] )
					gsub(/'"$BAN_LIST_ARRAY"'/, " ", c)
					gsub(/^ +| +$/, "", c)
					gsub(/ [ \t]+/, " ", c)
					#print a[i]
					# we actually want this data, so leaving this off for now
# 					if (c ~ /\<flash\>|\<pendrive\>|memory stick|memory card/) {
# 						continue
# 					}
					print c
				}
			}
		}' $FILE_SCSI ) )
		log_function_data 'cat' "$FILE_SCSI"
	fi
	IFS="$ORIGINAL_IFS"
	## then we'll loop through that array looking for matches.
	if [[ -n $( grep -Es 'sd[a-z]|nvme' <<< ${A_HDD_DATA[@]} ) ]];then
		# first pack the main ls variable so we don't have to keep using ls /dev...
		# not all systems have /dev/disk/by-id
		ls_disk_by_id="$( ls -l /dev/disk/by-id 2>/dev/null )"
		ls_disk_by_path="$( ls -l /dev/disk/by-path 2>/dev/null )"
		for (( i=0; i < ${#A_HDD_DATA[@]} - 1; i++ ))
		do
			firmware_rev=''
			hdd_temp=''
			hdd_serial=''
			temp_name=''
			working_path=''
			block_type=''
			if [[ -z ${A_HDD_DATA[$i]/*nvme*/} ]];then
				block_type='nvme'
			elif [[ -z ${A_HDD_DATA[$i]/*sd[a-z]*/} ]];then
				block_type='sdx'
			fi
			if [[ -n $block_type ]];then
				IFS=","
				a_temp_working=( ${A_HDD_DATA[$i]} )
				IFS="$ORIGINAL_IFS"
				if [[ $block_type == 'sdx' ]];then
					working_path=/sys/block/${a_temp_working[0]}/device/
				elif [[ $block_type == 'nvme' ]];then
					# this results in:
					# /sys/devices/pci0000:00/0000:00:03.2/0000:06:00.0/nvme/nvme0/nvme0n1
					# but we want to go one level down so slice off trailing nvme0n1
					working_path=$(readlink -f /sys/block/${a_temp_working[0]} 2>/dev/null )
					working_path=${working_path%nvme*}
				fi
				# /sys/block/[sda,hda]/device/model
				# this is handles the new /sys data types first
				if [[ -e ${working_path}model ]];then
					temp_name="$( remove_erroneous_chars ${working_path}model )"
					temp_name=$( cut -d '-' -f 1 <<< ${temp_name// /_} )
				elif [[ ${#a_temp_scsi[@]} -gt 0 ]];then
					for (( j=0; j < ${#a_temp_scsi[@]}; j++ ))
					do
						## ok, ok, it's incomprehensible, search /dev/disk/by-id for a line that contains the
						# discovered disk name AND ends with the correct identifier, sdx
						# get rid of whitespace for some drive names and ids, and extra data after - in name
						temp_name=$( cut -d '-' -f 1 <<< ${a_temp_scsi[$j]// /_} )
						sd_ls_by_id=$( grep -Em1 ".*$temp_name.*${a_temp_working[0]}$" <<< "$ls_disk_by_id" )
						if [[ -n $sd_ls_by_id ]];then
							temp_name=${a_temp_scsi[$j]}
							break
						else
							# test to see if we can get a better name output when null
							if [[ -n $temp_name ]];then
								temp_name=$temp_name
							fi
						fi
					done
				fi
				# I don't know identifier for thunderbolt in /dev/disk/by-id / /dev/disk/by-path
				if [[ -n $temp_name && -n "$ls_disk_by_id" ]];then
					usb_exists=$( grep -Em1 "usb-.*$temp_name.*${a_temp_working[0]}$" <<< "$ls_disk_by_id" )
					firewire_exists=$( grep -Em1 "ieee1394-.*$temp_name.*${a_temp_working[0]}$" <<< "$ls_disk_by_id" )
					# thunderbolt_exists=$( grep -Em1 "ieee1394-.*$temp_name.*${a_temp_working[0]}$" <<< "$ls_disk_by_id" )
					# note: sometimes with wwn- numbering usb does not appear in by-id but it does in by-path
				fi
				if [[ -n "$ls_disk_by_path" ]];then
					if [[ -z $usb_exists ]];then
						usb_exists=$( grep -Em1 "usb-.*${a_temp_working[0]}$" <<< "$ls_disk_by_path" )
					fi
					if [[ -n $usb_exists ]];then
						a_temp_working[3]='USB'
					fi
					if [[ -z $firewire_exists ]];then
						firewire_exists=$( grep -Em1 "ieee1394-.*${a_temp_working[0]}$" <<< "$ls_disk_by_path" )
					fi
					if [[ -n $firewire_exists ]];then
						a_temp_working[3]='FireWire'
					fi
				fi
				a_temp_working[2]=$temp_name
				for (( j=0; j < ${#a_temp_working[@]}; j++ ))
				do
					if [[ $j -gt 0 ]];then
						A_HDD_DATA[i]="${A_HDD_DATA[i]},${a_temp_working[$j]}"
					else
						A_HDD_DATA[i]="${a_temp_working[$j]}"
					fi
				done
			fi
			if [[ $B_EXTRA_DATA == 'true' ]];then
				IFS=","
				a_temp_working=( ${A_HDD_DATA[i]} )
				# echo "a:" ${a_temp_working[@]}
				IFS="$ORIGINAL_IFS"
				
				if [[ -n ${a_temp_working[1]} ]];then
					hdd_temp=$( get_hdd_temp_data "/dev/${a_temp_working[0]}" )
				fi
				if [[ $B_EXTRA_EXTRA_DATA == 'true' ]];then
					if [[ -e ${working_path}serial ]];then
						hdd_serial="$( remove_erroneous_chars ${working_path}serial )"
					else
						hdd_serial=$( get_hdd_serial_number "${a_temp_working[0]}" )
					fi
					if [[ -e ${working_path}firmware_rev ]];then
						firmware_rev="$( remove_erroneous_chars ${working_path}firmware_rev )"
					fi
				fi
				A_HDD_DATA[i]="${a_temp_working[0]},${a_temp_working[1]},${a_temp_working[2]},${a_temp_working[3]},$hdd_serial,$hdd_temp,$firmware_rev"
				# echo b: ${A_HDD_DATA[i]}
			fi
		done
	fi
	a_temp=${A_HDD_DATA[@]}
	log_function_data "A_HDD_DATA: $a_temp"
	eval $LOGFE
}

# args: $1 ~ hdd_used
get_hard_drive_data_bsd()
{
	eval $LOGFS
	
	local a_temp=''
	
	if [[ -n $DMESG_BOOT_DATA ]];then
		IFS=$'\n'
		A_HDD_DATA=( $( gawk -v hddUsed="$1" -F ':' '
		BEGIN {
			IGNORECASE=1
			size=0
			bSetSize="false"
		}
		$1 ~ /^(ad|ada|mmcblk|nvme[0-9]+n|sd|wd)[0-9]+(|[[:space:]]at.*)$/ {
			diskId=gensub(/^((ad|ada|mmcblk|nvme[0-9]+n|sd|wd)[0-9]+)[^0-9].*/,"\\1",1,$1)
			# note: /var/run/dmesg.boot may repeat items since it is not created
			# fresh every boot, this way, only the last items will be used per disk id
			if (aIds[diskId] == "" ) {
				aIds[diskId]=diskId
				if ( $0 !~ /raid/) { 
					bSetSize="true"
				}
			}
			aDisks[diskId, "id"] = diskId
			if ($0 ~ /[^0-9][0-9\.]+[[:space:]]*[MG]B/ && $0 !~ /MB\/s/) {
				workingSize=gensub(/.*[^0-9]([0-9\.]+[[:space:]]*[MG]B).*/,"\\1",1,$0)
				if (workingSize ~ /GB/ ) {
					sub(/[[:space:]]*GB/,"",workingSize)
					workingSize=workingSize*1000
				}
				else if (workingSize ~ /MB/ ) {
					sub(/[[:space:]]*MB/,"",workingSize)
					workingSize=workingSize
				}
				aDisks[diskId, "size"] = workingSize
				if ( bSetSize == "true" ) {
					if ( workingSize != "" ){
						size=size+workingSize
						bSetSize="false"
					}
				}
			}
			if ( $NF ~ /<.*>/ ){
				gsub(/.*<|>.*/,"",$NF)
				aDisks[diskId, "model"] = $NF
			}
			if ( $NF ~ /serial number/ ){
				sub(/serial[[:space:]]+number[[:space:]]*/,"",$NF)
				aDisks[diskId, "serial"] = $NF
			}
		}
		END {
			# sde,3.9GB,STORE_N_GO,USB,C200431546D3CF49-0:0,0
			# sdd,250.1GB,ST3250824AS,,9ND08GKX,45
			# multi dimensional pseudo arrays are sorted at total random, not in order of
			# creation, so force a sort of the aIds, which deletes the array index but preserves
			# the sorted keys.
			asort(aIds) 
			
			for ( key in aIds ) {
				# we are not adding to size above for raid, and we do not print it for raid
				# this is re openbsd raid, which uses sd0 for raid array, even though sd is for scsi
				if ( aDisks[aIds[key], "model"] !~ /raid/ ) {
					workingSize = aDisks[aIds[key], "size"]/1000
					workingSize = sprintf( "%.1fGB", workingSize )
					print aDisks[aIds[key], "id"] "," workingSize "," aDisks[aIds[key], "model"] "," "," aDisks[aIds[key], "serial"] ",," 
				}
			}
			size = size/1000                # calculate size in GB size
			# in kb
			workingUsed = hddUsed*1024/1000**3         # calculate workingUsed in GB used
			# this handles a special case with livecds where no hdd_used is detected
			if ( size > 0 && hddUsed == "na" ) {
				size = sprintf( "%.1f", size )
				print size "GB,-,,.."
			}
			else if ( size > 0 && workingUsed > 0 ) {
				diskUsed = workingUsed*100/size  # calculate used percentage
				diskUsed = sprintf( "%.1f", diskUsed )
				if ( int(diskUsed) > 100 ) {
					diskUsed = "Used Error!"
				}
				else {
					diskUsed = diskUsed "% used"
				}
				size = sprintf( "%.1f", size )
				print size "GB," diskUsed ",,.." 
			}
			else {
				print "NA,-,,.." # print an empty array, this will be further handled in the print out function
			}
		}' <<< "$DMESG_BOOT_DATA" ) )
		IFS="$ORIGINAL_IFS"
	fi
	
	a_temp=${A_HDD_DATA[@]}
	# echo ${a_temp[@]}
	log_function_data "A_HDD_DATA: $a_temp"
	
	eval $LOGFE
}

# args: $1 - which drive to get serial number of
get_hdd_serial_number()
{
	eval $LOGFS
	
	local hdd_serial=''
	
	get_partition_dev_data 'id'
	
	# lrwxrwxrwx 1 root root  9 Apr 26 09:32 scsi-SATA_ST3160827AS_5MT2HMH6 -> ../../sdc
	# exception: ata-InnoDisk_Corp._-_mSATA_3ME3_BCA34401050060191 -> ../../sda
	# exit on the first instance
	hdd_serial=$( gawk '
	/'$1'$/ {
		serial=gensub( /(.+)_([^_]+)$/, "\\2", 1, $9 )
		print serial
		exit
	}' <<< "$DEV_DISK_ID" )
	
	echo $hdd_serial
	log_function_data "hdd serial: $hdd_serial"
	eval $LOGFE
}

# a few notes, normally hddtemp requires root, but you can set user rights in /etc/sudoers.
# args: $1 - /dev/<disk> to be tested for
get_hdd_temp_data()
{
	eval $LOGFS
	local hdd_temp='' sudo_command='' device=$1
	
	if [[ $B_SUDO_TESTED != 'true' ]];then
		B_SUDO_TESTED='true'
		SUDO_PATH=$( type -p sudo )
	fi
	# only use sudo if not root, -n option requires sudo -V 1.7 or greater. sudo will just error out
	# which is the safest course here for now, otherwise that interactive sudo password thing is too annoying
	# important: -n makes it non interactive, no prompt for password
	if [[ $B_ROOT != 'true' && -n $SUDO_PATH ]];then
		sudo_command='sudo -n '
	fi
	# try this to see if hddtemp gives result for the base name
	if [[ -z ${device/*nvme*/} ]];then
		if type -p nvme &>/dev/null;then
			device=${device%n[0-9]}
			# this will fail if regular user and no sudo present, but that's fine, it will just return null
			hdd_temp=$(  eval $sudo_command nvme smart-log $device 2>/dev/null | gawk -F ':' '
			BEGIN {
				IGNORECASE=1
			}
			# other rows may have: Temperature sensor 1 :
			/^temperature\s*:/ {
				gsub(/^[[:space:]]+|[[:space:]]*C$/,"",$2)
				print $2
			}' )
		fi
	else
		if [[ $B_HDDTEMP_TESTED != 'true' ]];then
			B_HDDTEMP_TESTED='true'
			HDDTEMP_PATH=$( type -p hddtemp )
		fi
		if [[ -n $HDDTEMP_PATH && -n $device ]];then
			# this will fail if regular user and no sudo present, but that's fine, it will just return null
			hdd_temp=$( eval $sudo_command $HDDTEMP_PATH -nq -u C $device )
		fi
	fi
	if [[ -n $hdd_temp && -z ${hdd_temp//[0-9]/} ]];then
		echo $hdd_temp
	fi
	eval $LOGFE
}

get_init_data()
{
	eval $LOGFS
	
	local init_type='' init_version='' rc_type='' rc_version='' a_temp=''
	local ls_run='' strings_init_version=''
	local runlevel=$( get_runlevel_data )
	local default_runlevel=$( get_runlevel_default )
	
	# this test is pretty solid, if pid 1 is owned by systemd, it is systemd
	# otherwise that is 'init', which covers the rest of the init systems, I think anyway.
	# more data may be needed for other init systems.
	if [[ -e /proc/1/comm && -n $( grep -s 'systemd' /proc/1/comm ) ]];then
		init_type='systemd'
		if type -p systemd &>/dev/null;then
			init_version=$( get_program_version 'systemd' '^systemd' '2' )
		fi
		if [[ -z $init_version ]];then
			if type -p systemctl &>/dev/null;then
				init_version=$( get_program_version 'systemctl' '^systemd' '2' )
			fi
		fi
	else
		ls_run=$(ls /run)
		# note: upstart-file-bridge.pid upstart-socket-bridge.pid upstart-udev-bridge.pid
		if [[ -n $( /sbin/init --version 2>/dev/null | grep 'upstart' ) ]];then
			init_type='Upstart'
			# /sbin/init --version == init (upstart 1.12.1)
			init_version=$( get_program_version 'init' 'upstart' '3' )
		elif [[ -e /proc/1/comm && -n $( grep -s 'epoch' /proc/1/comm ) ]];then
			init_type='Epoch'
			# epoch version == Epoch Init System 1.0.1 "Sage"
			init_version=$( get_program_version 'epoch' '^Epoch' '4' )
		# missing data: note, runit can install as a dependency without being the init system
		# http://smarden.org/runit/sv.8.html
		# NOTE: the proc test won't work on bsds, so if runit is used on bsds we will need more data
		elif [[ -e /proc/1/comm && -n $( grep -s 'runit' /proc/1/comm ) ]];then
		# elif [[ -e /sbin/runit-init || -e /etc/runit || -n $( type -p sv ) ]];then
			init_type='runit' # lower case
			# no data on version yet
		# freebsd at least
		elif type -p launchctl &>/dev/null;then
			init_type='launchd'
			#  / launchd/ version.plist /etc/launchd.conf
			# init_version=$( get_program_version 'Launchd' '^Launchd' '4' )
		elif [[ -f /etc/inittab ]];then
			init_type='SysVinit'
			if type -p strings &>/dev/null;then
				strings_init_version="$( strings /sbin/init | grep -E 'version[[:space:]]+[0-9]' )"
			fi
			if [[ -n $strings_init_version ]];then
				init_version=$( gawk '{print $2}' <<< "$strings_init_version" )
			fi
		elif [[ -f /etc/ttys ]];then
			init_type='init (bsd)'
		fi
		if [[ -n $( grep 'openrc' <<< "$ls_run" ) ]];then
			rc_type='OpenRC'
			# /sbin/openrc --version == openrc (OpenRC) 0.13
			if type -p openrc &>/dev/null;then
				rc_version=$( get_program_version 'openrc' '^openrc' '3' )
			# /sbin/rc --version == rc (OpenRC) 0.11.8 (Gentoo Linux)
			elif type -p rc &>/dev/null;then
				rc_version=$( get_program_version 'rc' '^rc' '3' )
			fi
			if [[ -e /run/openrc/softlevel ]];then
				runlevel=$( cat /run/openrc/softlevel 2>/dev/null )
			elif [[ -e /var/run/openrc/softlevel ]];then
				runlevel=$( cat /var/run/openrc/softlevel 2>/dev/null )
			elif type -p rc-status &>/dev/null;then
				runlevel=$( rc-status -r 2>/dev/null )
			fi
		## assume sysvrc, but this data is too buggy and weird and inconsistent to have meaning
		# leaving this off for now
# 		elif [[ -f /etc/inittab ]];then
# 			rc_type='SysVrc'
# 			# this is a guess that rc and init are same versions, may need updates / fixes
# 			rc_version=$init_version
		fi
	fi
	IFS=$'\n'
	
	A_INIT_DATA=( 
	"$init_type"
	"$init_version"
	"$rc_type"
	"$rc_version"
	"$runlevel"
	"$default_runlevel" )
	
	IFS="$ORIGINAL_IFS"
	
	a_temp=${A_INIT_DATA[@]}
	log_function_data "A_INIT_DATA: $a_temp"
	
	eval $LOGFE
}

# note: useless because this is just absurdly inaccurate, too bad...
get_install_date()
{
	eval $LOGFS
	
	local installed=''
	
	if ls -al --time-style '+FORMAT %Y-%m-%d' /usr 2>/dev/null;then
		installed=$(ls -al --time-style '+FORMAT %Y-%m-%d' / | awk '/lost\+found/ {print $7;exit}' )
# 	elif 
# 		:
	fi
	
	echo $installed
	
	eval $LOGFE
}

get_kernel_compiler_version()
{
	# note that we use gawk to get the last part because beta, alpha, git versions can be non-numeric
	local compiler_version='' compiler_type=''
	
	if [[ -e /proc/version ]];then
		compiler_version=$( grep -Eio 'gcc[[:space:]]*version[[:space:]]*([^ \t]*)' /proc/version 2>/dev/null | gawk '{print $3}' )
		if [[ -n $compiler_version ]];then
			compiler_type='gcc'
		fi
	else
		if [[ $BSD_VERSION == 'darwin' ]];then
			if type -p gcc &>/dev/null;then
				compiler_version=$( get_program_version 'gcc' 'Apple[[:space:]]LLVM' '4' )
				if [[ -n $compiler_version ]];then
					compiler_type='LLVM-GCC'
				fi
			fi
		else
			if [[ -f /etc/src.conf ]];then
				compiler_type=$( grep '^CC' /etc/src.conf | cut -d '=' -f 2 )
			elif [[ -f /etc/make.conf ]];then
				compiler_type=$( grep '^CC' /etc/make.conf | cut -d '=' -f 2 )
			fi
			if [[ -n $compiler_type ]];then
				if type -p $compiler_type &>/dev/null;then
					if [[ $compiler_type == 'gcc' ]];then
						compiler_version=$( get_program_version 'gcc' '^gcc' '3' )
					elif [[ $compiler_type == 'clang' ]];then
						# FreeBSD clang version 3.0 (tags/RELEASE_30/final 145349) 20111210
						compiler_version=$( get_program_version 'clang' 'clang' '4' )
					fi
				fi
			fi
		fi
	fi
	if [[ -n $compiler_version ]];then
		compiler_version="$compiler_type^$compiler_version"
	fi
	echo $compiler_version
}

get_kernel_version()
{
	eval $LOGFS
	
	local kernel_version='' ksplice_kernel_version=''
	
	kernel_version=$( uname -rm )
	if [[ $BSD_VERSION == 'darwin' ]];then
		kernel_version="Darwin $kernel_version"
	fi
	if [[ -n $( type -p uptrack-uname ) && -n $kernel_version ]];then
		ksplice_kernel_version=$( uptrack-uname -rm )
		if [[ $kernel_version != $ksplice_kernel_version ]];then
			kernel_version="$ksplice_kernel_version (ksplice)"
		fi
	fi
	log_function_data "kernel_version: $kernel_version - ksplice_kernel_version: $ksplice_kernel_version"
	
	CURRENT_KERNEL=$kernel_version
	
	eval $LOGFE
}

# args: $1 - v/n 
get_lspci_data()
{
	eval $LOGFS
	local lspci_data=''

	if [[ $B_LSPCI == 'true' ]];then
		lspci_data="$( lspci -$1 | gawk '{
			gsub(/\(prog-if[^)]*\)/,"")
			sub(/^0000:/, "", $0) # seen case where the 0000: is prepended, rare, but happens
			print
		}' )"
	fi
	log_function_data 'raw' "lspci_data $1:\n$lspci_data"
	if [[ $1 == 'v' ]];then
		LSPCI_V_DATA="$lspci_data"
	elif [[ $1 == 'n' ]];then
		LSPCI_N_DATA="$lspci_data"
	fi
	eval $LOGFE
}

# args: $1 - busid
get_lspci_chip_id()
{
	eval $LOGFS
	
	local chip_id=''
	
	chip_id=$( gawk '
	/^'$1'/ {
		if ( $3 != "" ) {
			print $3
		}
	}' <<< "$LSPCI_N_DATA" )
	
	echo $chip_id
	
	eval $LOGFE
}

get_machine_data()
{
	eval $LOGFS
	local a_temp='' separator='' id_file='' file_data='' array_string=''
	local id_dir='/sys/class/dmi/id/' dmi_data='' firmware_type='BIOS'
	local machine_files="
	sys_vendor product_name product_version product_serial product_uuid 
	board_vendor board_name board_version board_serial 
	bios_vendor bios_version bios_date 
	"
	if [[ $B_EXTRA_EXTRA_DATA == 'true' ]];then
		machine_files="$machine_files
		chassis_vendor chassis_type chassis_version chassis_serial
		"
	fi
	if [[ -d $id_dir && $B_FORCE_DMIDECODE == 'false' ]];then
		if [[ -d /sys/firmware/efi ]];then
			firmware_type='UEFI'
		elif [[ -n $(ls /sys/firmware/acpi/tables/UEFI* 2>/dev/null ) ]];then
			firmware_type='UEFI [Legacy]'
		fi
		for id_file in $machine_files
		do
			file_data=''
			if [[ -r $id_dir$id_file ]];then
				file_data=$( gawk '
				BEGIN {
					IGNORECASE=1
				}
				{
					gsub(/'"$BAN_LIST_NORMAL"'/, "", $0)
					gsub(/'"$BAN_LIST_ARRAY"'/, " ", $0)
					# yes, there is a typo in a user data set, unknow
					# Base Board Version|Base Board Serial Number
					# Chassis Manufacturer|Chassis Version|Chassis Serial Number
					# System manufacturer|System Product Name|System Version
					# To Be Filled By O.E.M.
					sub(/^Base Board .*|^Chassis .*|.*O\.E\.M\..*|.*OEM.*|^Not .*|^System .*|.*unknow.*|.*N\/A.*|Default string|none|^To be filled.*/, "", $0)
					gsub(/\ybios\y|\yacpi\y/, "", $0) # note: biostar
					sub(/http:\/\/www.abit.com.tw\//, "Abit", $0)
					gsub(/^ +| +$/, "", $0)
					gsub(/ [ \t]+/, " ", $0)
					print $0
				}' < $id_dir$id_file )
			fi
			array_string="$array_string$separator$file_data"
			separator=','
		done
		if [[ $array_string != '' ]];then
			# note: dmidecode has two more data types possible, so always add 2 more
			if [[ $B_EXTRA_EXTRA_DATA == 'true' ]];then
				array_string="$array_string,,"
			else
				array_string="$array_string,,,,,,"
			fi
			array_string="$array_string,$firmware_type"
		fi
	else
		get_dmidecode_data
		if [[ -n $DMIDECODE_DATA ]];then
			if [[ $DMIDECODE_DATA == 'dmidecode-error-'* ]];then
				array_string=$DMIDECODE_DATA
			# please note: only dmidecode version 2.11 or newer supports consistently the -s flag
			else
				array_string=$( gawk -F ':' '
				BEGIN {
					IGNORECASE=1
					baseboardManufacturer=""
					baseboardProductName=""
					baseboardSerialNumber=""
					baseboardVersion=""
					chassisManufacturer=""
					chassisSerialNumber=""
					chassisType=""
					chassisVersion=""
					firmwareReleaseDate=""
					firmwareRevision="" # only available from dmidecode
					firmwareRomSize="" # only available from dmidecode
					firmwareType="BIOS"
					firmwareVendor=""
					firmwareVersion=""
					systemManufacturer=""
					systemProductName=""
					systemVersion=""
					systemSerialNumber=""
					systemUuid=""
					bItemFound="" # we will only output if at least one item was found
					fullString=""
					testString=""
					bSys=""
					bCha=""
					bBio=""
					bBas=""
				}
				/^Bios Information/ {
					while ( getline && !/^$/ ) {
						if ( $1 ~ /^Release Date/ ) { firmwareReleaseDate=$2 }
						if ( $1 ~ /^BIOS Revision/ ) { firmwareRevision=$2 }
						if ( $1 ~ /^ROM Size/ ) { firmwareRomSize=$2 }
						if ( $1 ~ /^Vendor/ ) { firmwareVendor=$2 }
						if ( $1 ~ /^Version/ ) { firmwareVersion=$2 }
						if ( $1 ~ /^UEFI is supported/ ) { firmwareType="UEFI" }
					}
					testString=firmwareReleaseDate firmwareRevision firmwareRomSize firmwareVendor firmwareVersion
					if ( testString != ""  ) {
						bItemFound="true"
					}
					bBio="true"
				}
				/^Base Board Information/ {
					while ( getline && !/^$/ ) {
						if ( $1 ~ /^Manufacturer/ ) { baseboardManufacturer=$2 }
						if ( $1 ~ /^Product Name/ ) { baseboardProductName=$2 }
						if ( $1 ~ /^Serial Number/ ) { baseboardSerialNumber=$2 }
					}
					testString=baseboardManufacturer baseboardProductName baseboardSerialNumber
					if ( testString != ""  ) {
						bItemFound="true"
					}
					bBas="true"
				}
				/^Chassis Information/ {
					while ( getline && !/^$/ ) {
						if ( $1 ~ /^Manufacturer/ ) { chassisManufacturer=$2 }
						if ( $1 ~ /^Serial Number/ ) { chassisSerialNumber=$2 }
						if ( $1 ~ /^Type/ ) { chassisType=$2 }
						if ( $1 ~ /^Version/ ) { chassisVersion=$2 }
					}
					testString=chassisManufacturer chassisSerialNumber chassisType chassisVersion
					if ( testString != ""  ) {
						bItemFound="true"
					}
					bCha="true"
				}
				/^System Information/ {
					while ( getline && !/^$/ ) {
						if ( $1 ~ /^Manufacturer/ ) { systemManufacturer=$2 }
						if ( $1 ~ /^Product Name/ ) { systemProductName=$2 }
						if ( $1 ~ /^Version/ ) { systemVersion=$2 }
						if ( $1 ~ /^Serial Number/ ) { systemSerialNumber=$2 }
						if ( $1 ~ /^UUID/ ) { systemUuid=$2 }
					}
					testString=systemManufacturer systemProductName systemVersion systemSerialNumber systemUuid
					if ( testString != ""  ) {
						bItemFound="true"
					}
					bSys="true"
				}
				( bSys == "true" && bCha="true" && bBio == "true" && bBas == "true" ) {
					exit # stop the loop
				}
				END {
					# sys_vendor product_name product_version product_serial product_uuid 
					# board_vendor board_name board_version board_serial 
					# bios_vendor bios_version bios_date 
					if ( bItemFound == "true" ) {
						fullString = systemManufacturer "," systemProductName "," systemVersion "," systemSerialNumber 
						fullString = fullString "," systemUuid "," baseboardManufacturer "," baseboardProductName 
						fullString = fullString "," baseboardVersion "," baseboardSerialNumber "," firmwareVendor
						fullString = fullString "," firmwareVersion "," firmwareReleaseDate "," chassisManufacturer
						fullString = fullString "," chassisType "," chassisVersion "," chassisSerialNumber 
						fullString = fullString ","  firmwareRevision "," firmwareRomSize "," firmwareType
						
						print fullString
					}
				}' <<< "$DMIDECODE_DATA" )
			fi
		fi
	fi
	# echo $array_string
	IFS=','
	A_MACHINE_DATA=( $array_string )
	IFS="$ORIGINAL_IFS"
	# echo ${A_MACHINE_DATA[5]}
	a_temp=${A_MACHINE_DATA[@]}
 	# echo $a_temp
	log_function_data "A_MACHINE_DATA: $a_temp"
	eval $LOGFE
}
# B_ROOT='true';get_machine_data;exit
## return memory used/installed
get_memory_data()
{
	eval $LOGFS
	local memory='' memory_full='' used_memory=''
	if [[ $B_MEMINFO_FILE == 'true' ]];then
		memory=$( gawk '
		/^MemTotal:/ {
			tot = $2
		}
		/^(MemFree|Buffers|Cached):/ {
			notused+=$2
		}
		END {
			used = tot - notused
			printf("%.1f/%.1fMB\n", used/1024, tot/1024)
		}' $FILE_MEMINFO )
		log_function_data 'cat' "$FILE_MEMINFO"
	elif [[ $B_SYSCTL == 'true' && -n $SYSCTL_A_DATA ]];then
		local gawk_fs=': '
		# darwin sysctl is broken and uses both : and = and repeats these items
		if [[ $BSD_VERSION == 'openbsd' ]];then
			gawk_fs='='
		fi
		# use this for all bsds, maybe we can get some useful data on other ones
		if [[ -n $( type -p vmstat) ]];then
			# avail mem:2037186560 (1942MB)
			used_memory=$( vmstat 2>/dev/null | tail -n 1 | gawk '
			# openbsd/linux
			# procs    memory       page                    disks    traps          cpu
			# r b w    avm     fre  flt  re  pi  po  fr  sr wd0 wd1  int   sys   cs us sy id
			# 0 0 0  55256 1484092  171   0   0   0   0   0   2   0   12   460   39  3  1 96
			# freebsd:
			# procs      memory      page                    disks     faults         cpu
			# r b w     avm    fre   flt  re  pi  po    fr  sr ad0 ad1   in   sy   cs us sy id
			# 0 0 0  21880M  6444M   924  32  11   0   822 827   0   0  853  832  463  8  3 88
			# dragonfly
			#  procs      memory      page                    disks     faults      cpu
			#  r b w     avm    fre  flt  re  pi  po  fr  sr ad0 ad1   in   sy  cs us sy id
			#  0 0 0       0  84060 30273993 2845 12742 1164 407498171 320960902   0   0 424453025 1645645889 1254348072 35 38 26
			
			BEGIN {
				IGNORECASE=1
				memory=""
			}
			{
				if ($4 ~ /M/ ){
					sub(/M/,"",$4)
					memory=$4*1024
				}
				else if ($4 ~ /G/ ){
					sub(/G/,"",$4)
					memory=$4*1024*1000
				}
				else {
					sub(/K/,"",$4)
					# dragonfly can have 0 avm, but they may fix that so make test dynamic
					if ( $4 != 0 ) {
						memory=$4
					}
					else {
						memory="avm-0-" $5
					}
				}
				print memory " " 
				exit
			}' )
		fi
		# for dragonfly, we will use free mem, not used because free is 0
		memory=$( grep -i 'mem' <<< "$SYSCTL_A_DATA" | gawk -v usedMemory="$used_memory" -F "$gawk_fs"  '
		BEGIN {
			realMemory=""
			freeMemory=""
		}
		# freebsd seems to use bytes here
		/^hw.physmem/ && ( realMemory == "" ) {
			gsub(/^[^0-9]+|[^0-9]+$/,"",$2)
			realMemory = $2/1024
			if ( freeMemory != "" ) {
				exit
			}
		}
		# But, it uses K here. Openbsd does not seem to have this item
		# this can be either: Free Memory OR Free Memory Pages
		$1 ~ /^Free Memory/ {
			gsub(/[^0-9]/,"",$NF)
			freeMemory = $NF
			if ( realMemory != "" ) {
				exit
			}
		}
		END {
			# hack: temp fix for openbsd/darwin: in case no free mem was detected but we have physmem
			if ( freeMemory == "" && realMemory != "" ) {
				# use openbsd/dragonfly avail mem data if available
				if (usedMemory != "" ) {
					if (usedMemory !~ /^avm-0-/ ) {
						printf("%.1f/%.1fMB\n", usedMemory/1024, realMemory/1024)
					}
					else {
						sub(/avm-0-/,"",usedMemory)
						int(usedMemory)
						# using free mem, not used for dragonfly
						usedMemory = realMemory - usedMemory
						printf("%.1f/%.1fMB\n", usedMemory/1024, realMemory/1024)
					}
				}
				else {
					printf("NA/%.1fMB\n", realMemory/1024)
				}
			}
			else if ( freeMemory != "" && realMemory != "" ) {
				used = realMemory - freeMemory
				printf("%.1f/%.1fMB\n", used/1024, realMemory/1024)
			}
		}' )
	fi
	log_function_data "memory: $memory"
	MEMORY="$memory"
	eval $LOGFE
}

# process and return module version data
get_module_version_number()
{
	eval $LOGFS
	local module_version=''
	
	if [[ $B_MODINFO_TESTED != 'true' ]];then
		B_MODINFO_TESTED='true'
		MODINFO_PATH=$( type -p modinfo )
	fi

	if [[ -n $MODINFO_PATH ]];then
		module_version=$( $MODINFO_PATH $1 2>/dev/null | gawk '
		BEGIN {
			IGNORECASE=1
		}
		/^version/ {
			gsub(/'"$BAN_LIST_ARRAY"'/, " ", $2)
			gsub(/^ +| +$/, "", $2)
			gsub(/ [ \t]+/, " ", $2)
			print $2
		}
		' )
	fi

	echo "$module_version"
	log_function_data "module_version: $module_version"
	eval $LOGFE
}


## create array of network cards
get_networking_data()
{
	eval $LOGFS
	
	local B_USB_NETWORKING='false' a_temp=''
	
	IFS=$'\n'
	A_NETWORK_DATA=( $( 
	echo "$LSPCI_V_DATA" | gawk '
	# NOTE: see version 2.1.28 or earlier for old logic if for some reason it is needed again
	# that used a modified string made from nic name for index, why, I have no idea, makes no sense and leads
	# to wrong ordered output as well. get_audio_data uses the old logic for now too.
	BEGIN {
		IGNORECASE=1
		counter=0 
	}
	/^[0-9a-f:\.]+ ((ethernet|network) (controller|bridge)|infiniband)/ || /^[0-9a-f:\.]+ [^:]+: .*(ethernet|infiniband|network).*$/ {
		aNic[counter]=gensub(/^[0-9a-f:\.]+ [^:]+: (.+)$/,"\\1","g",$0)
		#gsub(/realtek semiconductor/, "Realtek", aNic[counter])
		#gsub(/davicom semiconductor/, "Davicom", aNic[counter])
		# The doublequotes are necessary because of the pipes in the variable.
		gsub(/'"$BAN_LIST_NORMAL"'/, "", aNic[counter])
		gsub(/'"$BAN_LIST_ARRAY"'/, " ", aNic[counter])
		if ( '$COLS_INNER' < 100 ){
			sub(/PCI Express/,"PCIE", aNic[counter])
		}
		gsub(/^ +| +$/, "", aNic[counter])
		gsub(/ [ \t]+/, " ", aNic[counter])
		aPciBusId[counter] = gensub(/(^[0-9a-f:\.]+) [^:]+: .+$/,"\\1","g",$0)
		while ( getline && !/^$/ ) {
			gsub(/'"$BAN_LIST_ARRAY"'/, "", $0)
			if ( /^[[:space:]]*I\/O/ ) {
				aPorts[counter] = aPorts[counter] $4 " "
			}
			if ( /driver in use/ ) {
				aDrivers[counter] = aDrivers[counter] gensub( /(.*): (.*)/ ,"\\2" ,"g" ,$0 ) ""
			}
			else if ( /kernel modules/ ) {
				aModules[counter] = aModules[counter] gensub( /(.*): (.*)/ ,"\\2" ,"g" ,$0 ) ""
			}
		}
		counter++
	}
	END {
		for (i=0;i<counter;i++) {
			useDrivers=""
			usePorts=""
			useModules=""
			useNic=""
			usePciBusId=""

			## note: this loses the plural ports case, is it needed anyway?
			if ( aPorts[i] != "" ) {
				usePorts = aPorts[i]
			}
			if ( aDrivers[i] != "" ) {
				useDrivers = aDrivers[i]
			}
			if ( aModules[i] != "" ) {
				useModules = aModules[i]
			}
			if ( aNic[i] != "" ) {
				useNic=aNic[i]
			}
			if ( aPciBusId[i] != "" ) {
				usePciBusId = aPciBusId[i]
			}
			# create array primary item for master array
			sub( / $/, "", usePorts ) # clean off trailing whitespace
			print useNic "," useDrivers "," usePorts "," useModules, "," usePciBusId
		}
	}' ) )
	IFS="$ORIGINAL_IFS"
	get_networking_usb_data
	if [[ $B_SHOW_ADVANCED_NETWORK == 'true' || $B_USB_NETWORKING == 'true' ]];then
		if [[ -z $BSD_TYPE ]];then
			get_network_advanced_data
		fi
	fi
	a_temp=${A_NETWORK_DATA[@]}
	log_function_data "A_NETWORK_DATA: $a_temp"
	
	eval $LOGFE
}

get_network_advanced_data()
{
	eval $LOGFS
	local a_network_adv_working='' if_data='' working_path='' working_uevent_path='' dir_path=''
	local if_id='' speed='' duplex='' mac_id='' oper_state=''  chip_id='' b_path_made='true'
	local usb_data='' usb_vendor='' usb_product='' product_path='' driver_test='' array_counter=0
	local full_path=''
	# we need to change to holder since we are updating the main array
	IFS=$'\n'
	local a_main_working=(${A_NETWORK_DATA[@]})
	IFS="$ORIGINAL_IFS"
	
	for (( i=0; i < ${#a_main_working[@]}; i++ ))
	do
		IFS=","
		a_network_adv_working=( ${a_main_working[i]} )
		IFS="$ORIGINAL_IFS"
		# reset these every go round
		driver_test=''
		if_data=''
		product_path=''
		usb_data=''
		usb_product=''
		usb_vendor=''
		working_path=''
		working_uevent_path=''
		if [[ -z $( grep '^usb-' <<< ${a_network_adv_working[4]} ) ]];then
			# note although this may exist technically don't use it, it's a virtual path
			# and causes weird cat errors when there's a missing file as well as a virtual path
			# /sys/bus/pci/devices/0000:02:02.0/net/eth1
			# real paths are: /sys/devices/pci0000:00/0000:00:1e/0/0000:02:02.0/net/eth1/uevent
			# and on older debian kernels: /sys/devices/pci0000:00/0000:02:02.0/net:eth1/uevent
			# but broadcom shows this sometimes, and older kernels maybe:
			# /sys/devices/pci0000:00/0000:00:01.0/0000:05:00.0/net/eth0/
			# /sys/devices/pci0000:00/0000:00:03.0/0000:03:00.0/ssb0:0/uevent:['DRIVER=b43', 'MODALIAS=ssb:v4243id0812rev0D']:
			# echo a ${a_network_adv_working[4]}
			if [[ -d /sys/bus/pci/devices/ ]];then
				working_path="/sys/bus/pci/devices/0000:${a_network_adv_working[4]}"
			elif [[ -d /sys/devices/pci0000:00/ ]];then
				working_path="/sys/devices/pci0000:00/0000:00:01.0/0000:${a_network_adv_working[4]}"
			fi
			#echo wp ${a_network_adv_working[4]} $i
			# now we want the real one, that xiin also displays, without symbolic links.
			if [[ -n $working_path && -e $working_path ]];then
				working_path=$( readlink -f $working_path 2>/dev/null )
			else
				working_path=$( find -P /sys/ -type d -name "*:${a_network_adv_working[4]}" 2>/dev/null )
				# just on off chance we get two returns, just one one
				working_path=${working_path%% *}
			fi
			# sometimes there is another directory between the path and /net
			if [[ -n $working_path && ! -e $working_path/net ]];then
				# using find here, probably will need to also use it in usb part since the grep
				# method seems to not be working now. Slice off the rest, which leaves the basic path
				working_path=$( find $working_path/*/net/*/uevent 2>/dev/null | \
				sed 's|/net.*||' )
			fi
			# working_path=$( ls /sys/devices/pci*/*/0000:${a_network_adv_working[4]}/net/*/uevent  )
		else
			# now we'll use the actual vendor:product string instead
			usb_data=${a_network_adv_working[10]}
			usb_vendor=$( cut -d ':' -f 1 <<< $usb_data )
			usb_product=$( cut -d ':' -f 2 <<< $usb_data )
			# this grep returns the path plus the contents of the file, with a colon separator, so slice that off
			# /sys/devices/pci0000:00/0000:00:1a.0/usb1/1-1/1-1.1/idVendor
			working_path=$( grep -s "$usb_vendor" /sys/devices/pci*/*/usb*/*/*/idVendor | \
			sed -e "s/idVendor:$usb_vendor//"  -e '/driver/d' )
			# try an alternate path if first one doesn't work
			# /sys/devices/pci0000:00/0000:00:0b.1/usb1/1-1/idVendor
			if [[ -z $working_path ]];then
				working_path=$( grep -s "$usb_vendor" /sys/devices/pci*/*/usb*/*/idVendor | \
				sed -e "s/idVendor:$usb_vendor//"  -e '/driver/d' )
				product_path=$( grep -s "$usb_product" /sys/devices/pci*/*/usb*/*/idProduct | \
				sed -e "s/idProduct:$usb_product//" -e '/driver/d' )
			else
				product_path=$( grep -s "$usb_product" /sys/devices/pci*/*/usb*/*/*/idProduct | \
				sed -e "s/idProduct:$usb_product//" -e '/driver/d' )
			fi
			# make sure it's the right product/vendor match here, it will almost always be but let's be sure
			if [[ -n $working_path && -n $product_path ]] && [[ $working_path == $product_path ]];then
			#if [[ -n $working_path ]];then
				# now ls that directory and get the numeric starting sub directory and that should be the full path
				# to the /net directory part
				dir_path=$( ls $working_path 2>/dev/null | grep -sE '^[0-9]' )
				working_uevent_path="$working_path$dir_path"
			fi
		fi
		# /sys/devices/pci0000:00/0000:00:1d.0/usb2/2-1/2-1.2/2-1.2:1.0/uevent grep for DRIVER=
		# /sys/devices/pci0000:00/0000:00:0b.1/usb1/1-1/1-1:1.0/uevent
		if [[ -n $usb_data ]];then
			driver_test=$( grep -si 'DRIVER=' $working_uevent_path/uevent | cut -d '=' -f 2 )
			if [[ -n $driver_test ]];then
				a_network_adv_working[1]=$driver_test
			fi
		fi
		#echo wp: $working_path
		log_function_data "PRE: working_path: $working_path\nworking_uevent_path: $working_uevent_path"
		# this applies in two different cases, one, default, standard, two, for usb, this is actually
		# the short path, minus the last longer numeric directory name, ie: 
		# from debian squeeze 2.6.32-5-686: 
		# /sys/devices/pci0000:00/0000:00:0b.1/usb1/1-1/net/wlan0/address
		if [[ -e $working_path/net ]];then
			# in cases like infiniband dual port devices, there can be two ids, like ib0 ib1, 
			# with line break in output
			if_data=$( ls $working_path/net 2>/dev/null )
			b_path_made='false'
		# this is the normal usb detection if the first one didn't work
		elif [[ -n $usb_data && -e $working_uevent_path/net ]];then
			if_data=$( ls $working_uevent_path/net 2>/dev/null )
			working_path=$working_uevent_path/net/$if_data
		# 2.6.32 debian lenny kernel shows not: /net/eth0 but /net:eth0
		elif [[ -n ${working_path/\/sys*/} ]];then
			if_data=$( ls $working_path 2>/dev/null | grep 'net:' )
			if [[ -n $if_data ]];then
				working_path=$working_path/$if_data
				# we won't be using this for path any more, just the actual if id output
				# so prep it for the loop below
				if_data=$( cut -d ':' -f 2 <<< "$if_data" )
			fi
		fi
		# just in case we got a failed path, like /net or /, clear it out for tests below
		if [[ -n ${working_path/\/sys*/} ]];then
			working_path=''
		fi
		#echo id: $if_data
		log_function_data "POST: working_path: $working_path\nif_data: $if_data - if_id: $if_id"
		# there are virtual devices that will have no if data but which we still want in the array
		# as it loops. These will also have null working_path as well since no **/net is found
		# echo if_data: $if_data
		if [[ -z $if_data ]];then
			if_data='null-if-id'
		fi
		## note: in cases of dual ports with different ids, this loop will create extra array items
		for if_item in $if_data
		do
			chip_id=
			duplex=''
			full_path=''
			if_id=''
			mac_id=''
			oper_state=''
			speed=''
			# strip out trailing spaces
			if_item=${if_item%% }
			#echo wp1: $working_path
			if [[ $working_path != '' ]];then
				if_id=$if_item
				if [[ $b_path_made == 'false' ]];then
					full_path=$working_path/net/$if_item
				else
					full_path=$working_path
				fi
				if [[ -r $full_path/speed ]];then
					speed=$( cat $full_path/speed 2>/dev/null )
				fi
				if [[ -r $full_path/duplex ]];then
					duplex=$( cat $full_path/duplex 2>/dev/null )
				fi
				if [[ -r $full_path/address ]];then
					mac_id=$( cat $full_path/address 2>/dev/null )
				fi
				if [[ -r $full_path/operstate ]];then
					oper_state=$( cat $full_path/operstate 2>/dev/null )
				fi
				if [[ -n ${a_network_adv_working[10]} ]];then
					chip_id=${a_network_adv_working[10]}
				fi
			fi
			
			#echo fp: $full_path 
			#echo id: $if_id
			# echo "$if_data ii:  $if_item $array_counter i: $i"
			A_NETWORK_DATA[$array_counter]=${a_network_adv_working[0]}","${a_network_adv_working[1]}","${a_network_adv_working[2]}","${a_network_adv_working[3]}","${a_network_adv_working[4]}","$if_id","$oper_state","$speed","$duplex","$mac_id","$chip_id
			
			((array_counter++))
		done
	done
	a_temp=${A_NETWORK_DATA[@]}
	log_function_data "A_NETWORK_DATA (advanced): $a_temp"

	eval $LOGFE
}

get_networking_usb_data()
{
	eval $LOGFS
	local lsusb_path='' lsusb_data='' a_usb='' array_count=''
	
	# now we'll check for usb wifi, a work in progress
	# USB_NETWORK_SEARCH
	# alsa usb detection by damentz
	# for every sound card symlink in /proc/asound - display information about it
	lsusb_path=$( type -p lsusb )
	# if lsusb exists, the file is a symlink, and contains an important usb exclusive file: continue
	if [[ -n $lsusb_path ]]; then
		# send error messages of lsusb to /dev/null as it will display a bunch if not a super user
		lsusb_data="$( $lsusb_path 2>/dev/null )"
		# also, find the contents of usbid in lsusb and print everything after the 7th word on the
		# corresponding line. Finally, strip out commas as they will change the driver :)
		if [[ -n $lsusb_data ]];then
			IFS=$'\n'
			a_usb=( $( 
			gawk '
			BEGIN {
				IGNORECASE=1
				string=""
				separator=""
			}
			/'"$USB_NETWORK_SEARCH"'/ && !/bluetooth| hub|keyboard|mouse|printer| ps2|reader|scan|storage/ {
				string=""
				gsub(/'"$BAN_LIST_ARRAY"'/, " ", $0 )
				gsub(/'"$BAN_LIST_NORMAL"'/, "", $0)
				gsub(/ [ \t]+/, " ", $0)
				#sub(/realtek semiconductor/, "Realtek", $0)
				#sub(/davicom semiconductor/, "Davicom", $0)
				#sub(/Belkin Components/, "Belkin", $0)
				
				for ( i=7; i<= NF; i++ ) {
					string = string separator $i
					separator = " "
				}
				if ( $2 != "" ){
					sub(/:/, "", $4 )
					print string ",,,,usb-" $2 "-" $4 ",,,,,," $6
				}
			}' <<< "$lsusb_data" ) )
			IFS="$ORIGINAL_IFS"
			if [[ ${#a_usb[@]} -gt 0 ]];then
				array_count=${#A_NETWORK_DATA[@]}
				for (( i=0; i < ${#a_usb[@]}; i++ ))
				do
					A_NETWORK_DATA[$array_count]=${a_usb[i]}
					((array_count++))
				done
				# need this to get the driver data for -N regular output, but no need
				# to run the advanced stuff unless required
				B_USB_NETWORKING='true'
			fi
		fi
	fi
# 	echo $B_USB_NETWORKING
	eval $LOGFE
}

get_networking_wan_ip_data()
{
	eval $LOGFS
	local ip='' ip_data='' downloader_error=0 ua='' b_ipv4_good=true no_check_ssl=''
	
	# get ip using wget redirect to stdout. This is a clean, text only IP output url,
	# single line only, ending in the ip address. May have to modify this in the future
	# to handle ipv4 and ipv6 addresses but should not be necessary.
	# ip=$( echo  2001:0db8:85a3:0000:0000:8a2e:0370:7334 | gawk  --re-interval '
	# ip=$( wget -q -O - $WAN_IP_URL | gawk  --re-interval '
	# this generates a direct dns based ipv4 ip address, but if opendns.com goes down, 
	# the fall backs will still work. 
	# note: consistently slower than domain based: dig +short +time=1 +tries=1 myip.opendns.com. A @208.67.222.222
	if [[ -n $DNSTOOL ]];then
		ip=$( dig +short +time=1 +tries=1 myip.opendns.com @resolver1.opendns.com 2>/dev/null)
	fi
	if [[ $ip == '' ]];then
		case $DOWNLOADER in
			curl)
				if [[ -n $( grep 'smxi.org' <<< $WAN_IP_URL ) ]];then
					ua="-A s-tools/inxi-ip"
				fi
				ip_data="$( curl $NO_SSL_OPT $ua -y $DL_TIMEOUT -s $WAN_IP_URL )" || downloader_error=$?
				;;
			fetch)
				ip_data="$( fetch $NO_SSL_OPT -T $DL_TIMEOUT -q -o - $WAN_IP_URL )" || downloader_error=$?
				;;
			ftp)
				ip_data="$( ftp $NO_SSL_OPT -o - $WAN_IP_URL 2>/dev/null )" || downloader_error=$?
				;;
			wget)
				if [[ -n $( grep 'smxi.org' <<< $WAN_IP_URL ) ]];then
					ua="-U s-tools/inxi-ip"
				fi
				ip_data="$( wget $NO_SSL_OPT $ua -T $DL_TIMEOUT -q -O - $WAN_IP_URL )" || downloader_error=$?
				;;
			no-downloader)
				downloader_error=1
				;;
		esac
		ip=$( gawk  --re-interval '
		{
			#gsub("\n","",$2")
			print $NF
		}' <<< "$ip_data" )
	fi
	
	# validate the data
	if [[ -z $ip ]];then
		ip='None Detected!'
	elif [[ -z $( grep -Es \
	'^([0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}|[[:alnum:]]{0,4}:[[:alnum:]]{0,4}:[[:alnum:]]{0,4}:[[:alnum:]]{0,4}:[[:alnum:]]{0,4}:[[:alnum:]]{0,4}:[[:alnum:]]{0,4}:[[:alnum:]]{0,4})$' <<< $ip ) ]];then
		ip='IP Source Corrupt!'
	fi
	echo "$ip"
	log_function_data "ip: $ip"
	eval $LOGFE
}

get_networking_local_ip_data()
{
	eval $LOGFS
	
	local ip_tool_command=$( type -p ip )
	local a_temp='' ip_tool='ip' ip_tool_data=''
	# the chances for all new systems to have ip by default are far higher than
	# the deprecated ifconfig. Only try for ifconfig if ip is not present in system
	if [[ -z $ip_tool_command ]];then
		ip_tool_command=$( type -p ifconfig )
		ip_tool='ifconfig'
	else
		ip_tool_command="$ip_tool_command addr"
	fi
	if [[ -n "$ip_tool_command" ]];then
		if [[ $ip_tool == 'ifconfig' ]];then
			ip_tool_data="$( $ip_tool_command | gawk '
			{
				line=gensub(/^([a-z]+[0-9][:]?[[:space:]].*)/, "\n\\1", $0)
				print line
			}' )"
		# note, ip addr does not have proper record separation, so creating new lines explicitly here at start
		# of each IF record item. Also getting rid of the unneeded numeric line starters, now it can be parsed 
		# like ifconfig more or less
		elif [[ $ip_tool == 'ip' ]];then
			ip_tool_data="$( eval $ip_tool_command | sed 's/^[0-9]\+:[[:space:]]\+/\n/' )"
		fi
	fi
	if [[ -z $ip_tool_command ]];then
		A_INTERFACES_DATA=( "Interfaces program 'ip' missing. Please check: $SELF_NAME --recommends" )
	elif [[ -n "$ip_tool_data" ]];then
		IFS=$'\n' # $ip_tool_command
		A_INTERFACES_DATA=( $( 
		gawk -v ipTool=$ip_tool -v bsdType=$BSD_TYPE '
		BEGIN {
			IGNORECASE=1
			addExtV6 = ""
			addIpV6 = ""
			interface=""
			ipExtV6=""
			ifIpV4=""
			ifIpV6=""
			ifMask=""
		}
		# skip past the lo item
		/^lo/ {
			while (getline && !/^$/ ) {
				# do nothing, just get past this entry item
			}
		}
		/^[a-zA-Z]+[0-9]/ {
			# not clear on why inet is coming through, but this gets rid of it
			# as first line item.
			gsub(/'"$BAN_LIST_ARRAY"'/, " ", $0)
			gsub(/^ +| +$/, "", $0)
			gsub(/ [ \t]+/, " ", $0)
			interface = $1
			# prep this this for ip addr: eth0: but NOT eth0:1
			sub(/:$/, "", interface)
			ifIpV4=""
			ifIpV6=""
			ifMask=""
			ipExtV6=""
			aInterfaces[interface]++
			
			while (getline && !/^$/ ) {
				addIpV6 = ""
				addExtV6 = ""
				if ( ipTool == "ifconfig" ) {
					if (/inet addr:/) {
						ifIpV4 = gensub( /addr:([0-9\.]+)/, "\\1", "g", $2 )
						if (/mask:/) {
							ifMask = gensub( /mask:([0-9\.]+)/, "\\1", "g", $NF )
						}
					}
					if (/inet6 addr:/) {
						# ^fe80:
						if ( $2 ~ /^fe80/) { 
							addIpV6 = $2
						}
						else if ( $0 ~ /<global>/ || $0 ~ /Scope:Global/ ) { 
							addExtV6 = "sg~" $2
						}
						# ^fec0:
						else if ( $0 ~ /<site>/ || $0 ~ /Scope:Site/ || $2 ~ /^fec0/ || $2 ~ /^fc00/) { 
							addExtV6 = "ss~" $2
						}
						else {
							addExtV6 = "su~" $2
						}
					}
					if ( bsdType == "bsd" ) {
						if ( $1 == "inet" ) {
							ifIpV4 = $2
							if ( $3 == "netmask" ) {
								ifMask = $4
							}
						}
						# bsds end ip with %em1 (% + interface name)
						if ( $0 ~ /inet6.*%/ ){
							sub(/%.*/,"",$2)
							if ( $2 ~ /^fe80/ ) {
								addIpV6 = $2
							}
							else if ( $2 ~ /^fec0/ || $2 ~ /^fc00/ ) {
								addExtV6 = "ss~" $2
							}
							else {
								addExtV6 = "sg~" $2
							}
						}
					}
				}
				else if ( ipTool == "ip" ) {
					if ( $1 == "inet" ) {
						ifIpV4 = $2
					}
					if ( $1 == "inet6" ){
						# filter out deprecated IPv6 privacy addresses
						if ( $0 ~ / temporary deprecated/) { 
							addExtV6 = ""
						}
						else if ( $0 ~ /scope global temporary/) { 
							addExtV6 = "st~" $2
						}
						else if ( $0 ~ /scope global/) { 
							addExtV6 = "sg~" $2
						}
						# ^fe80:
						else if ( $2 ~ /^fe80/ || $0 ~ /scope link/) { 
							addIpV6 = $2
						}
						# ^fec0:
						else if ( $2 ~ /^fec0/ || $2 ~ /^fc00/ || $0 ~ /scope site/) { 
							addExtV6 = "ss~" $2
						}
						else {
							addExtV6 = "su~" $2
						}
					}
				}
				if ( addIpV6 != "" ) {
					if ( ifIpV6 == "" ) {
						ifIpV6 = addIpV6
					}
					else {
						ifIpV6 = ifIpV6 "^" addIpV6
					}
				}
				if (addExtV6 != "" ){
					if ( ipExtV6 == "" ){
						ipExtV6 = addExtV6
					}
					else {
						ipExtV6 = ipExtV6 "^" addExtV6
					}
				}
			}
			# slice off the digits that are sometimes tacked to the end of the address, 
			# like: /64 or /24
			sub(/\/[0-9]+/, "", ifIpV4)
			gsub(/\/[0-9]+/, "", ifIpV6) #
			ipAddresses[interface] = ifIpV4 "," ifMask "," ifIpV6 "," ipExtV6
		}
		END {
			j=0
			for (i in aInterfaces) {
				ifData = ""
				a[j] = i
				if (ipAddresses[i] != "") {
					ifData = ipAddresses[i]
				}
				# create array primary item for master array
				# tested needed to avoid bad data from above, if null it is garbage
				# this is the easiest way to handle junk I found, improve if you want
				if ( ifData != "" ) {
					print a[j] "," ifData
				}
				j++
			}
		}' <<< "$ip_tool_data" ) )
		IFS="$ORIGINAL_IFS"
	else
		A_INTERFACES_DATA=( "Interfaces program $ip_tool present but created no data. " )
	fi
	a_temp=${A_INTERFACES_DATA[@]}
	log_function_data "A_INTERFACES_DATA: $a_temp"
	eval $LOGFE
}
# get_networking_local_ip_data;exit

get_optical_drive_data()
{
	eval $LOGFS
	
	local a_temp='' sys_uevent_path='' proc_cdrom='' link_list=''
	local separator='' linked='' working_disk='' disk='' item_string='' proc_info_string='' 
	local dev_disks_full=''
	dev_disks_full="$( ls /dev/dvd* /dev/cd* /dev/scd* /dev/sr* /dev/fd[0-9] 2>/dev/null | grep -vE 'random' )"
	## Not using this now because newer kernel is NOT linking all optical drives. Some, but not all
	# Some systems don't support xargs -L plus the unlinked optical drive unit make this not a good option
	# get the actual disk dev location, first try default which is easier to run, need to preserve line breaks
	# local dev_disks_real="$( echo "$dev_disks_full" | xargs -L 1 readlink 2>/dev/null | sort -u )"
	
	#echo ddl: $dev_disks_full
	for working_disk in $dev_disks_full
	do
		disk=$( readlink $working_disk 2>/dev/null )
		if [[ -z $disk ]];then
			disk=$working_disk
		fi
		disk=${disk##*/}  # puppy shows this as /dev/sr0, not sr0
		# if [[ -z $dev_disks_real || -z $( grep $disk <<< $dev_disks_real ) ]];then
		if [[ -n $disk && -z $( grep "$disk" <<< $dev_disks_real ) ]];then
			# need line break IFS for below, no white space
			dev_disks_real="$dev_disks_real$separator$disk"
			separator=$'\n'
			#separator=' '
		fi
	done
	dev_disks_real="$( sort -u <<< "$dev_disks_real" )"
	working_disk=''
	disk=''
	separator=''
	#echo ddr: $dev_disks_real

	# A_OPTICAL_DRIVE_DATA indexes: not going to use all these, but it's just as easy to build the full
	# data array and use what we need from it as to update it later to add features or items
	# 0 - true dev path, ie, sr0, hdc
	# 1 - dev links to true path
	# 2 - device vendor - for hdx drives, vendor model are one string from proc
	# 3 - device model
	# 4 - device rev version
	# 5 - speed
	# 6 - multisession support
	# 7 - MCN support
	# 8 - audio read
	# 9 - cdr
	# 10 - cdrw
	# 11 - dvd read
	# 12 - dvdr
	# 13 - dvdram
	# 14 - state
	
	if [[ -n $dev_disks_real ]];then
		if [[ $B_SHOW_FULL_OPTICAL == 'true' ]];then
			proc_cdrom="$( cat /proc/sys/dev/cdrom/info 2>/dev/null )"
		fi
		IFS=$'\n'
		A_OPTICAL_DRIVE_DATA=( $(
		for disk in $dev_disks_real
		do
			for working_disk in $dev_disks_full 
			do
				if [[ -n $( readlink $working_disk | grep $disk ) ]];then
					linked=${working_disk##*/}
					link_list="$link_list$separator$linked"
					separator='~'
				fi
			done
			item_string="$disk,$link_list"
			link_list=''
			linked=''
			separator=''
			vendor=''
			model=''
			proc_info_string=''
			rev_number=''
			state=""
			sys_path=''
			working_disk=''
			# this is only for new sd type paths in /sys, otherwise we'll use /proc/ide
			if [[ -z $( grep '^hd' <<< $disk ) ]];then
				# maybe newer kernels use this, not enough data.
				sys_path=$( ls /sys/devices/pci*/*/ata*/host*/target*/*/block/$disk/uevent 2>/dev/null | sed "s|/block/$disk/uevent||" )
				# maybe older kernels, this used to work (2014-03-16)
				if [[ -z $sys_path ]];then
					sys_path=$( ls /sys/devices/pci*/*/host*/target*/*/block/$disk/uevent 2>/dev/null | sed "s|/block/$disk/uevent||" )
				fi
				# no need to test for errors yet, probably other user systems will require some alternate paths though
				if [[ -n $sys_path ]];then
					vendor=$( cat $sys_path/vendor 2>/dev/null )
					model=$( cat $sys_path/model 2>/dev/null | sed 's/^[[:space:]]*//;s/[[:space:]]*$//;s/,//g' )
					state=$( cat $sys_path/state 2>/dev/null | sed 's/^[[:space:]]*//;s/[[:space:]]*$//;s/,//g' )
					rev_number=$( cat $sys_path/rev 2>/dev/null | sed 's/^[[:space:]]*//;s/[[:space:]]*$//;s/,//g' )
				fi
			elif [[ -e /proc/ide/$disk/model ]];then
				vendor=$( cat /proc/ide/$disk/model 2>/dev/null )
			fi
			if [[ -n $vendor ]];then
				vendor=$( gawk '
				BEGIN {
					IGNORECASE=1
				}
				{
					gsub(/'"$BAN_LIST_NORMAL"'/, "", $0)
					sub(/TSSTcorp/, "TSST ", $0) # seen more than one of these weird ones
					gsub(/'"$BAN_LIST_ARRAY"'/, " ", $0)
					gsub(/^[[:space:]]*|[[:space:]]*$/, "", $0)
					gsub(/ [[:space:]]+/, " ", $0)
					print $0
				}'	<<< $vendor )
			fi
			# this needs to run no matter if there's proc data or not to create the array comma list
			if [[ $B_SHOW_FULL_OPTICAL == 'true' ]];then
				proc_info_string=$( gawk -v diskId=$disk '
				BEGIN {
					IGNORECASE=1
					position=""
					speed=""
					multisession=""
					mcn=""
					audio=""
					cdr=""
					cdrw=""
					dvd=""
					dvdr=""
					dvdram=""
				}
				# first get the position of the device name from top field
				# we will use this to get all the other data for that column
				/drive name:/ {
					for ( position=3; position <= NF; position++ ) {
						if ( $position == diskId ) {
							break
						}
					}
				}
				/drive speed:/ {
					speed = $position
				}
				/Can read multisession:/ {
					multisession=$( position + 1 )
				}
				/Can read MCN:/ {
					mcn=$( position + 1 )
				}
				/Can play audio:/ {
					audio=$( position + 1 )
				}
				/Can write CD-R:/ {
					cdr=$( position + 1 )
				}
				/Can write CD-RW:/ {
					cdrw=$( position + 1 )
				}
				/Can read DVD:/ {
					dvd=$( position + 1 )
				}
				/Can write DVD-R:/ {
					dvdr=$( position + 1 )
				}
				/Can write DVD-RAM:/ {
					dvdram=$( position + 1 )
				}
				END {
					print speed "," multisession "," mcn "," audio "," cdr "," cdrw "," dvd "," dvdr "," dvdram
				}
				' <<< "$proc_cdrom" )
			fi
			item_string="$item_string,$vendor,$model,$rev_number,$proc_info_string,$state"
			echo $item_string
		done \
		) )
		IFS="$ORIGINAL_IFS"
	fi
	a_temp=${A_OPTICAL_DRIVE_DATA[@]}
	# echo "$a_temp"
	log_function_data "A_OPTICAL_DRIVE_DATA: $a_temp"
	eval $LOGFE
}
# get_optical_drive_data;exit

get_optical_drive_data_bsd()
{
	eval $LOGFS
	
	local a_temp=''
	
	if [[ -n $DMESG_BOOT_DATA ]];then
		IFS=$'\n'
		A_OPTICAL_DRIVE_DATA=( $( gawk -F ':' '
		BEGIN {
			IGNORECASE=1
		}
		# sde,3.9GB,STORE_N_GO,USB,C200431546D3CF49-0:0,0
		# sdd,250.1GB,ST3250824AS,,9ND08GKX,45
		$1 ~ /^(cd|dvd)[0-9]+/ {
			diskId=gensub(/^((cd|dvd)[0-9]+)[^0-9].*/,"\\1",1,$1)
			# note: /var/run/dmesg.boot may repeat items since it is not created
			# fresh every boot, this way, only the last items will be used per disk id
			if (aIds[diskId] == "" ) {
				aIds[diskId]=diskId
			}
			aDisks[diskId, "id"] = diskId
			if ( $NF ~ /<.*>/ ){
				gsub(/.*<|>.*/,"",$NF)
				rev_number=gensub(/.*[^0-9\.]([0-9\.]+)$/,"\\1",1,$NF)
				if (rev_number ~ /^[0-9\.]+$/) {
					aDisks[diskId, "rev"] = rev_number
				}
				model=gensub(/(.*[^0-9\.])[0-9\.]+$/,"\\1",1,$NF)
				sub(/[[:space:]]+$/,"",model)
				aDisks[diskId, "model"] = model
			}
			if ( $NF ~ /serial number/ ){
				sub(/serial[[:space:]]+number[[:space:]]*/,"",$NF)
				aDisks[diskId, "serial"] = $NF
			}
			if ( $NF ~ /[GM]B\/s/ ){
				speed=gensub(/^([0-9\.]+[[:space:]]*[GM]B\/s).*/,"\\1",1,$NF)
				sub(/\.[0-9]+/,"",speed)
				if ( speed ~ /^[0-9]+/ ) {
					aDisks[diskId, "speed"] = speed
				}
			}
		}
		# "$link,dev-readlinks,$vendor,$model,$rev_number,$proc_info_string,$state"
		# $proc_info_string: print speed "," multisession "," mcn "," audio "," cdr "," cdrw "," dvd "," dvdr "," dvdram
		END {
			# multi dimensional pseudo arrays are sorted at total random, not in order of
			# creation, so force a sort of the aIds, which deletes the array index but preserves
			# the sorted keys.
			asort(aIds) 
			for ( key in aIds ) {
				print aDisks[aIds[key], "id"] ",,," aDisks[aIds[key], "model"] "," aDisks[aIds[key], "rev"] "," aDisks[aIds[key], "speed"] ",,,,,,,," 
			}
		}' <<< "$DMESG_BOOT_DATA" ) )
		IFS="$ORIGINAL_IFS"
	fi
	
	a_temp=${A_OPTICAL_DRIVE_DATA[@]}
	# echo ${a_temp[@]}
	log_function_data "A_OPTICAL_DRIVE_DATA: $a_temp"
	
	eval $LOGFE
}

get_partition_data()
{
	eval $LOGFS
	
	local a_part_working='' dev_item='' a_temp='' dev_working_item='' 
	local swap_data='' df_string='' main_partition_data='' fs_type=''
	local mount_data='' dev_bsd_item=''
	#local excluded_file_types='--exclude-type=aufs --exclude-type=tmpfs --exclude-type=iso9660'
	# df doesn't seem to work in script with variables like at the command line
	# added devfs linprocfs sysfs fdescfs which show on debian kfreebsd kernel output
	if [[ -z $BSD_TYPE ]];then
		swap_data="$( swapon -s 2>/dev/null )"
		df_string='df -h -T -P --exclude-type=aufs --exclude-type=devfs --exclude-type=devtmpfs 
		--exclude-type=fdescfs --exclude-type=iso9660 --exclude-type=linprocfs --exclude-type=procfs
		--exclude-type=squashfs --exclude-type=sysfs --exclude-type=tmpfs --exclude-type=unionfs'
	else
		swap_data="$( swapctl -l -k 2>/dev/null )"
		# default size is 512, -H only for size in human readable format
		# older bsds don't support -T, pain, so we'll use partial output there
		if df -h -T &>/dev/null;then
			df_string='df -h -T'
		else
			df_string='df -h'
		fi
	fi
	
	main_partition_data="$( eval $df_string )"
	# set dev disk label/mapper/uuid data globals
	get_partition_dev_data 'label'
	get_partition_dev_data 'mapper'
	get_partition_dev_data 'uuid'
	
	log_function_data 'raw' "main_partition_data:\n$main_partition_data\n\nswap_data:\n$swap_data"
	
	# new kernels/df have rootfs and / repeated, creating two entries for the same partition
	# so check for two string endings of / then slice out the rootfs one, I could check for it
	# before slicing it out, but doing that would require the same action twice re code execution
	if [[ $( grep -cs '[[:space:]]/$' <<< "$main_partition_data" ) -gt 1 ]];then
		main_partition_data="$( grep -vs '^rootfs' <<< "$main_partition_data" )"
	fi
	# echo "$main_partition_data"
	log_function_data 'raw' "main_partition_data_post_rootfs:\n$main_partition_data\n\nswap_data:\n$swap_data"
	IFS=$'\n'
	# $NF = partition name; $(NF - 4) = partition size; $(NF - 3) = used, in gB; $(NF - 1) = percent used
	## note: by subtracting from the last field number NF, we avoid a subtle issue with LVM df output, where if
	## the first field is too long, it will occupy its own line, this way we are getting only the needed data
	A_PARTITION_DATA=( $( echo "$main_partition_data" | gawk -v bsdType="$BSD_TYPE" -v bsdVersion="$BSD_VERSION" '
	BEGIN {
		IGNORECASE=1
		fileSystem=""
	}
	# this has to be nulled for every iteration so it does not retain value from last iteration
	devBase=""
	# skipping these file systems because bsds do not support df --exclude-type=<fstype>
	# note that using $1 to handle older bsd df, which do not support -T. This will not be reliable but we will see
	( bsdType != "" ) {
		# skip if non disk/partition, or if raid primary id, which will not have a / in it. 
		# Note: kfreebsd uses /sys, not sysfs, is this a bug or expected behavior?
		if ( $1 ~ /^(aufs|devfs|devtmpfs|fdescfs|iso9660|linprocfs|procfs|squashfs|\/sys|sysfs|tmpfs|type|unionfs)$/ || 
		( $1 ~ /^([^\/]+)$/ && $1 !~ /^ROOT/ ) ) {
			# note use next, not getline or it does not work right
			next 
		}
	}
	# this is required because below we are subtracting from NF, so it has to be > 5
	# the real issue is long file system names that force the wrap of df output: //fileserver/main
	# but we still need to handle more dynamically long space containing file names, but later.
	# Using df -P should fix this, ie, no wrapping of line lines, but leaving this for now
	( NF < 6 ) && ( $0 !~ /[0-9]+%/ ) {
		# set the dev location here for cases of wrapped output
		if ( NF == 1 ) {
			devBase=gensub( /^(\/dev\/)(.+)$/, "\\2", 1, $1 )
		}
		getline
	}
	
	# next set devBase if it didn not get set above here
	( devBase == "" ) && ( $1 ~ /^\/dev\/|:\/|\/\// ) {
		devBase=gensub( /^(\/dev\/)(.+)$/, "\\2", 1, $1 )
	}
	# this handles zfs type devices/partitions, which do not start with / but contain /
	( bsdType != "" && devBase == "" && $1 ~ /^[^\/]+\/.+/ ) {
		devBase=gensub( /^([^\/]+\/)([^\/]+)$/, "non-dev-\\1\\2", 1, $1 )
	}
	# this handles yet another fredforfaen special case where a mounted drive
	# has the search string in its name
	$NF ~ /^\/$|^\/boot$|^\/var$|^\/var\/tmp$|^\/var\/log$|^\/home$|^\/opt$|^\/tmp$|^\/usr$/ {
		# note, older df in bsd do not have file system column
		if ( NF == "7" && $(NF - 1) ~ /[0-9]+%/ ) {
			fileSystem=$(NF - 5)
		}
		else {
			fileSystem=""
		}
		# /dev/disk0s2    249G    24G   225G    10% 5926984 54912758   10%   /
		if ( bsdVersion == "darwin" && $(NF - 4) ~ /[0-9]+%/ ) {
			print $NF "," $(NF - 7) "," $(NF - 6) "," $(NF - 4) ",main," fileSystem "," devBase 
		}
		else {
			print $NF "," $(NF - 4) "," $(NF - 3) "," $(NF - 1) ",main," fileSystem "," devBase 
		}
	}
	# skip all these, including the first, header line. Use the --exclude-type
	# to handle new filesystems types we do not want listed here
	$NF !~ /^\/$|^\/boot$|^\/var$|^\/var\/tmp$|^\/var\/log$|^\/home$|^\/opt$|^\/tmp$|^\/usr$|^filesystem/ {
		# this is to avoid file systems with spaces in their names, that will make
		# the test show the wrong data in each of the fields, if no x%, then do not use
		# using 3 cases, first default, standard, 2nd, 3rd, handles one and two spaces in name
		if ( bsdVersion == "darwin" && $(NF - 4) ~ /[0-9]+%/ ) {
			fileSystem=""
			print $NF "," $(NF - 7) "," $(NF - 6) "," $(NF - 4) ",main," fileSystem "," devBase 
		}
		else if ( $(NF - 1) ~ /[0-9]+%/ ) {
			# note, older df in bsd do not have file system column
			if ( NF == "7" ) {
				fileSystem=$(NF - 5)
			}
			else {
				fileSystem=""
			}
			print $NF "," $(NF - 4) "," $(NF - 3) "," $(NF - 1) ",secondary," fileSystem "," devBase 
		}
		# these two cases construct the space containing name
		else if ( $(NF - 2) ~ /[0-9]+%/ ) {
			# note, older df in bsd do not have file system column
			if ( NF == "8" && $(NF - 6) !~ /^[0-9]+/ ) {
				fileSystem=$(NF - 6)
			}
			else {
				fileSystem=""
			}
			print $(NF - 1) " " $NF "," $(NF - 5) "," $(NF - 4) "," $(NF - 2) ",secondary," fileSystem "," devBase
		}
		else if ( $(NF - 3) ~ /[0-9]+%/ ) {
			# note, older df in bsd do not have file system column
			if ( NF == "9" && $(NF - 7) !~ /^[0-9]+/ ) {
				fileSystem=$(NF - 7)
			}
			else {
				fileSystem=""
			}
			print $(NF - 2) " " $(NF - 1) " " $NF "," $(NF - 6) "," $(NF - 5) "," $(NF - 3) ",secondary," fileSystem "," devBase 
		}
	}' )
	# now add the swap partition data, don't want to show swap files, just partitions,
	# though this can include /dev/ramzswap0. Note: you can also use /proc/swaps for this
	# data, it's the same exact output as swapon -s
	$( echo "$swap_data" | gawk -v bsdType=$BSD_TYPE '
	BEGIN {
		swapCounter = 1
		usedHolder=""
		sizeHolder=""
	}
	/^\/dev/ {
		if ( bsdType == "" ) {
			usedHolder=$4
			sizeHolder=$3
		}
		else {
			usedHolder=$3
			sizeHolder=$2
		}
		size = sprintf( "%.2f", sizeHolder*1024/1000**3 )
		devBase = gensub( /^(\/dev\/)(.+)$/, "\\2", 1, $1 )
		used = sprintf( "%.2f", usedHolder*1024/1000**3 )
		percentUsed = sprintf( "%.0f", ( usedHolder/sizeHolder )*100 )
		print "swap-" swapCounter "," size "GB," used "GB," percentUsed "%,main," "swap," devBase
		swapCounter = ++swapCounter
	}' ) )
	IFS="$ORIGINAL_IFS"
	
	a_temp=${A_PARTITION_DATA[@]}
	# echo $a_temp
	log_function_data "1: A_PARTITION_DATA:\n$a_temp"
	
	# we'll use this for older systems where no filesystem type is shown in df
	if [[ $BSD_TYPE == 'bsd' ]];then
		mount_data="$( mount )"
	fi
	# now we'll handle some fringe cases where irregular df -hT output shows /dev/disk/.. instead of 
	# /dev/h|sdxy type data for column 1, . A_PARTITION_DATA[6]
	# Here we just search for the uuid/label and then grab the end of the line to get the right dev item.
	for (( i=0; i < ${#A_PARTITION_DATA[@]}; i++ ))
	do
		IFS=","
		a_part_working=( ${A_PARTITION_DATA[i]} )
		IFS="$ORIGINAL_IFS"
		
		dev_item=${a_part_working[6]} # reset each loop
		fs_type=${a_part_working[5]}
		# older bsds have df minus -T so can't get fs type easily, try using mount instead
		if [[ $BSD_TYPE == 'bsd' ]] && [[ -z $fs_type && -n $dev_item ]];then
			dev_bsd_item=$( sed -e 's/non-dev-//' -e 's|/|\\/|g' <<< "$dev_item" )
			fs_type=$( gawk -v bsdVersion="$BSD_VERSION" -F '(' '
			BEGIN {
				IGNORECASE=1
				fileSystem=""
			}
			/'$dev_bsd_item'/ {
				if ( bsdVersion != "openbsd" ) {
					# slice out everything after / plus the first comma
					sub( /,.*/, "", $2 )
					fileSystem=$2
				}
				else {
					# for openbsd: /dev/wd0f on /usr type ffs (local, nodev)
					gsub(/^.*type[[:space:]]+|[[:space:]]*$/, "", $1 )
					fileSystem=$1
				}
				print fileSystem
				exit
			}' <<< "$mount_data" )
		fi
		# note: for swap this will already be set
		if [[ -n $( grep -E '(by-uuid|by-label)' <<< $dev_item ) ]];then
			dev_working_item=${dev_item##*/}
			if [[ -n $DEV_DISK_UUID ]];then
				dev_item=$( echo "$DEV_DISK_UUID" | gawk '
					$0 ~ /[ /t]'$dev_working_item'[ /t]/ {
						item=gensub( /..\/..\/(.+)/, "\\1", 1, $NF )
						print item
						exit
					}' )
			fi
			# if we didn't find anything for uuid try label
			if [[ -z $dev_item && -n $DEV_DISK_LABEL ]];then
				dev_item=$( echo "$DEV_DISK_LABEL" | gawk '
					$0 ~ /[ /t]'$dev_working_item'[ /t]/ {
						item=gensub( /..\/..\/(.+)/, "\\1", 1, $NF )
						print item
						exit
					}' )
			fi
		elif [[ -n $( grep 'mapper/' <<< $dev_item ) ]];then
			# get the mapper actual dev item
			dev_item=$( get_dev_processed_item "$dev_item" )
		fi
		
		if [[ -n $dev_item ]];then
			# assemble everything we could get for dev/h/dx, label, and uuid
			IFS=","
			A_PARTITION_DATA[i]=${a_part_working[0]}","${a_part_working[1]}","${a_part_working[2]}","${a_part_working[3]}","${a_part_working[4]}","$fs_type","$dev_item
			IFS="$ORIGINAL_IFS"
		fi
	done
	a_temp=${A_PARTITION_DATA[@]}
	# echo $a_temp;exit
	log_function_data "2: A_PARTITION_DATA:\n$a_temp"
	if [[ $B_SHOW_LABELS == 'true' || $B_SHOW_UUIDS == 'true' ]];then
		get_partition_data_advanced
	fi
	eval $LOGFE
}

# first get the locations of the mount points for label/uuid detection
get_partition_data_advanced()
{
	eval $LOGFS
	local a_part_working='' dev_partition_data=''
	local dev_item='' dev_label='' dev_uuid='' a_temp=''
	local mount_point=''
	# set dev disk label/mapper/uuid data globals
	get_partition_dev_data 'label'
	get_partition_dev_data 'mapper'
	get_partition_dev_data 'uuid'

	if [[ $B_MOUNTS_FILE == 'true' ]];then
		for (( i=0; i < ${#A_PARTITION_DATA[@]}; i++ ))
		do
			IFS=","
			a_part_working=( ${A_PARTITION_DATA[i]} )
			IFS="$ORIGINAL_IFS"
			
			# note: for swap this will already be set
			if [[ -z ${a_part_working[6]} ]];then
				
				mount_point=$( sed 's|/|\\/|g'  <<< ${a_part_working[0]} )
				#echo mount_point $mount_point
				dev_partition_data=$( gawk '
				BEGIN {
					IGNORECASE = 1
					partition = ""
					partTemp = ""
				}
				# trying to handle space in name
# 				gsub(/\\040/, " ", $0 )
				/[ \t]'$mount_point'[ \t]/ && $1 != "rootfs" {
					# initialize the variables
					label = ""
					uuid = ""

					# slice out the /dev
					partition=gensub( /^(\/dev\/)(.+)$/, "\\2", 1, $1 )
					# label and uuid can occur for root, set partition to null now
					if ( partition ~ /by-label/ ) {
						label=gensub( /^(\/dev\/disk\/by-label\/)(.+)$/, "\\2", 1, $1 )
						partition = ""
					}
					if ( partition ~ /by-uuid/ ) {
						uuid=gensub( /^(\/dev\/disk\/by-uuid\/)(.+)$/, "\\2", 1, $1 )
						partition = ""
					}

					# handle /dev/root for / id
					if ( partition == "root" ) {
						# if this works, great, otherwise, just set this to null values
						partTemp="'$( readlink /dev/root 2>/dev/null )'"
						if ( partTemp != "" ) {
							if ( partTemp ~ /[hsv]d[a-z]+[0-9]{1,2}/ ) {
								partition=gensub( /^(\/dev\/)(.+)$/, "\\2", 1, partTemp )
							}
							else if ( partTemp ~ /by-uuid/ ) {
								uuid=gensub( /^(\/dev\/disk\/by-uuid\/)(.+)$/, "\\2", 1, partTemp )
								partition="" # set null to let real location get discovered
							}
							else if ( partTemp ~ /by-label/ ) {
								label=gensub( /^(\/dev\/disk\/by-label\/)(.+)$/, "\\2", 1, partTemp )
								partition="" # set null to let real location get discovered
							}
						}
						else {
							partition = ""
							label = ""
							uuid = ""
						}
					}
					print partition "," label "," uuid
					exit
				}'	$FILE_MOUNTS )

				# assemble everything we could get for dev/h/dx, label, and uuid
				IFS=","
				A_PARTITION_DATA[i]=${a_part_working[0]}","${a_part_working[1]}","${a_part_working[2]}","${a_part_working[3]}","${a_part_working[4]}","${a_part_working[5]}","$dev_partition_data
				IFS="$ORIGINAL_IFS"
			fi
			## now we're ready to proceed filling in the data
			IFS=","
			a_part_working=( ${A_PARTITION_DATA[i]} )
			IFS="$ORIGINAL_IFS"
			# get the mapper actual dev item first, in case it's mapped
			dev_item=$( get_dev_processed_item "${a_part_working[6]}" )
			# make sure not to slice off rest if it's a network mounted file system
			if [[ -n $dev_item && -z $( grep -E '(^//|:/)' <<< $dev_item ) ]];then
				dev_item=${dev_item##*/} ## needed to avoid error in case name still has / in it
			fi
			dev_label=${a_part_working[7]}
			dev_uuid=${a_part_working[8]}
			# then if dev data/uuid is incomplete, try to get missing piece
			# it's more likely we'll get a uuid than a label. But this should get the
			# dev item set no matter what, so then we can get the rest of any missing data
			# first we'll get the dev_item if it's missing
			if [[ -z $dev_item ]];then
				if [[ -n $DEV_DISK_UUID && -n $dev_uuid ]];then
					dev_item=$( echo "$DEV_DISK_UUID" | gawk '
						$0 ~ /[ \t]'$dev_uuid'[ \t]/ {
							item=gensub( /..\/..\/(.+)/, "\\1", 1, $NF )
							print item
							exit
						}' )
				elif [[ -n $DEV_DISK_LABEL && -n $dev_label ]];then
					dev_item=$( echo "$DEV_DISK_LABEL" | gawk '
						# first we need to change space x20 in by-label back to a real space
						#gsub(/x20/, " ", $0 )
						# then we can see if the string is there
						$0 ~ /[ \t]'$dev_label'[ \t]/ {
							item=gensub( /..\/..\/(.+)/, "\\1", 1, $NF )
							print item
							exit
						}' )
				fi
			fi
			
			# this can trigger all kinds of weird errors if it is a non /dev path, like: remote:/machine/name
			if [[ -n $dev_item && -z $( grep -E '(^//|:/)' <<< $dev_item ) ]];then
				if [[ -n $DEV_DISK_UUID && -z $dev_uuid ]];then
					dev_uuid=$( echo "$DEV_DISK_UUID" | gawk  '
					/'$dev_item'$/ {
						print $(NF - 2)
						exit
					}' )
				fi
				if [[ -n $DEV_DISK_LABEL && -z $dev_label ]];then
					dev_label=$( echo "$DEV_DISK_LABEL" | gawk '
					/'$dev_item'$/ {
						print $(NF - 2)
						exit
					}' )
				fi
			fi

			# assemble everything we could get for dev/h/dx, label, and uuid
			IFS=","
			A_PARTITION_DATA[i]=${a_part_working[0]}","${a_part_working[1]}","${a_part_working[2]}","${a_part_working[3]}","${a_part_working[4]}","${a_part_working[5]}","$dev_item","$dev_label","$dev_uuid
			IFS="$ORIGINAL_IFS"
		done
		log_function_data 'cat' "$FILE_MOUNTS"
	else
		if [[ $BSD_TYPE == 'bsd' ]];then
			get_partition_data_advanced_bsd
		fi
	fi
	a_temp=${A_PARTITION_DATA[@]}
	# echo $a_temp
	log_function_data "3-advanced: A_PARTITION_DATA:\n$a_temp"
	eval $LOGFE
}

get_partition_data_advanced_bsd()
{
	eval $LOGFS
	local gpart_data="$( gpart list 2>/dev/null )"
	local a_part_working='' label_uuid='' dev_item=''
	
	if [[ -n $gpart_data ]];then
		for (( i=0; i < ${#A_PARTITION_DATA[@]}; i++ ))
		do
			IFS=","
			a_part_working=( ${A_PARTITION_DATA[i]} )
			IFS="$ORIGINAL_IFS"
			# no need to use the rest of the name if it's not a straight /dev/item
			dev_item=${a_part_working[6]##*/}
			
			label_uuid=$( gawk -F ':' '
			BEGIN {
				IGNORECASE=1
				label=""
				uuid=""
			}
			/^[0-9]+\.[[:space:]]*Name.*'$dev_item'/ {
				while ( getline && $1 !~ /^[0-9]+\.[[:space:]]*Name/ ) {
					if ( $1 ~ /rawuuid/ ) {
						gsub(/^[[:space:]]+|[[:space:]]+$/,"",$2)
						uuid=$2
					}
					if ( $1 ~ /label/ ) {
						gsub(/^[[:space:]]+|[[:space:]]+$|none|\(null\)/,"",$2)
						label=$2
					}
				}
				print label","uuid
				exit
			}' <<< "$gpart_data" )

			# assemble everything we could get for dev/h/dx, label, and uuid
			IFS=","
			A_PARTITION_DATA[i]=${a_part_working[0]}","${a_part_working[1]}","${a_part_working[2]}","${a_part_working[3]}","${a_part_working[4]}","${a_part_working[5]}","${a_part_working[6]}","$label_uuid
			IFS="$ORIGINAL_IFS"
		done
	fi
	eval $LOGFE
}

# args: $1 - uuid/label/id/mapper
get_partition_dev_data()
{
	eval $LOGFS
	
	# only run these tests once per directory to avoid excessive queries to fs
	case $1 in
		id)
			if [[ $B_ID_SET != 'true' ]];then
				if [[ -d /dev/disk/by-id ]];then
					DEV_DISK_ID="$( ls -l /dev/disk/by-id )"
				fi
				B_ID_SET='true'
			fi
			;;
		label)
			if [[ $B_LABEL_SET != 'true' ]];then
				if [[ -d /dev/disk/by-label ]];then
					DEV_DISK_LABEL="$( ls -l /dev/disk/by-label )"
				fi
				B_LABEL_SET='true'
			fi
			;;
		mapper)
			if [[ $B_MAPPER_SET != 'true' ]];then
				if [[ -d /dev/mapper ]];then
					DEV_DISK_MAPPER="$( ls -l /dev/mapper )"
				fi
				B_MAPPER_SET='true'
			fi
			;;
		uuid)
			if [[ $B_UUID_SET != 'true' ]];then
				if [[ -d /dev/disk/by-uuid ]];then
					DEV_DISK_UUID="$( ls -l /dev/disk/by-uuid )"
				fi
				B_UUID_SET='true'
			fi
			;;
		
	esac
	log_function_data 'raw' "DEV_DISK_LABEL:\n$DEV_DISK_LABEL\n\nDEV_DISK_UUID:\n$DEV_DISK_UUID\n\nDEV_DISK_ID:\n$DEV_DISK_ID\n\nDEV_DISK_MAPPER:\n$DEV_DISK_MAPPER"
	# debugging section, uncomment to insert user data
# 	DEV_DISK_LABEL='
#
# '
# DEV_DISK_UUID='
#
# '
# DEV_DISK_MAPPER='
#
# '
	eval $LOGFE
}

# args: $1 - dev item, check for mapper, then get actual dev item if mapped
# eg: lrwxrwxrwx 1 root root       7 Sep 26 15:10 truecrypt1 -> ../dm-2 
get_dev_processed_item()
{
	eval $LOGFS
	
	local dev_item=$1 dev_return=''
	
	if [[ -n $DEV_DISK_MAPPER && -n $( grep -is 'mapper/' <<< $dev_item ) ]];then
		dev_return=$( echo "$DEV_DISK_MAPPER" | gawk '
		$( NF - 2 ) ~ /^'${dev_item##*/}'$/ {
			item=gensub( /..\/(.+)/, "\\1", 1, $NF )
			print item
		}' )
	fi
	if [[ -z $dev_return ]];then
		dev_return=$dev_item
	fi
	
	echo $dev_return

	eval $LOGFE
}

get_patch_version_string()
{
	SELF_PATCH=${SELF_PATCH##*[0]} # strip leading zero(s)
	
	if [[ -n $SELF_PATCH ]];then
		SELF_PATCH="-$SELF_PATCH"
		# for cases where it was for example: 00-bsd cleaned to --bsd trim out one -
		SELF_PATCH="${SELF_PATCH/--/-}"
	fi
}

get_pciconf_data()
{
	eval $LOGFS
	
	local pciconf_data='' a_temp=''
	
	if [[ $B_PCICONF == 'true' ]];then
		pciconf_data="$( pciconf -lv 2>/dev/null )"
		if [[ -n $pciconf_data ]];then
			pciconf_data=$( gawk '
			BEGIN {
				IGNORECASE=1
			}
			{
					gsub(/'"$BAN_LIST_NORMAL"'/, "", $0)
					gsub(/[[:space:]]+=[[:space:]]+/, "=",$0)
					gsub(/^[[:space:]]+|'"'"'|\"|,/, "", $0)
					gsub(/=0x/,"=",$0)
					# line=gensub(/.*[[:space:]]+(class=[^[:space:]]*|card=[^[:space:]]*)|chip=[^[:space:]]*|rev=[^[:space:]]*|hdr=[^[:space:]]*).*/,"\n\\1","g",$0)
					line=gensub(/(.*@.*)/,"\n\\1",$0)
					print line
			}' <<< "$pciconf_data" )
			# create empty last line with this spacing trick
			pciconf_data="$pciconf_data

EOF"
			# echo "$pciconf_data"
			# now insert into arrays
			IFS=$'\n'
			A_PCICONF_DATA=( $( gawk '
			BEGIN {
				fullLine=""
				driver=""
				vendor=""
				device=""
				class=""
				chipId=""
				pciId=""
				itemData=""
				IGNORECASE=1
			}
			/^.*@/ {
				pciId=""
				vendor=""
				class=""
				driver=""
				device=""
				chipId=""
				itemData=$1
				
				driver=gensub(/^([^@]+)@.*/, "\\1", itemData )
				pciId=gensub(/^.*@pci([0-9\.:]+).*/, "\\1", itemData )
				sub(/:$/, "", pciId)
				itemData=$4
				chipId=gensub(/.*chip=([0-9a-f][0-9a-f][0-9a-f][0-9a-f])([0-9a-f][0-9a-f][0-9a-f][0-9a-f]).*/, "\\2:\\1", itemData )
				if ( $2 ~ /class=020000/ ) {
					class="network"
				}
				else if ( $2 == "class=030000" ) {
					class="display"
				}
				else if ( $2 ~ /class=040300|class=040100/ ) {
					class="audio"
				}
				
				while ( getline && $1 !~ /^$/ ) {
					if ( $1 ~ /^vendor/ ) {
						sub(/^vendor=/, "", $1 )
						vendor=$0
					}
					else if ( $1 ~ /^device/ ) {
						sub(/^device=/, "", $1 )
						device=$0
					}
					else if ( $1 ~ /^class=/ && class == "" ) {
						sub(/^class=/, "", $1)
						class=$0
					}
				}
				if ( device == "" ) {
					device=vendor
				}
				fullLine=class "," device "," vendor "," driver "," pciId "," chipId
				print fullLine
			}' <<< "$pciconf_data" ))
			IFS="$ORIGINAL_IFS"
		fi
	else
		A_PCICONF_DATA='pciconf-not-installed'
	fi
	B_PCICONF_SET='true'
	a_temp=${A_PCICONF_DATA[@]}
	log_function_data "$a_temp"
	log_function_data "$pciconf_data"
	eval $LOGFE
}

# packs standard card arrays using the pciconf stuff
# args: $1 - audio/network/display - matches first item in A_PCICONF_DATA arrays
get_pciconf_card_data()
{
	eval $LOGFS
	local a_temp='' array_string='' j=0 device_string=''
	local ip_tool_command=$( type -p ifconfig )
	local mac='' state='' speed='' duplex='' network_string=''
	
	for (( i=0;i<${#A_PCICONF_DATA[@]};i++ ))
	do
		IFS=','
		a_temp=( ${A_PCICONF_DATA[i]} )
		IFS="$ORIGINAL_IFS"
		
		if [[ ${a_temp[0]} == $1 ]];then
			# don't print the vendor if it's already in the device name
			if [[ -z $( grep -i "${a_temp[2]}" <<< "${a_temp[1]}" ) ]];then
				device_string="${a_temp[2]} ${a_temp[1]}"
			else
				device_string=${a_temp[1]}
			fi
			case $1 in
				audio)
					array_string="$device_string,${a_temp[3]},,,${a_temp[4]},,${a_temp[5]}"
					A_AUDIO_DATA[j]=$array_string
					;;
				display)
					array_string="$device_string,${a_temp[4]},${a_temp[5]},${a_temp[3]}"
					A_GRAPHICS_CARD_DATA[j]=$array_string
					;;
				network)
					if [[ -n $ip_tool_command && -n ${a_temp[3]} ]];then
						network_string=$( 	$ip_tool_command ${a_temp[3]} | gawk '
						BEGIN {
							IGNORECASE=1
							mac=""
							state=""
							speed=""
							duplex=""
						}
						/^[[:space:]]*ether/ {
							mac = $2
						}
						/^[[:space:]]*media/ {
							if ( $0 ~ /<.*>/ ) {
								duplex=gensub(/.*<([^>]+)>.*/,"\\1",$0)
							}
							if ( $0 ~ /\(.*\)/ ) {
								speed=gensub(/.*\(([^<[:space:]]+).*\).*/,"\\1",$0)
							}
						}
						/^[[:space:]]*status/ {
							sub(/.*status[:]?[[:space:]]*/,"", $0)
							state=$0
						}
						END {
							print state "~" speed "~" mac "~" duplex
						}')
					fi
					if [[ -n $network_string ]];then
						mac=$( cut -d '~' -f 3 <<< $network_string )
						state=$( cut -d '~' -f 1 <<< $network_string )
						speed=$( cut -d '~' -f 2 <<< $network_string )
						duplex=$( cut -d '~' -f 4 <<< $network_string )
					fi
					array_string="$device_string,${a_temp[3]},,,${a_temp[4]},${a_temp[3]},$state,$speed,$duplex,$mac,${a_temp[5]}"
					A_NETWORK_DATA[j]=$array_string
					;;
			esac
			((j++))
		fi
	done
	
	eval $LOGFE
}

# args: $1 - type cpu/mem 
get_ps_tcm_data()
{
	eval $LOGFS
	local array_length='' reorder_temp='' i=0 head_tail='' sort_type='' ps_data=''
	
	# bummer, have to make it more complex here because of reverse sort
	# orders in output, pesky lack of support of +rss in old systems
	case $1 in
		mem)
			if [[ $BSD_TYPE != 'bsd' ]];then
				sort_type='ps aux --sort -rss'
				head_tail='head'
			else
				sort_type='ps aux -m'
				head_tail='head'
			fi
			;;
		cpu)
			if [[ $BSD_TYPE != 'bsd' ]];then
				sort_type='ps aux --sort %cpu'
				head_tail='tail'
			else
				sort_type='ps aux -r'
				head_tail='head'
			fi
			;;
	esac
	
	# throttle potential irc abuse
	if [[ $B_IRC == 'true' && $PS_COUNT -gt 5 ]];then
		PS_THROTTLED=$PS_COUNT
		PS_COUNT=5
	fi
	# use eval here to avoid glitches with -
	ps_data="$( eval $sort_type )"

	IFS=$'\n'
	# note that inxi can use a lot of cpu, and can actually show up here as the script runs
	A_PS_DATA=( $( echo "$ps_data" | grep -Ev "($SELF_NAME|%CPU|[[:space:]]ps[[:space:]])" | $head_tail -n $PS_COUNT | gawk '
	BEGIN {
		IGNORECASE=1
		appName=""
		appPath=""
		appStarterName=""
		appStarterPath=""
		cpu=""
		mem=""
		pid=""
		user=""
		rss=""
	}
	{
		cpu=$3
		mem=$4
		pid=$2
		user=$1
		rss=sprintf( "%.2f", $6/1024 )
		# have to get rid of [,],(,) eg: [lockd] which break the printout function compare in bash
		gsub(/\[|\]|\(|\)/,"~", $0 )
		if ( $12 ~ /^\// ){
			appStarterPath=$11
			appPath=$12
		}
		else {
			appStarterPath=$11
			appPath=$11
		}
		appStarterName=gensub( /(\/.*\/)(.*)/, "\\2", "1", appStarterPath )
		appName=gensub( /(\/.*\/)(.*)/, "\\2", "1", appPath )
		print appName "," appPath "," appStarterName "," appStarterPath "," cpu "," mem "," pid "," rss "," user
	}
	' ) )
	# make the array ordered highest to lowest so output looks the way we expect it to
	# this isn't necessary for -rss, and we can't make %cpu ordered the other way, so
	# need to reverse it here. -rss is used because on older systems +rss is not supported
	if [[ $1 == 'cpu' && $BSD_TYPE != 'bsd' ]];then
		array_length=${#A_PS_DATA[@]}; 
		while (( $i < $array_length/2 ))
		do 
			reorder_temp=${A_PS_DATA[i]}f
			A_PS_DATA[i]=${A_PS_DATA[$array_length-$i-1]}
			A_PS_DATA[$array_length-$i-1]=$reorder_temp
			(( i++ ))
		done 
	fi

	IFS="$ORIGINAL_IFS"
	
# 	echo ${A_PS_DATA[@]}
	eval $LOGFE
}

# mdstat syntax information: http://www-01.ibm.com/support/docview.wss?uid=isg3T1011259
# note that this does NOT use either Disk or Partition information for now, ie, there
# is no connection between the data types, but the output should still be consistent
get_raid_data()
{
	eval $LOGFS
	
	local mdstat=''
		
	if [[ $B_MDSTAT_FILE == 'true' ]];then
	 	mdstat="$( cat $FILE_MDSTAT 2>/dev/null )"
	fi
	
	if [[ -n $mdstat ]];then
		# need to make sure there's always a newline in front of each record type, and
		# also correct possible weird formats for the output from older kernels etc.
		mdstat="$( sed -e 's/^md/\nmd/' -e 's/^unused[[:space:]]/\nunused /' \
		-e 's/read_ahead/\nread_ahead/' -e 's/^resync=/\nresync=/' -e 's/^Event/\nEvent/' \
		-e 's/^[[:space:]]*$//' -e 's/[[:space:]]read_ahead/\nread_ahead/' <<< "$mdstat" )"
		# some fringe cases do not end as expected, so need to add newlines plus EOF to make sure while loop doesn't spin
		mdstat=$( echo -e "$mdstat\n\nEOF" )

		IFS=$'\n'
		A_RAID_DATA=( $(
		gawk '
		BEGIN {
			IGNORECASE=1
			RS="\n"
		}
		/^personalities/ {
			KernelRaidSupport = gensub(/personalities[[:space:]]*:[[:space:]]*(.*)/, "\\1", 1, $0)
			# clean off the brackets
			gsub(/[\[\]]/,"",KernelRaidSupport)
			print "KernelRaidSupport," KernelRaidSupport
		}
		/^read_ahead/ {
			ReadAhead=gensub(/read_ahead (.*)/, "\\1", 1 )
			print "ReadAhead," ReadAhead
		}
		/^Event:/ {
			print "raidEvent," $NF
		}
		# print logic will search for this value and use it to print out the unused devices data
		/^unused devices/ {
			unusedDevices = gensub(/^unused devices:[[:space:]][<]?([^>]*)[>]?.*/, "\\1", 1, $0)
			print "UnusedDevices," unusedDevices
		}
		
		/^md/ {
			# reset for each record loop through
			deviceState = ""
			bitmapValues = ""
			blocks = ""
			chunkSize = ""
			components = ""
			device = ""
			deviceReport = ""
			finishTime = ""
			recoverSpeed = ""
			recoveryProgressBar = ""
			recoveryPercent = ""
			raidLevel = ""
			sectorsRecovered = ""
			separator = ""
			superBlock = ""
			uData = ""
			
			while ( !/^[[:space:]]*$/  ) {
				gsub(/'"$BAN_LIST_ARRAY"'/, " ", $0 )
				gsub(/[[:space:]]+/, " ", $0 )
				if ( $0 ~ /^md/ ) {
					device = gensub(/(md.*)[[:space:]]?:/, "\\1", "1", $1 )
				}
				if ( $0 ~ /mirror|raid[0-9]+/ ) {
					raidLevel = gensub(/(.*)raid([0-9]+)(.*)/, "\\2", "g", $0 )
				}
				if ( $0 ~ /(active \(auto-read-only\)|active|inactive)/ ) {
					deviceState = gensub(/(.*) (active \(auto-read-only\)|active|inactive) (.*)/, "\\2", "1", $0 )
				}
				# gawk will not return all the components using gensub, only last one
				separator = ""
				for ( i=3; i<=NF; i++ ) {
					if ( $i ~ /[hs]d[a-z][0-9]*(\[[0-9]+\])?(\([SF]\))?/ ) {
						components = components separator $i
						separator=" "
					}
				}
				if ( $0 ~ /blocks/ ) {
					blocks = gensub(/(.*[[:space:]]+)?([0-9]+)[[:space:]]blocks.*/, "\\2", "1", $0)
				}
				if ( $0 ~ /super[[:space:]][0-9\.]+/ ) {
					superBlock = gensub(/.*[[:space:]]super[[:space:]]([0-9\.]+)[[:space:]].*/, "\\1", "1", $0)
				}
				if ( $0 ~ /algorithm[[:space:]][0-9\.]+/ ) {
					algorithm = gensub(/.*[[:space:]]algorithm[[:space:]]([0-9\.]+)[[:space:]].*/, "\\1", "1", $0)
				}
				if ( $0 ~ /\[[0-9]+\/[0-9]+\]/ ) {
					deviceReport = gensub(/.*[[:space:]]\[([0-9]+\/[0-9]+)\][[:space:]].*/, "\\1", "1", $0)
					uData = gensub(/.*[[:space:]]\[([U_]+)\]/, "\\1", "1", $0)
				}
				# need to avoid this:  bitmap: 0/10 pages [0KB], 16384KB chunk
				# while currently all the normal chunks are marked with k, not kb, this can change in the future
				if ( $0 ~ /[0-9]+[k] chunk/ && $0 !~ /bitmap/ ) {
					chunkSize = gensub(/(.*) ([0-9]+[k]) chunk.*/, "\\2", "1", $0)
				}
				if ( $0 ~ /^resync=/ ) {
					sub(/resync=/,"")
					print "resyncStatus," $0
				}
				if ( $0 ~ /\[[=]*>[\.]*\].*(resync|recovery)/ ) {
					recoveryProgressBar = gensub(/.*(\[[=]*>[\.]*\]).*/, "\\1",1,$0)
				}
				if ( $0 ~ / (resync|recovery)[[:space:]]*=/ ) {
					recoveryPercent = gensub(/.* (resync|recovery)[[:space:]]*=[[:space:]]*([0-9\.]+%).*/, "\\1~\\2", 1 )
					if ( $0 ~ /[[:space:]]\([0-9]+\/[0-9]+\)/ ) {
						sectorsRecovered = gensub(/.* \(([0-9]+\/[0-9]+)\).*/, "\\1", 1, $0 )
					}
					if ( $0 ~ /finish[[:space:]]*=/ ) {
						finishTime = gensub(/.* finish[[:space:]]*=[[:space:]]*([[0-9\.]+)([a-z]+) .*/, "\\1 \\2", 1, $0 )
					}
					if ( $0 ~ /speed[[:space:]]*=/ ) {
						recoverSpeed = gensub(/.* speed[[:space:]]*=[[:space:]]*([[0-9\.]+)([a-z]+\/[a-z]+)/, "\\1 \\2", 1, $0 )
					}
				}
				if ( $0 ~ /bitmap/ ) {
					bitmapValues = gensub(/(.*[[:space:]])?bitmap:(.*)/, "\\2", 1, $0 )
				}
				
				getline
			}
			raidString = device "," deviceState "," raidLevel "," components "," deviceReport "," uData 
			raidString = raidString "," blocks "," superBlock "," algorithm "," chunkSize "," bitmapValues
			raidString = raidString "," recoveryProgressBar "," recoveryPercent "," sectorsRecovered "," finishTime "," recoverSpeed
			
			print raidString
		}
		' <<< "$mdstat" ) )
		IFS="$ORIGINAL_IFS"
	else
		if [[ $BSD_TYPE == 'bsd' ]];then
			get_raid_data_bsd
		fi
	fi
	B_RAID_SET='true'
	a_temp=${A_RAID_DATA[@]}
	log_function_data "A_RAID_DATA: $a_temp"
# 	echo -e "A_RAID_DATA:\n${a_temp}"
	
	eval $LOGFE
}

get_raid_data_bsd()
{
	eval $LOGFS
	local zpool_path=$( type -p zpool 2>/dev/null )
	local zpool_data='' zpool_arg='v'
	
	if [[ -n $zpool_path ]];then
		B_BSD_RAID='true'
		# bsd sed does not support inserting a true \n so use this trick
		# some zfs does not have -v
		if $zpool_path list -v &>/dev/null;then
			zpool_data="$( $zpool_path list -v 2>/dev/null | sed $SED_RX 's/^([^[:space:]])/\
\1/' )"
		else
			zpool_data="$( $zpool_path list 2>/dev/null | sed $SED_RX 's/^([^[:space:]])/\
\1/' )"
			zpool_arg='no-v'
		fi
# 		echo "$zpool_data"
		IFS=$'\n'
		A_RAID_DATA=( $(
		gawk '
		BEGIN {
			IGNORECASE=1
			raidString=""
			separator=""
			components=""
			reportSize=""
			blocksAvailable=""
			chunkRaidAllocated=""
		}
		/SIZE.*ALLOC/ {
			sub(/.*ALLOC.*/,"", $0)
		}
		# gptid/d874c7e7-3f6d-11e4-b7dc-080027ea466c
		/^[^[:space:]]/ {
			components=""
			separator=""
			raidLevel=""
			device=$1
			deviceState=$7
			reportSize=$2
			blocksAvailable=$4
			chunkRaidAllocated=$3
			
			getline
			# raid level is the second item in the output, unless it is not, sometimes it is absent
			if ( $1 != "" ) {
				if ( $1 ~ /raid|mirror/ ) {
					raidLevel="zfs " $1
				}
				else {
					raidLevel="zfs-no-raid"
					components = $1
					separator=" "
				}
			}
			
			while ( getline && $1 !~ /^$/ ) {
				# https://blogs.oracle.com/eschrock/entry/zfs_hot_spares
				if ($1 ~ /spares/) {
					getline
				}
				# print $1
				components = components separator $1
				separator=" "
			}
			# some issues if we use ~ here
			gsub(/\//,"%",components)
			# print $1
			raidString = device "," deviceState "," raidLevel "," components "," reportSize "," uData 
			raidString = raidString "," blocksAvailable "," superBlock "," algorithm "," chunkRaidAllocated 
			# none of these are used currently
			raidString = raidString "," bitmapValues  "," recoveryProgressBar "," recoveryPercent 
			raidString = raidString "," sectorsRecovered "," finishTime "," recoverSpeed
			gsub(/~/,"",raidString)
			print raidString
		}' <<< "$zpool_data" ) )
		IFS="$ORIGINAL_IFS"
		# pass the zpool type, so we know how to get the components
		get_raid_component_data_bsd "$zpool_arg"
	fi
	eval $LOGFE
}

# note, we've already tested for zpool so no further tests required
# args: $1 - zpool type, v will have a single row output, no-v has stacked for components
get_raid_component_data_bsd()
{
	eval $LOGFS
	local a_raid_data='' array_string='' component='' component_string='' 
	local zpool_status='' device='' separator='' component_status=''
	
	for (( i=0; i<${#A_RAID_DATA[@]}; i++))
	do
		IFS=","
		a_raid_data=( ${A_RAID_DATA[i]} )
		IFS="$ORIGINAL_IFS"
		separator=''
		component_string=''
		component_status=''
		zpool_status=''
		device=${a_raid_data[0]}
		zpool_status="$( zpool status $device )"
		# we will remove ONLINE for status and only use OFFLINE/DEGRADED as tests
		# for print output display of issues with components
		# note: different zfs outputs vary, some have the components listed by line
		if [[ $1 == 'v' ]];then
			for component in ${a_raid_data[3]}
			do
				component_status=$( gawk '
				BEGIN {
					IGNORECASE=1
					separator=""
				}
				{
					gsub(/\//,"%",$1)
				}
				$1 ~ /^'$component'$/ {
					sub( /ONLINE/, "", $2 )
					print "'$component'" $2
					exit
				}' <<< "$zpool_status" )
				component_string="$component_string$separator$component_status"
				separator=' '
			done
			array_string="$device,${a_raid_data[1]},${a_raid_data[2]},${component_string//%/\/},${a_raid_data[4]}"
			array_string="$array_string,${a_raid_data[5]},${a_raid_data[6]},${a_raid_data[7]},${a_raid_data[8]}"
			array_string="$array_string,${a_raid_data[9]},${a_raid_data[10]},${a_raid_data[11]},${a_raid_data[12]},"
			array_string="$array_string${a_raid_data[13]},${a_raid_data[14]},${a_raid_data[15]}"
		else
			component_string=$( gawk '
			BEGIN {
				IGNORECASE=1
				separator=""
				components=""
				raidLevel=""
			}
			$1 ~ /^'$device'$/ {
				while ( getline && !/^$/ ) {
					# raid level is the second item in the output, unless it is not, sometimes it is absent
					if ( $1 != "" ) {
						if ( raidLevel == "" ) {
							if (  $1 ~ /raid|mirror/ ) {
								raidLevel="zfs " $1
								getline
							}
							else {
								raidLevel="zfs-no-raid"
							}
						}
					}
					# https://blogs.oracle.com/eschrock/entry/zfs_hot_spares
					if ($1 ~ /spares/) {
						getline
					}
					sub( /ONLINE/, "", $2 )
					components=components separator $1 separator $2
					separator=" "
				}
				print raidLevel "," components
			}' <<< "$zpool_status" )
			# note: component_string is raid type AND components
			array_string="$device,${a_raid_data[1]},$component_string,${a_raid_data[4]}"
			array_string="$array_string,${a_raid_data[5]},${a_raid_data[6]},${a_raid_data[7]},${a_raid_data[8]}"
			array_string="$array_string,${a_raid_data[9]},${a_raid_data[10]},${a_raid_data[11]},${a_raid_data[12]},"
			array_string="$array_string${a_raid_data[13]},${a_raid_data[14]},${a_raid_data[15]}"
		fi
		IFS=","
		A_RAID_DATA[i]=$array_string
		IFS="$ORIGINAL_IFS"
	done
	
	eval $LOGFE
}
# get_raid_data_bsd;exit

get_ram_data()
{
	eval $LOGFS
	
	local a_temp='' array_string=''
	
	get_dmidecode_data
	
	if [[ -n $DMIDECODE_DATA ]];then
		if [[ $DMIDECODE_DATA == 'dmidecode-error-'* ]];then
			A_MEMORY_DATA[0]=$DMIDECODE_DATA
		# please note: only dmidecode version 2.11 or newer supports consistently the -s flag
		else
			IFS=$'\n'
			A_MEMORY_DATA=( $( 
			gawk -F ':' '
			BEGIN {
				IGNORECASE=1
				arrayHandle=""
				bankLocator=""
				clockSpeed=""
				configuredClockSpeed=""
				dataWidth=""
				deviceManufacturer=""
				devicePartNumber=""
				deviceSerialNumber=""
				deviceSpeed=""
				deviceType=""
				deviceTypeDetail=""
				deviceSize=""
				errorCorrection=""
				formFactor=""
				handle=""
				location=""
				locator=""
				aArrayData[0,"maxCapacity5"]=0
				aArrayData[0,"maxCapacity16"]=0
				aArrayData[0,"usedCapacity"]=0
				aArrayData[0,"maxModuleSize"]=0
				aArrayData[0,"derivedModuleSize"]=0
				aArrayData[0,"deviceCount5"]=0
				aArrayData[0,"deviceCount16"]=0
				aArrayData[0,"deviceCountFound"]=0
				aArrayData[0,"moduleVoltage5"]=""
				moduleVoltage=""
				numberOfDevices=""
				primaryType=""
				totalWidth=""
				use=""
				i=0
				j=0
				k=0
				bDebugger1="false"
				dDebugger2="false"
				bType5="false"
			}
			function calculateSize(data,size) {
				if ( data ~ /^[0-9]+[[:space:]]*[GMTP]B/) {
					if ( data ~ /GB/ ) {
						data=gensub(/([0-9]+)[[:space:]]*GB/,"\\1",1,data) * 1024
					}
					else if ( data ~ /MB/ ) {
						data=gensub(/([0-9]+)[[:space:]]*MB/,"\\1",1,data)
					}
					else if ( data ~ /TB/ ) {
						data=gensub(/([0-9]+)[[:space:]]*TB/,"\\1",1,data) * 1024 * 1000
					}
					else if ( data ~ /PB/ ) {
						data=gensub(/([0-9]+)[[:space:]]*TB/,"\\1",1,data) * 1024 * 1000 * 1000
					}
					if (data ~ /^[0-9][0-9]+$/ && data > size ) {
						size=data
					}
				}
				return size
			}
			/^Table[[:space:]]+at[[:space:]]/ {
				bType5="false"
				# we need to start count here because for testing > 1 array, and we want always to have
				# the actual module data assigned to the right primary array, even when it is out of
				# position in dmidecode output
				i=0
				j=0
				k++
			}
			# {print k ":k:" $0}
			/^Handle .* DMI[[:space:]]+type[[:space:]]+5(,|[[:space:]])/ {
				while ( getline && !/^$/ ) {
					if ( $1 == "Maximum Memory Module Size" ) {
						aArrayData[k,"maxModuleSize"]=calculateSize($2,aArrayData[k,"maxModuleSize"])
						# print "mms:" aArrayData[k,"maxModuleSize"] ":" $2
					}
					if ($1 == "Maximum Total Memory Size") {
						aArrayData[k,"maxCapacity5"]=calculateSize($2,aArrayData[k,"maxCapacity5"])
					}
					if ( $1 == "Memory Module Voltage" ) {
						aArrayData[k,"moduleVoltage5"]=$2
					}
				}
				aArrayData[k,"data-type"]="memory-array"
				# print k ":data5:"aArrayData[k,"data-type"]
				bType5="true"
			}
			/^Handle .* DMI[[:space:]]+type[[:space:]]+6(,|[[:space:]])/ {
				while ( getline && !/^$/ ) {
					if ( $1 == "Installed Size" ) {
						# get module size
						aMemory[k,j,18]=calculateSize($2,0)
						# get data after module size
						sub(/ Connection/,"",$2)
						sub(/^[0-9]+[[:space:]]*[MGTP]B[[:space:]]*/,"",$2)
						aMemory[k,j,16]=$2
					}
					if ( $1 == "Current Speed" ) {
						aMemory[k,j,17]=$2
					}
				}
				j++
			}
			
			/^Handle .* DMI[[:space:]]+type[[:space:]]+16/ {
				arrayHandle=gensub(/Handle[[:space:]]([0-9a-zA-Z]+)([[:space:]]|,).*/,"\\1",$0)
				while ( getline && !/^$/ ) {
					# print $0
					if ( $1 == "Maximum Capacity") {
						aArrayData[k,"maxCapacity16"]=calculateSize($2,aArrayData[k,"maxCapacity16"])
						#print "mc:" aArrayData[k,"maxCapacity16"] ":" $2
					}
					# note: these 3 have cleaned data in get_dmidecode_data, so replace stuff manually
					if ( $1 == "Location") {
						sub(/[[:space:]]Or[[:space:]]Motherboard/,"",$2)
						location=$2
						if ( location == "" ){
							location="System Board"
						}
					}
					if ( $1 == "Use") {
						use=$2
						if ( use == "" ){
							use="System Memory"
						}
					}
					if ( $1 == "Error Correction Type") {
						errorCorrection=$2
						if ( errorCorrection == "" ){
							errorCorrection="None"
						}
					}
					if ( $1 == "Number of Devices") {
						numberOfDevices=$2
					}
				}
				aArrayData[k,"data-type"]="memory-array"
				# print k ":data16:"aArrayData[k,"data-type"]
				aArrayData[k,"handle"]=arrayHandle
				aArrayData[k,"location"]=location
				aArrayData[k,"deviceCount16"]=numberOfDevices
				aArrayData[k,"use"]=use
				aArrayData[k,"errorCorrection"]=errorCorrection
				
				# reset
				primaryType=""
				arrayHandle=""
				location=""
				numberOfDevices=""
				use=""
				errorCorrection=""
				moduleVoltage=""
				
				aDerivedModuleSize[k+1]=0
				aArrayData[k+1,"deviceCountFound"]=0
				aArrayData[k+1,"maxCapacity5"]=0
				aArrayData[k+1,"maxCapacity16"]=0
				aArrayData[k+1,"maxModuleSize"]=0
			}
			/^Handle .* DMI[[:space:]]+type[[:space:]]+17/ {
				while ( getline && !/^$/ ) {
					if ( $1 == "Array Handle") {
						arrayHandle=$2
					}
					if ( $1 == "Data Width") {
						dataWidth=$2
					}
					if ( $1 == "Total Width") {
						totalWidth=$2
					}
					if ( $1 == "Size") {
						# do not try to guess from installed modules, only use this to correct type 5 data
						aArrayData[k,"derivedModuleSize"]=calculateSize($2,aArrayData[k,"derivedModuleSize"])
						workingSize=calculateSize($2,0)
						if ( workingSize ~ /^[0-9][0-9]+$/ ){
							aArrayData[k,"deviceCountFound"]++
							# build up actual capacity found for override tests
							aArrayData[k,"usedCapacity"]=workingSize + aArrayData[k,"usedCapacity"]
						}
						# print aArrayData[k,"derivedModuleSize"] " dm:" k ":mm " aMaxModuleSize[k] " uc:" aArrayData[k,"usedCapacity"]
						# we want any non real size data to be preserved
						if ( $2 ~ /^[0-9]+[[:space:]]*[MTPG]B/ ) {
							deviceSize=workingSize
						}
						else {
							deviceSize=$2
						}
					}
					if ( $1 == "Locator") {
						# sub(/.*_/,"",$2)
						#sub(/RAM slot #|^DIMM/, "Slot",$2)
						sub(/RAM slot #/, "Slot",$2)
						
						#locator=toupper($2)
						locator=$2
					}
					if ( $1 == "Bank Locator") {
						#sub(/_.*/,"",$2)
						#sub(/RAM slot #|Channel|Chan/,"bank",$2)
						#sub(/RAM slot #|Channel|Chan/,"bank",$2)
						#bankLocator=toupper($2)
						bankLocator=$2
					}
					if ( $1 == "Form Factor") {
						formFactor=$2
					}
					if ( $1 == "Type") {
						deviceType=$2
					}
					if ( $1 == "Type Detail") {
						deviceTypeDetail=$2
					}
					if ( $1 == "Speed") {
						deviceSpeed=$2
					}
					if ( $1 == "Configured Clock Speed") {
						configuredClockSpeed=$2
					}
					if ( $1 == "Manufacturer") {
						gsub(/(^[0]+$|Undefined.*|.*Manufacturer.*)/,"",$2)
						deviceManufacturer=$2
					}
					if ( $1 == "Part Number") {
						sub(/(^[0]+$||.*Module.*|Undefined.*)/,"",$2)
						devicePartNumber=$2
					}
					if ( $1 == "Serial Number") {
						gsub(/(^[0]+$|Undefined.*)/,"",$2)
						deviceSerialNumber=$2
					}
				}
				# because of the wide range of bank/slot type data, we will just use
				# the one that seems most likely to be right. Some have: Bank: SO DIMM 0 slot: J6A
				# so we dump the useless data and use the one most likely to be visibly correct
				if ( bankLocator ~ /DIMM/ ) {
					mainLocator=bankLocator
				}
				else {
					mainLocator=locator
				}
				# sometimes the data is just wrong, they reverse total/data. data I believe is
				# used for the actual memory bus width, total is some synthetic thing, sometimes missing.
				# note that we do not want a regular string comparison, because 128 bit memory buses are
				# in our future, and 128 bits < 64 bits with string compare
				intData=gensub(/(^[0-9]+).*/,"\\1",1,dataWidth)
				intTotal=gensub(/(^[0-9]+).*/,"\\1",1,totalWidth)
				if (intData != "" && intTotal != "" && intData > intTotal ) {
					tempWidth=dataWidth
					dataWidth=totalWidth
					totalWidth=tempWidth
				}
				
				aMemory[k,i,0]="memory-device"
				aMemory[k,i,1]=arrayHandle
				aMemory[k,i,2]=deviceSize
				aMemory[k,i,3]=bankLocator
				aMemory[k,i,4]=locator
				aMemory[k,i,5]=formFactor
				aMemory[k,i,6]=deviceType
				aMemory[k,i,7]=deviceTypeDetail
				aMemory[k,i,8]=deviceSpeed
				aMemory[k,i,9]=configuredClockSpeed
				aMemory[k,i,10]=dataWidth
				aMemory[k,i,11]=totalWidth
				aMemory[k,i,12]=deviceManufacturer
				aMemory[k,i,13]=devicePartNumber
				aMemory[k,i,14]=deviceSerialNumber
				aMemory[k,i,15]=mainLocator
				
				primaryType=""
				arrayHandle=""
				deviceSize=""
				bankLocator=""
				locator=""
				mainLocator=""
				mainLocator=""
				formFactor=""
				deviceType=""
				deviceTypeDetail=""
				deviceSpeed=""
				configuredClockSpeed=""
				dataWidth=""
				totalWidth=""
				deviceManufacturer=""
				devicePartNumber=""
				deviceSerialNumber=""
				i++
			}
			END {
				## CRITICAL: gawk keeps changing integers to strings, so be explicit with int() in math
				# print primaryType "," arrayHandle "," location "," maxCapacity "," numberOfDevices "," use "," errorCorrection "," maxModuleSize "," moduleVoltage
				
				# print primaryType "," arrayHandle "," deviceSize "," bankLocator "," locator "," formFactor "," deviceType "," deviceTypeDetail "," deviceSpeed "," configuredClockSpeed "," dataWidth "," totalWidth "," deviceManufacturer "," devicePartNumber "," deviceSerialNumber "," mainLocator
				
				for ( m=1;m<=k;m++ ) {
					estCap=""
					estMod=""
					unit=""
					altCap=0
					workingMaxCap=int(aArrayData[m,"maxCapacity16"])
					
					if ( bDebugger1 == "true" ){
						print ""
						print "count: " m
						print "1: mmods: " aArrayData[m,"maxModuleSize"] " :dmmods: " aArrayData[m,"derivedModuleSize"] " :mcap: " workingMaxCap " :ucap: " aArrayData[m,"usedCapacity"] 
					}
					# 1: if max cap 1 is null, and max cap 2 not null, use 2
					if ( workingMaxCap == 0 ) {
						if ( aArrayData[m,"maxCapacity5"] != 0 ) {
							workingMaxCap=aArrayData[m,"maxCapacity5"]
						}
					}
					if ( aArrayData[m,"deviceCount16"] == "" ) {
						aArrayData[m,"deviceCount16"] = 0
					}
					if ( bDebugger1 == "true" ){
						print "2: mmods: " aArrayData[m,"maxModuleSize"] " :dmmods: " aArrayData[m,"derivedModuleSize"] " :mcap: " workingMaxCap " :ucap: " aArrayData[m,"usedCapacity"]
					}
					# 2: now check to see if actually found module sizes are > than listed max module, replace if >
					if (aArrayData[m,"maxModuleSize"] != 0 && aArrayData[m,"derivedModuleSize"] != 0 && int(aArrayData[m,"derivedModuleSize"]) > int(aArrayData[m,"maxModuleSize"]) ) {
						aArrayData[m,"maxModuleSize"]=aArrayData[m,"derivedModuleSize"]
						estMod=" (est)"
					}
					aArrayData[m,"maxModuleSize"]=int(aArrayData[m,"maxModuleSize"])
					aArrayData[m,"derivedModuleSize"]=int(aArrayData[m,"derivedModuleSize"])
					aArrayData[m,"usedCapacity"]=int(aArrayData[m,"usedCapacity"])
					workingMaxCap=int(workingMaxCap) 
					 
					# note: some cases memory capacity == max module size, so one stick will fill it
					# but I think only with cases of 2 slots does this happen, so if > 2, use the count of slots.
					if ( bDebugger1 == "true" ){
						print "3: fmod: " aArrayData[m,"deviceCountFound"] " :modc: " aArrayData[m,"deviceCount16"] " :maxc1: " aArrayData[m,"maxCapacity5"] " :maxc2: " aArrayData[m,"maxCapacity16"]
					}
					if (workingMaxCap != 0 && ( aArrayData[m,"deviceCountFound"] != 0 || aArrayData[m,"deviceCount16"] != 0 ) ) {
						aArrayData[m,"deviceCount16"]=int(aArrayData[m,"deviceCount16"])
						## first check that actual memory found is not greater than listed max cap, or
						## checking to see module count * max mod size is not > used capacity
						if ( aArrayData[m,"usedCapacity"] != 0 && aArrayData[m,"maxCapacity16"] != 0 ) {
							if ( aArrayData[m,"usedCapacity"] > workingMaxCap ) {
								if ( aArrayData[m,"maxModuleSize"] != 0 && 
									aArrayData[m,"usedCapacity"] < aArrayData[m,"deviceCount16"] * aArrayData[m,"maxModuleSize"] ) {
									workingMaxCap=aArrayData[m,"deviceCount16"] * aArrayData[m,"maxModuleSize"]
									estCap=" (est)"
									if ( bDebugger1 == "true" ){
										print "A"
									}
								}
								else if ( aArrayData[m,"derivedModuleSize"] != 0 && 
											aArrayData[m,"usedCapacity"] < aArrayData[m,"deviceCount16"] * aArrayData[m,"derivedModuleSize"] ) {
									workingMaxCap=aArrayData[m,"deviceCount16"] *  aArrayData[m,"derivedModuleSize"]
									estCap=" (est)"
									if ( bDebugger1 == "true" ){
										print "B"
									}
								}
								else {
									workingMaxCap=aArrayData[m,"usedCapacity"]
									estCap=" (est)"
									if ( bDebugger1 == "true" ){
										print "C"
									}
								}
							}
						} 
						# note that second case will never really activate except on virtual machines and maybe
						# mobile devices
						if ( estCap == "" ) {
							# do not do this for only single modules found, max mod size can be equal to the array size
							if ( ( aArrayData[m,"deviceCount16"] > 1 && aArrayData[m,"deviceCountFound"] > 1 ) && 
								( workingMaxCap < aArrayData[m,"derivedModuleSize"] * aArrayData[m,"deviceCount16"] ) ) {
								workingMaxCap = aArrayData[m,"derivedModuleSize"] * aArrayData[m,"deviceCount16"]
								estCap=" (est)"
								if ( bDebugger1 == "true" ){
									print "D"
								}
							}
							else if ( ( aArrayData[m,"deviceCountFound"] > 0 ) && 
										( workingMaxCap < aArrayData[m,"derivedModuleSize"] * aArrayData[m,"deviceCountFound"] ) ) {
								workingMaxCap = aArrayData[m,"derivedModuleSize"] * aArrayData[m,"deviceCountFound"]
								estCap=" (est)"
								if ( bDebugger1 == "true" ){
									print "E"
								}
							}
							## handle cases where we have type 5 data: mms x device count equals type 5 max cap
							# however do not use it if cap / devices equals the derived module size
							else if ( aArrayData[m,"maxModuleSize"] > 0 && 
										( aArrayData[m,"maxModuleSize"] * aArrayData[m,"deviceCount16"] == aArrayData[m,"maxCapacity5"] ) && 
										aArrayData[m,"maxCapacity5"] != aArrayData[m,"maxCapacity16"] && 
										aArrayData[m,"maxCapacity16"] / aArrayData[m,"deviceCount16"] != aArrayData[m,"derivedModuleSize"] ) {
								workingMaxCap = aArrayData[m,"maxCapacity5"]
								altCap=aArrayData[m,"maxCapacity5"] # not used
								estCap=" (check)"
								if ( bDebugger1 == "true" ){
									print "F"
								}
							}
						}
					}
					altCap=int(altCap)
					workingMaxCap=int(workingMaxCap)
					if ( bDebugger1 == "true" ){
						print "4: mmods: " aArrayData[m,"maxModuleSize"] " :dmmods: " aArrayData[m,"derivedModuleSize"] " :mcap: " workingMaxCap " :ucap: " aArrayData[m,"usedCapacity"]
					}
					# some cases of type 5 have too big module max size, just dump the data then since
					# we cannot know if it is valid or not, and a guess can be wrong easily
					if ( aArrayData[m,"maxModuleSize"] != 0 && workingMaxCap != "" && 
						( aArrayData[m,"maxModuleSize"] > workingMaxCap ) ){
						aArrayData[m,"maxModuleSize"] = 0
						# print "yes"
					}
					if ( bDebugger1 == "true" ){
						print "5: dms: " aArrayData[m,"derivedModuleSize"] " :dc: " aArrayData[m,"deviceCount16"] " :wmc: " workingMaxCap
					}
					## prep for output ##
					if (aArrayData[m,"maxModuleSize"] == 0 ){
						aArrayData[m,"maxModuleSize"]=""
						# ie: 2x4gB
						if ( estCap == "" && int(aArrayData[m,"derivedModuleSize"]) > 0 &&
						    workingMaxCap > ( int(aArrayData[m,"derivedModuleSize"]) * int(aArrayData[m,"deviceCount16"]) * 4 ) ) { 
							estCap=" (check)"
							if ( bDebugger1 == "true" ){
								print "G"
							}
						}
					}
					else {
						# case where listed max cap is too big for actual slots x max cap, eg:
						# listed max cap, 8gb, max mod 2gb, slots 2
						if ( estCap == "" && aArrayData[m,"maxModuleSize"] > 0 ) {
							if ( int(workingMaxCap) > int(aArrayData[m,"maxModuleSize"]) * aArrayData[m,"deviceCount16"] ) {
								estCap=" (check)"
								if ( bDebugger1 == "true" ){
									print "H"
								}
							}
						}
						if (aArrayData[m,"maxModuleSize"] > 1023 ) {
							aArrayData[m,"maxModuleSize"]=aArrayData[m,"maxModuleSize"] / 1024 " GB"
						}
						else {
							aArrayData[m,"maxModuleSize"]=aArrayData[m,"maxModuleSize"] " MB"
						}
					}
					if ( aArrayData[m,"deviceCount16"] == 0 ) {
						aArrayData[m,"deviceCount16"] = ""
					}
					if (workingMaxCap != 0 ) {
						if ( workingMaxCap < 1024 ) {
							workingMaxCap = workingMaxCap
							unit=" MB"
						}
						else if ( workingMaxCap < 1024000 ) {
							workingMaxCap = workingMaxCap / 1024
							unit=" GB"
						}
						else if ( workingMaxCap < 1024000000 ) {
							workingMaxCap = workingMaxCap / 1024000
							unit=" TB"
						}
						# we only want a max 2 decimal places, this trick gives 0 to 2
						workingMaxCap=gensub(/([0-9]+\.[0-9][0-9]).*/,"\\1",1,workingMaxCap)
						workingMaxCap = workingMaxCap unit estCap
						
					}
					else {
						workingMaxCap == ""
					}
					
					print aArrayData[m,"data-type"] "," aArrayData[m,"handle"] "," aArrayData[m,"location"] "," workingMaxCap "," aArrayData[m,"deviceCount16"] "," aArrayData[m,"use"] "," aArrayData[m,"errorCorrection"] "," aArrayData[m,"maxModuleSize"] estMod "," aArrayData[m,"voltage5"] 
					# print device rows next
					for ( j=0;j<=100;j++ ) {
						if (aMemory[m,j,0] != "" ) {
							unit=""
							workingSize=aMemory[m,j,2]
							if ( workingSize ~ /^[0-9]+$/ ) {
								workingSize=int(workingSize)
								if ( workingSize < 1024 ) {
									workingSize = workingSize
									unit=" MB"
								}
								else if ( workingSize < 1024000 ) {
									workingSize = workingSize / 1024
									unit=" GB"
								}
								else if ( workingSize < 1024000000 ) {
									workingSize = workingSize / 1024000
									unit=" TB"
								}
								# we only want a max 2 decimal places, this trick gives 0 to 2
								workingSize=gensub(/([0-9]+\.[0-9][0-9]).*/,"\\1",1,workingSize)
								workingSize = workingSize unit
							}
							print aMemory[m,j,0] "," aMemory[m,j,1] "," workingSize "," aMemory[m,j,3] "," aMemory[m,j,4] "," aMemory[m,j,5] "," aMemory[m,j,6] "," aMemory[m,j,7] "," aMemory[m,j,8]  "," aMemory[m,j,9] "," aMemory[m,j,10] "," aMemory[m,j,11] "," aMemory[m,j,12] "," aMemory[m,j,13] "," aMemory[m,j,14] "," aMemory[m,j,15] "," aMemory[m,j,16] "," aMemory[m,j,17]
						}
						else {
							break
						}
					}
				}
			}' <<< "$DMIDECODE_DATA" ) )
		fi
	fi
	IFS="$ORIGINAL_IFS"
	a_temp=${A_MEMORY_DATA[@]}
	
 	# echo "${a_temp[@]}"
	log_function_data "A_MEMORY_DATA: $a_temp"
	
	eval $LOGFE
}

# Repos will be added as we get distro package manager data to create the repo data. 
# This method will output the file name also, which is useful to create output that's 
# neat and readable. Each line of the total number contains the following sections,
# separated by a : for splitting in the print function
# part one, repo type/string : part two, file name, if present, of info : part 3, repo data
# args: $1 - [file location of debug data file - optional, only for debugging data collection] 
get_repo_data()
{
	eval $LOGFS
	local repo_file='' repo_data_working='' repo_data_working2='' repo_line='' repo_files=''
	local repo_name=''
	local apt_file='/etc/apt/sources.list' yum_repo_dir='/etc/yum.repos.d/' yum_conf='/etc/yum.conf'
	local pacman_conf='/etc/pacman.conf' pacman_repo_dir='/etc/pacman.d/' pisi_dir='/etc/pisi/'
	local zypp_repo_dir='/etc/zypp/repos.d/' ports_conf='/etc/portsnap.conf' openbsd_conf='/etc/pkg.conf'
	local bsd_pkg_dir='/usr/local/etc/pkg/repos/' slackpkg_file='/etc/slackpkg/mirrors'
	local netbsd_file='/usr/pkg/etc/pkgin/repositories.conf' freebsd_file='/etc/freebsd-update.conf'
	local freebsd_pkg_file='/etc/pkg/FreeBSD.conf' slackpkg_plus_file='/etc/slackpkg/slackpkgplus.conf'
	local portage_repo_dir='/etc/portage/repos.conf/' apk_file='/etc/apk/repositories'
	
	# apt - debian, buntus, also sometimes some yum/rpm repos may create apt repos here as well
	if [[ -f $apt_file || -d $apt_file.d ]];then
		repo_files=$(ls /etc/apt/sources.list /etc/apt/sources.list.d/*.list 2>/dev/null)
		log_function_data "apt repo files: $repo_files"
		for repo_file in $repo_files
		do
			if [[ -n $1 ]];then
				cat $repo_file &> $1/repo-data_${repo_file//\//-}.txt
			fi
			repo_data_working="$( gawk -v repoFile="$repo_file" '
			!/^[[:space:]]*$|^[[:space:]]*#/ {
				print "apt sources^" repoFile "^" $0
			}' $repo_file )"
			get_repo_builder "$repo_data_working"
		done
		repo_data_working=''
	fi
	# yum - fedora, redhat, centos, etc. Note that rpmforge also may create apt sources
	# in /etc/apt/sources.list.d/. Therefore rather than trying to assume what package manager is
	# actually running, inxi will merely note the existence of each repo type for apt/yum. 
	# Also, in rpm, you can install apt-rpm for the apt-get command, so it's not good to check for
	# only the commands in terms of selecting which repos to show.
	if [[ -d $yum_repo_dir || -f $yum_conf || -d $zypp_repo_dir ]];then
		if [[ -d $yum_repo_dir || -f $yum_conf ]];then
			# older redhats put their yum data in /etc/yum.conf
			repo_files=$( ls $yum_repo_dir*.repo $yum_conf 2>/dev/null )
			repo_name='yum'
			log_function_data "yum repo files: $repo_files"
		elif [[ -d $zypp_repo_dir ]];then
			repo_files=$( ls $zypp_repo_dir*.repo 2>/dev/null )
			repo_name='zypp'
			log_function_data "zypp repo files: $repo_files"
		fi
		if [[ -n $repo_files ]];then
			for repo_file in $repo_files
			do
				if [[ -n $1 ]];then
					cat $repo_file &> $1/repo-data_${repo_file//\//-}.txt
				fi
				repo_data_working="$( gawk -v repoFile="$repo_file" '
				# construct the string for the print function to work with, file name: data
				function print_line( fileName, repoId, repoUrl ){
					print "'$repo_name' sources^" fileName "^" repoId  repoUrl
				}
				BEGIN {
					FS="\n"
					IGNORECASE=1
					enabledStatus=""
					repoTitle=""
					urlData=""
				}
				# this is a hack, assuming that each item has these fields listed, we collect the 3
				# items one by one, then when the url/enabled fields are set, we print it out and
				# reset the data. Not elegant but it works. Note that if enabled was not present
				# we assume it is enabled then, and print the line, reset the variables. This will
				# miss the last item, so it is printed if found in END
				/^\[.+\]/ {
					if ( urlData != "" && repoTitle != "" ){
						print_line( repoFile, repoTitle, urlData )
						enabledStatus=""
						urlData=""
						repoTitle=""
					}
					gsub(/\[|\]/, "", $1 ) # strip out the brackets
					repoTitle = $1 " ~ "
				}
				/^(mirrorlist|baseurl)/ {
					sub( /(mirrorlist|baseurl)[[:space:]]*=[[:space:]]*/, "", $1 ) # strip out the field starter
					urlData = $1
				}
				# note: enabled = 1. enabled = 0 means disabled
				/^enabled[[:space:]]*=/ {
					enabledStatus = $1
				}
				# print out the line if all 3 values are found, otherwise if a new
				# repoTitle is hit above, it will print out the line there instead
				{ 
					if ( urlData != "" && enabledStatus != "" && repoTitle != "" ){
						if ( enabledStatus !~ /enabled[[:space:]]*=[[:space:]]*0/ ){
							print_line( repoFile, repoTitle, urlData )
						}
						enabledStatus=""
						urlData=""
						repoTitle=""
					}
				}
				END {
					# print the last one if there is data for it
					if ( urlData != ""  && repoTitle != "" ){
						print_line( repoFile, repoTitle, urlData )
					}
				}
				' $repo_file )"
				# then load the global for each file as it gets filled
				get_repo_builder "$repo_data_working"
			done
		fi
		repo_data_working=''
	# pacman - archlinux, going to assume that pisi and arch/pacman, etc don't have the above issue with apt/yum
	elif [[ -f $pacman_conf ]];then
		# get list of mirror include files, trim white space off ends
		repo_data_working="$( gawk '
		BEGIN {
			FS="="
			IGNORECASE=1
		}
		/^[[:space:]]*Include/ {
			sub(/^[[:space:]]+|[[:space:]]+$/,"",$2)
			print $2
		}
		' $pacman_conf )"
		# sort into unique paths only, to be used to search for server = data
		repo_data_working=$( sort -bu <<< "$repo_data_working" | uniq ) 
		repo_data_working="$repo_data_working $pacman_conf"
		for repo_file in $repo_data_working 
		do
			if [[ -n $1 ]];then
				cat $repo_file &> $1/repo-data_${repo_file//\//-}.txt
			fi
			if [[ -f $repo_file ]];then
				# inserting a new line after each found / processed match
				repo_data_working2="$repo_data_working2$( gawk -v repoFile=$repo_file '
				BEGIN {
					FS="="
					IGNORECASE=1
				}
				/^[[:space:]]*Server/ {
					sub(/^[[:space:]]+|[[:space:]]+$/,"",$2)
					print "pacman repo servers^" repoFile "^" $2 "\\n"
				}
				' $repo_file )"
			else
				echo "Error: file listed in $pacman_conf does not exist - $repo_file"
			fi
		done
		# execute line breaks
		REPO_DATA="$( echo -e $repo_data_working2 )"
		repo_data_working=''
	# pisi - pardus
	elif [[ -f $slackpkg_file || -f $slackpkg_plus_file ]];then
		# note, only one file, but loop it in case more are added in future
		if [[ -f $slackpkg_file ]];then
			if [[ -n $1 ]];then
				cat $slackpkg_file &> $1/repo-data_${slackpkg_file//\//-}.txt
			fi
			repo_data_working="$( gawk -v repoFile="$slackpkg_file" '
			!/^[[:space:]]*$|^[[:space:]]*#/ {
				print "slackpkg sources^" repoFile "^" $0
			}' $slackpkg_file )"
			get_repo_builder "$repo_data_working"
		fi
		if [[ -f $slackpkg_plus_file ]];then
			if [[ -n $1 ]];then
				cat $slackpkg_plus_file &> $1/repo-data_${slackpkg_plus_file//\//-}.txt
			fi
			# see sample for syntax
			repo_data_working="$( gawk -F '=' -v repoFile="$slackpkg_plus_file" '
			BEGIN {
				activeRepos=""
			}
			# stop if set to off
			/^SLACKPKGPLUS/ {
				if ( $2 == "off" ){
					exit
				}
			}
			# get list of current active repos
			/^REPOPLUS/ {
				activeRepos=$2
			}
			# print out repo line if found
			/^MIRRORPLUS/ {
				if ( activeRepos != "" ) {
					gsub(/MIRRORPLUS\['\''|'\''\]/,"",$1)
					if ( match( activeRepos, $1 ) ){
						print "slackpkg+ sources^" repoFile "^" $1 " ~ " $2
					}
				}
			}' $slackpkg_plus_file )"
			get_repo_builder "$repo_data_working"
		fi
		repo_data_working=''
	elif [[ -d $portage_repo_dir && -n $( type -p emerge ) ]];then
		repo_files=$( ls $portage_repo_dir*.conf 2>/dev/null )
		repo_name='portage'
		log_function_data "portage repo files: $repo_files"
		if [[ -n $repo_files ]];then
			for repo_file in $repo_files
			do
				if [[ -n $1 ]];then
					cat $repo_file &> $1/repo-data_${repo_file//\//-}.txt
				fi
				repo_data_working="$( gawk -v repoFile="$repo_file" '
				# construct the string for the print function to work with, file name: data
				function print_line( fileName, repoId, repoUrl ){
					print "'$repo_name' sources^" fileName "^" repoId  repoUrl
				}
				BEGIN {
					FS="\n"
					IGNORECASE=1
					enabledStatus=""
					repoTitle=""
					urlData=""
				}
				# this is a hack, assuming that each item has these fields listed, we collect the 3
				# items one by one, then when the url/enabled fields are set, we print it out and
				# reset the data. Not elegant but it works. Note that if enabled was not present
				# we assume it is enabled then, and print the line, reset the variables. This will
				# miss the last item, so it is printed if found in END
				/^\[.+\]/ {
					if ( urlData != "" && repoTitle != "" ){
						print_line( repoFile, repoTitle, urlData )
						enabledStatus=""
						urlData=""
						repoTitle=""
					}
					gsub(/\[|\]/, "", $1 ) # strip out the brackets
					repoTitle = $1 " ~ "
				}
				/^(sync-uri)/ {
					sub( /sync-uri[[:space:]]*=[[:space:]]*/, "", $1 ) # strip out the field starter
					urlData = $1
				}
				# note: enabled = 1. enabled = 0 means disabled
				/^auto-sync[[:space:]]*=/ {
					sub( /auto-sync[[:space:]]*=[[:space:]]*/, "", $1 ) # strip out the field starter
					enabledStatus = $1
				}
				# print out the line if all 3 values are found, otherwise if a new
				# repoTitle is hit above, it will print out the line there instead
				{ 
					if ( urlData != "" && enabledStatus != "" && repoTitle != "" ){
						if ( enabledStatus !~ /enabled[[:space:]]*=[[:space:]]*0/ ){
							print_line( repoFile, repoTitle, urlData )
						}
						enabledStatus=""
						urlData=""
						repoTitle=""
					}
				}
				END {
					# print the last one if there is data for it
					if ( urlData != ""  && repoTitle != "" ){
						print_line( repoFile, repoTitle, urlData )
					}
				}
				' $repo_file )"
				# then load the global for each file as it gets filled
				get_repo_builder "$repo_data_working"
			done
		fi
	elif [[ -d $pisi_dir && -n $( type -p pisi ) ]];then
		REPO_DATA="$( pisi list-repo )"
		if [[ -n $1 ]];then
			echo "$REPO_DATA" &> $1/repo-data_pisi-list-repo.txt
		fi
		log_function_data "pisi-list-repo: $REPO_DATA"
		# now we need to create the structure: repo info: repo path
		# we do that by looping through the lines of the output and then
		# putting it back into the <data>:<url> format print repos expects to see
		# note this structure in the data, so store first line and make start of line
		# then when it's an http line, add it, and create the full line collection.
# Pardus-2009.1 [Aktiv]
# 	http://packages.pardus.org.tr/pardus-2009.1/pisi-index.xml.bz2
# Contrib [Aktiv]
# 	http://packages.pardus.org.tr/contrib-2009/pisi-index.xml.bz2
		while read repo_line
		do
			repo_line=$( gawk '
			{
				# need to dump leading/trailing spaces and clear out color codes for irc output
				sub(/^[[:space:]]+|[[:space:]]+$/,"",$0)
# 				gsub(/\x1B\[([0-9]{1,2}(;[0-9]{1,2})?)?[m|K]/,"",$0) # leaving this pattern in case need it
				gsub(/\[([0-9];)?[0-9]+m/,"",$0)
				print $0
			}' <<< $repo_line )
			if [[ -n $( grep '://' <<< $repo_line ) ]];then
				repo_data_working="$repo_data_working^$repo_line\n"
			else
				repo_data_working="${repo_data_working}pisi repo^$repo_line"
			fi
		done <<< "$REPO_DATA"
		# echo and execute the line breaks inserted
		REPO_DATA="$( echo -e $repo_data_working )"
		repo_data_working=''
	# Mandriva/Mageia using: urpmq
	elif type -p urpmq &>/dev/null;then
		REPO_DATA="$( urpmq --list-media active --list-url )"
		if [[ -n $1 ]];then
			echo "$REPO_DATA" &> $1/repo-data_urpmq-list-media-active.txt
		fi
		# now we need to create the structure: repo info: repo path
		# we do that by looping through the lines of the output and then
		# putting it back into the <data>:<url> format print repos expects to see
		# note this structure in the data, so store first line and make start of line
		# then when it's an http line, add it, and create the full line collection.
# Contrib ftp://ftp.uwsg.indiana.edu/linux/mandrake/official/2011/x86_64/media/contrib/release
# Contrib Updates ftp://ftp.uwsg.indiana.edu/linux/mandrake/official/2011/x86_64/media/contrib/updates
# Non-free ftp://ftp.uwsg.indiana.edu/linux/mandrake/official/2011/x86_64/media/non-free/release
# Non-free Updates ftp://ftp.uwsg.indiana.edu/linux/mandrake/official/2011/x86_64/media/non-free/updates
# Nonfree Updates (Local19) /mnt/data/mirrors/mageia/distrib/cauldron/x86_64/media/nonfree/updates
		while read repo_line
		do
			repo_line=$( gawk '
			{
				# need to dump leading/trailing spaces and clear out color codes for irc output
				sub(/^[[:space:]]+|[[:space:]]+$/,"",$0)
# 				gsub(/\x1B\[([0-9]{1,2}(;[0-9]{1,2})?)?[m|K]/,"",$0) # leaving this pattern in case need it
				gsub(/\[([0-9];)?[0-9]+m/,"",$0)
				print $0
			}' <<< $repo_line )
			# urpmq output is the same each line, repo name space repo url, can be:
			# rsync://, ftp://, file://, http:// OR repo is locally mounted on FS in some cases
			if [[ -n $( grep -E '(://|[[:space:]]/)' <<< $repo_line ) ]];then
				# cut out the repo first
				repo_data_working2=$( grep -Eo '([^[:space:]]+://|[[:space:]]/).*' <<< $repo_line )
				# then get the repo name string by slicing out the url string
				repo_name=$( sed "s|[[:space:]]*$repo_data_working2||" <<< $repo_line )
				repo_data_working="${repo_data_working}urpmq repo^$repo_name^$repo_data_working2\n"
			fi
		done <<< "$REPO_DATA"
		# echo and execute the line breaks inserted
		REPO_DATA="$( echo -e $repo_data_working )"
	# alpine linux
	elif [[ -f $apk_file ]];then
		# note, only one file, but loop it in case more are added in future
		for repo_file in $apk_file
		do
			if [[ -n $1 ]];then
				cat $repo_file &> $1/repo-data_${repo_file//\//-}.txt
			fi
			repo_data_working="$( gawk -v repoFile="$repo_file" '
			!/^[[:space:]]*$|^[[:space:]]*#/ {
				print "APK repo^" repoFile "^" $0
			}' $repo_file )"
			get_repo_builder "$repo_data_working"
		done
		repo_data_working=''
	elif [[ -f $ports_conf || -f $freebsd_file || -d $bsd_pkg_dir ]];then
		if [[ -f $ports_conf ]];then
			if [[ -n $1 ]];then
				cat $ports_conf &> $1/repo-data_${ports_conf//\//-}.txt
			fi
			repo_data_working="$( gawk -F '=' -v repoFile=$ports_conf '
			BEGIN {
				IGNORECASE=1
			}
			/^SERVERNAME/ {
				print "BSD ports server^" repoFile "^" $2
				exit
			}
			' $ports_conf )"
			get_repo_builder "$repo_data_working"
		fi
		if [[ -f $freebsd_file ]];then
			if [[ -n $1 ]];then
				cat $freebsd_file &> $1/repo-data_${freebsd_file//\//-}.txt
			fi
			repo_data_working="$( gawk -v repoFile=$freebsd_file '
			BEGIN {
				IGNORECASE=1
			}
			/^ServerName/ {
				print "FreeBSD update server^" repoFile "^" $2
				exit
			}
			' $freebsd_file )"
			get_repo_builder "$repo_data_working"
		fi
		if [[ -f $freebsd_pkg_file ]];then
			if [[ -n $1 ]];then
				cat $freebsd_pkg_file &> $1/repo-data_${freebsd_pkg_file//\//-}.txt
			fi
			repo_data_working="$( gawk -F ': ' -v repoFile=$freebsd_pkg_file '
			BEGIN {
				IGNORECASE=1
			}
			$1 ~ /^[[:space:]]*url/ {
				gsub(/\"|pkg\+|,/,"",$2)
				print "FreeBSD default pkg server^" repoFile "^" $2
				exit
			}
			' $freebsd_pkg_file )"
			get_repo_builder "$repo_data_working"
		fi
		
		if [[ -d $bsd_pkg_dir ]];then
			repo_files=$(ls ${bsd_pkg_dir}*.conf 2>/dev/null )
			for repo_file in $repo_files
			do
				if [[ -n $1 ]];then
					cat $repo_file &> $1/repo-data_${repo_file//\//-}.txt
				fi
				repo_data_working="$( gawk -v repoFile=$repo_file '
				BEGIN {
					FS=":"
					IGNORECASE=1
					repoName=""
					repoUrl=""
					enabled=""
				}
				{
					gsub(/{|}|^#.*/,"",$0)
				}
				/^[^[:space:]]/ {
					repoName=$1
					repoUrl=""
					enabled=""
					while ( getline && $0 !~ /^[[:space:]]*$/ ) {
						gsub(/'"$BAN_LIST_ARRAY"'/,"",$0)
						gsub(/({|}|^[[:space:]]+|[[:space:]]+$)/,"",$1)
						gsub(/({|}|^[[:space:]]+|[[:space:]]+$)/,"",$2)
						if ( $1 == "url" ) {
							repoUrl=$2$3
						}
						if ( $1 == "enabled" ) {
							if ( $2 == "yes" ) {
								print "BSD pkg server^" repoFile "^" repoName " ~ " repoUrl 
							}
						}
					}
				}
				' $repo_file )"
				get_repo_builder "$repo_data_working"
			done
		fi
		repo_data_working=''
	elif [[ -f $openbsd_conf ]];then
		if [[ -n $1 ]];then
			cat $openbsd_conf &> $1/repo-data_${openbsd_conf//\//-}.txt
		fi
		REPO_DATA="$( gawk -F '=' -v repoFile=$openbsd_conf '
		BEGIN {
			IGNORECASE=1
		}
		/^installpath/ {
			print "OpenBSD pkg mirror^" repoFile "^" $2
		}
		' $openbsd_conf )"
	elif [[ -f $netbsd_file ]];then
		# note, only one file, but loop it in case more are added in future
		for repo_file in $netbsd_file
		do
			if [[ -n $1 ]];then
				cat $repo_file &> $1/repo-data_${repo_file//\//-}.txt
			fi
			repo_data_working="$( gawk -v repoFile="$repo_file" '
			!/^[[:space:]]*$|^[[:space:]]*#/ {
				print "NetBSD pkg servers^" repoFile "^" $0
			}' $repo_file )"
			get_repo_builder "$repo_data_working"
		done
		repo_data_working=''
	fi
	eval $LOGFE
}
# build the total REPO_DATA global here
# args: $1 - the repo line/s
get_repo_builder()
{
	if [[ -n $1 ]];then
		if [[ -z $REPO_DATA ]];then
			REPO_DATA="$1"
		else
			REPO_DATA="$REPO_DATA
$1"
		fi
	fi
}

get_runlevel_data()
{
	eval $LOGFS
	local runlvl=''

	if type -p runlevel &>/dev/null;then
		runlvl="$( runlevel | gawk '{ print $2 }' )"
	fi
	echo $runlvl
	eval $LOGFE
}

# note: it appears that at least as of 2014-01-13, /etc/inittab is going to be used for
# default runlevel in upstart/sysvinit. systemd default is not always set so check to see 
# if it's linked.
get_runlevel_default()
{
	eval $LOGFS
	local default_runlvl=''
	local inittab='/etc/inittab'
	local systemd_default='/etc/systemd/system/default.target'
	local upstart_default='/etc/init/rc-sysinit.conf'
	
	# note: systemd systems do not necessarily have this link created
	if [[ -L $systemd_default  ]];then
		default_runlvl=$( readlink $systemd_default )
		if [[ -n $default_runlvl ]];then
			default_runlvl=${default_runlvl##*/}
		fi
	# http://askubuntu.com/questions/86483/how-can-i-see-or-change-default-run-level
	# note that technically default can be changed at boot but for inxi purposes that does
	# not matter, we just want to know the system default
	elif [[ -e $upstart_default ]];then
		# env DEFAULT_RUNLEVEL=2
		default_runlvl=$( gawk -F '=' '/^env[[:space:]]+DEFAULT_RUNLEVEL/ {
		print $2
		}' $upstart_default )
	fi
	
	# handle weird cases where null but inittab exists
	if [[ -z $default_runlvl && -f $inittab ]];then
		default_runlvl=$( gawk -F ':' '
		/^id.*initdefault/ {
			print $2
		}' $inittab )
	fi
	echo $default_runlvl
	eval $LOGFE
}

get_sensors_data()
{
	eval $LOGFS
	
	
	local a_temp=''
		
	IFS=$'\n'
	if [[ -n $Sensors_Data ]];then
		# note: non-configured sensors gives error message, which we need to redirect to stdout
		# also, -F ':' no space, since some cases have the data starting right after,like - :1287
		A_SENSORS_DATA=( $( 
  		gawk -F ':' -v userCpuNo="$SENSORS_CPU_NO" '
		BEGIN {
			IGNORECASE=1
			core0Temp="" # these only if all else fails...
			cpuPeciTemp="" # use if temps are missing or wrong
			cpuTemp=""
			cpuTempReal=""
			fanWorking=""
			indexCountaFanMain=0
			indexCountaFanDefault=0
			i=""
			j=""
			moboTemp=""
			moboTempReal=""
			psuTemp=""
			separator=""
			sysFanString=""
			temp1=""
			temp2=""
			temp3=""
			tempDiff=20 # for C, handled for F after that is determined
			tempFanType="" # set to 1 or 2
			tempUnit=""
			tempWorking=""
			tempWorkingUnit=""
		}
		# new data arriving: gpu temp in sensors, have to skip that
		/^('"$SENSORS_GPU_SEARCH"')-pci/ {
			while ( getline && !/^$/ ) {
				# do nothing, just skip it
			}
		}
		# dumping the extra + signs after testing for them,  nobody has negative temps.
		# also, note gawk treats ° as a space, so we have to get the C/F data
		# there are some guesses here, but with more sensors samples it will get closer.
		# note: using arrays starting at 1 for all fan arrays to make it easier overall
		# more validation because gensub if fails to get match returns full string, so
		# we have to be sure we are working with the actual real string before assiging
		# data to real variables and arrays. Extracting C/F degree unit as well to use
		# when constructing temp items for array. 
		# note that because of charset issues, no tempUnit="°" tempWorkingUnit degree sign 
		# used, but it is required in testing regex to avoid error.
		/^(M\/B|MB|SIO|SYS)(.*)\+([0-9]+)(.*)[ \t°](C|F)/ && $2 ~ /^[ \t]*\+([0-9]+)/ {
			moboTemp=gensub( /[ \t]+\+([0-9\.]*)(.*)/, "\\1", 1, $2 )
			tempWorkingUnit=gensub( /[ \t]+\+([0-9\.]+)[ \t°]+([CF])(.*)/, "\\2", 1, $2 )
			if ( tempWorkingUnit ~ /^C|F$/ && tempUnit == "" ){
				tempUnit=tempWorkingUnit
			}
		}
		# issue 58 msi/asus show wrong for CPUTIN so overwrite it if PECI 0 is present
		# http://www.spinics.net/lists/lm-sensors/msg37308.html
		/^CPU(.*)\+([0-9]+)(.*)[ \t°](C|F)/ && $2 ~ /^[ \t]*\+([0-9]+)/ {
			cpuTemp=gensub( /[ \t]+\+([0-9\.]+)(.*)/, "\\1", 1, $2 )
			tempWorkingUnit=gensub( /[ \t]+\+([0-9\.]+)[ \t°]+([CF])(.*)/, "\\2", 1, $2 )
			if ( tempWorkingUnit ~ /^C|F$/ && tempUnit == "" ){
				tempUnit=tempWorkingUnit
			}
		}
		/^PECI[[:space:]]Agent[[:space:]]0(.*)\+([0-9]+)(.*)[ \t°](C|F)/ && $2 ~ /^[ \t]*\+([0-9]+)/ {
			cpuPeciTemp=gensub( /[ \t]+\+([0-9\.]+)(.*)/, "\\1", 1, $2 )
			tempWorkingUnit=gensub( /[ \t]+\+([0-9\.]+)[ \t°]+([CF])(.*)/, "\\2", 1, $2 )
			if ( tempWorkingUnit ~ /^C|F$/ && tempUnit == "" ){
				tempUnit=tempWorkingUnit
			}
		}
		/^(P\/S|Power)(.*)\+([0-9]+)(.*)[ \t°](C|F)/ && $2 ~ /^[ \t]*\+([0-9]+)/ {
			psuTemp=gensub( /[ \t]+\+([0-9\.]+)(.*)/, "\\1", 1, $2 )
			tempWorkingUnit=gensub( /[ \t]+\+([0-9\.]+)[ \t°]+([CF])(.*)/, "\\2", 1, $2 )
			if ( tempWorkingUnit ~ /^C|F$/ && tempUnit == "" ){
				tempUnit=tempWorkingUnit
			}
		}
		# for temp1/2 only use temp1/2 if they are null or greater than the last ones
		$1 ~ /^temp1$/ && $2 ~ /^[ \t]*\+([0-9]+)/ {
			tempWorking=gensub( /[ \t]+\+([0-9\.]+)(.*)/, "\\1", 1, $2 )
			if ( temp1 == "" || ( tempWorking != "" && tempWorking > 0 ) ) {
				temp1=tempWorking
			}
			tempWorkingUnit=gensub( /[ \t]+\+([0-9\.]+)[ \t°]+([CF])(.*)/, "\\2", 1, $2 )
			if ( tempWorkingUnit ~ /^C|F$/ && tempUnit == "" ){
				tempUnit=tempWorkingUnit
			}
		}
		$1 ~ /^temp2$/ && $2 ~ /^[ \t]*\+([0-9]+)/ {
			tempWorking=gensub( /[ \t]+\+([0-9\.]+)(.*)/, "\\1", 1, $2 )
			if ( temp2 == "" || ( tempWorking != "" && tempWorking > 0 ) ) {
				temp2=tempWorking
			}
			tempWorkingUnit=gensub( /[ \t]+\+([0-9\.]+)[ \t°]+([CF])(.*)/, "\\2", 1, $2 )
			if ( tempWorkingUnit ~ /^C|F$/ && tempUnit == "" ){
				tempUnit=tempWorkingUnit
			}
		}
		# temp3 is only used as an absolute override for systems with all 3 present
		$1 ~ /^temp3$/ && $2 ~ /^[ \t]*\+([0-9]+)/ {
			tempWorking=gensub( /[ \t]+\+([0-9\.]+)(.*)/, "\\1", 1, $2 )
			if ( temp3 == "" || ( tempWorking != "" && tempWorking > 0 ) ) {
				temp3=tempWorking
			}
			tempWorkingUnit=gensub( /[ \t]+\+([0-9\.]+)[ \t°]+([CF])(.*)/, "\\2", 1, $2 )
			if ( tempWorkingUnit ~ /^C|F$/ && tempUnit == "" ){
				tempUnit=tempWorkingUnit
			}
		}
		# final fallback if all else fails, funtoo user showed sensors putting
		# temp on wrapped second line, not handled
		/^(core0|core 0|Physical id 0)(.*)\+([0-9]+)(.*)[ \t°](C|F)/ && $2 ~ /^[ \t]*\+([0-9]+)/ {
			tempWorking=gensub( /[ \t]+\+([0-9\.]+)(.*)/, "\\1", 1, $2 )
			if ( tempWorking != "" && core0Temp == "" && tempWorking > 0 ) {
				core0Temp=tempWorking
			}
			tempWorkingUnit=gensub( /[ \t]+\+([0-9\.]+)[ \t°]+([CF])(.*)/, "\\2", 1, $2 )
			if ( tempWorkingUnit ~ /^C|F$/ && tempUnit == "" ){
				tempUnit=tempWorkingUnit
			}
		}
		# note: can be cpu fan:, cpu fan speed:, etc. Some cases have no space before
		# $2 starts (like so :1234 RPM), so skip that space test in regex
		/^CPU(.*)[ \t]*([0-9]+)[ \t]RPM/ {
			aFanMain[1]=gensub( /[ \t]*([0-9]+)[ \t]+(.*)/, "\\1", 1, $2 )
		}
		/^(M\/B|MB|SYS)(.*)[ \t]*([0-9]+)[ \t]RPM/ {
			aFanMain[2]=gensub( /[ \t]*([0-9]+)[ \t]+(.*)/, "\\1", 1, $2 )
		}
		/(Power|P\/S|POWER)(.*)[ \t]*([0-9]+)[ \t]RPM/ {
			aFanMain[3]=gensub( /[ \t]*([0-9]+)[ \t]+(.*)/, "\\1", 1, $2 )
		}
		# note that the counters are dynamically set for fan numbers here
		# otherwise you could overwrite eg aux fan2 with case fan2 in theory
		# note: cpu/mobo/ps are 1/2/3
		# NOTE: test: ! i in array does NOT work, this appears to be an awk/gawk bug
		/^(AUX(1)? |CASE(1)? |CHASSIS(1)? )(.*)[ \t]*([0-9]+)[ \t]RPM/ {
			for ( i = 4; i < 7; i++ ){
				if ( i in aFanMain ){
					##
				}
				else {
					aFanMain[i]=gensub( /[ \t]*([0-9]+)[ \t]+(.*)/, "\\1", 1, $2 )
					break
				}
			}
		}
		/^(AUX([2-9]) |CASE([2-9]) |CHASSIS([2-9]) )(.*)[ \t]*([0-9]+)[ \t]RPM/ {
			for ( i = 5; i < 30; i++ ){
				if ( i in aFanMain ) {
					##
				}
				else {
					sysFanNu = i
					aFanMain[i]=gensub( /[ \t]*([0-9]+)[ \t]+(.*)/, "\\1", 1, $2 )
					break
				}
			}
		}
		# in rare cases syntax is like: fan1: xxx RPM
		/^(FAN(1)?[ \t:])(.*)[ \t]*([0-9]+)[ \t]RPM/ {
			aFanDefault[1]=gensub( /[ \t]*([0-9]+)[ \t]+(.*)/, "\\1", 1, $2 )
		}
		/^FAN([2-9]|1[0-9])(.*)[ \t]*([0-9]+)[ \t]RPM/ {
			fanWorking=gensub( /[ \t]*([0-9]+)[ \t]+(.*)/, "\\1", 1, $2 )
			sysFanNu=gensub( /fan([0-9]+)/, "\\1", 1, $1 )
			if ( sysFanNu ~ /^([0-9]+)$/ ) {
				# add to array if array index does not exist OR if number is > existing number
				if ( sysFanNu in aFanDefault ) {
					if ( fanWorking >= aFanDefault[sysFanNu] ) {
						aFanDefault[sysFanNu]=fanWorking
					}
				}
				else {
					aFanDefault[sysFanNu]=fanWorking
				}
			}
		}
		END {
			# first we need to handle the case where we have to determine which temp/fan to use for cpu and mobo:
			# note, for rare cases of weird cool cpus, user can override in their prefs and force the assignment
			# this is wrong for systems with > 2 tempX readings, but the logic is too complex with 3 variables
			# so have to accept that it will be wrong in some cases, particularly for motherboard temp readings.
			if ( temp1 != "" && temp2 != "" ){
				if ( userCpuNo != "" && userCpuNo ~ /(1|2)/ ) {
					tempFanType=userCpuNo
				}
				else {
					# first some fringe cases with cooler cpu than mobo: assume which is cpu temp based on fan speed
					# but only if other fan speed is 0.
					if ( temp1 >= temp2 && 1 in aFanDefault && 2 in aFanDefault && aFanDefault[1] == 0 && aFanDefault[2] > 0 ) {
						tempFanType=2
					}
					else if ( temp2 >= temp1 && 1 in aFanDefault && 2 in aFanDefault && aFanDefault[2] == 0 && aFanDefault[1] > 0 ) {
						tempFanType=1
					}
					# then handle the standard case if these fringe cases are false
					else if ( temp1 >= temp2 ) {
						tempFanType=1
					}
					else {
						tempFanType=2
					}
				}
			}
			# need a case for no temps at all reported, like with old intels
			else if ( temp2 == "" && cpuTemp == "" ){
				if ( temp1 == "" && moboTemp == "" ){
					tempFanType=1
				}
				else if ( temp1 != "" && moboTemp == "" ){
					tempFanType=1
				}
				else if ( temp1 != "" && moboTemp != "" ){
					tempFanType=1
				}
			}
			# convert the diff number for F, it needs to be bigger that is
			if ( tempUnit == "F" ) {
				tempDiff = tempDiff * 1.8
			}
			if ( cpuTemp != "" ) {
				# specific hack to handle broken CPUTIN temps with PECI
				if ( cpuPeciTemp != "" && ( cpuTemp - cpuPeciTemp ) > tempDiff ){
					cpuTempReal=cpuPeciTemp
				}
				# then get the real cpu temp, best guess is hottest is real
				else {
					cpuTempReal=cpuTemp
				}
			}
			else {
				if ( tempFanType != "" ){
					# there are some weird scenarios
					if ( tempFanType == 1 ){
						if ( temp1 != "" && temp2 != "" && temp2 > temp1 ) {
							cpuTempReal=temp2
						}
						else {
							cpuTempReal=temp1
						}
					}
					else {
						if ( temp1 != "" && temp2 != "" && temp1 > temp2 ) {
							cpuTempReal=temp1
						}
						else {
							cpuTempReal=temp2
						}
					}
				}
				else {
					cpuTempReal=temp1 # can be null, that is ok
				}
				if ( cpuTempReal != "" ) {
					# using temp3 is just not reliable enough, more errors caused than fixed imo
					#if ( temp3 != "" && temp3 > cpuTempReal ) {
					#	cpuTempReal=temp3
					#}
					# there are some absurdly wrong temp1: acpitz-virtual-0 temp1: +13.8°C
					if ( core0Temp != "" && (core0Temp - cpuTempReal) > tempDiff ) {
						cpuTempReal=core0Temp
					}
				}
			}
			# if all else fails, use core0/peci temp if present and cpu is null
			if ( cpuTempReal == "" ) {
				if ( core0Temp != "" ) {
					cpuTempReal=core0Temp
				}
				# note that peci temp is known to be colder than the actual system
				# sometimes so it is the last fallback we want to use even though in theory
				# it is more accurate, but fact suggests theory wrong.
				else if ( cpuPeciTemp != "" ) {
					cpuTempReal=cpuPeciTemp
				}
			}
			# then the real mobo temp
			if ( moboTemp != "" ){
				moboTempReal=moboTemp
			}
			else if ( tempFanType != "" ){
				if ( tempFanType == 1 ) {
					if ( temp1 != "" && temp2 != "" && temp2 > temp1 ) {
						moboTempReal=temp1
					}
					else {
						moboTempReal=temp2
					}
				}
				else {
					if ( temp1 != "" && temp2 != "" && temp1 > temp2 ) {
						moboTempReal=temp2
					}
					else {
						moboTempReal=temp1
					}
				}
				## NOTE: not safe to assume temp3 is the mobo temp, sad to say
				#if ( temp1 != "" && temp2 != "" && temp3 != "" && temp3 < moboTempReal ) {
				#	moboTempReal= temp3
				#}
			}
			else {
				moboTempReal=temp2
			}
			# then set the cpu fan speed
			if ( aFanMain[1] == "" ) {
				# note, you cannot test for aFanDefault[1] or [2] != "" 
				# because that creates an array item in gawk just by the test itself
				if ( tempFanType == 1 && 1 in aFanDefault ) {
					aFanMain[1]=aFanDefault[1]
					aFanDefault[1]=""
				}
				else if ( tempFanType == 2 && 2 in aFanDefault ) {
					aFanMain[1]=aFanDefault[2]
					aFanDefault[2]=""
				}
			}
			# then we need to get the actual numeric max array count for both fan arrays
			for (i = 0; i <= 29; i++) {
				if ( i in aFanMain && i > indexCountaFanMain ) {
					indexCountaFanMain=i
				}
			}
			for (i = 0; i <= 14; i++) {
				if ( i in aFanDefault && i > indexCountaFanDefault ) {
					indexCountaFanDefault=i
				}
			}
			# clear out any duplicates. Primary fan real trumps fan working always if same speed
			for (i = 1; i <= indexCountaFanMain; i++) {
				if ( i in aFanMain && aFanMain[i] != "" && aFanMain[i] != 0 ) {
					for (j = 1; j <= indexCountaFanDefault; j++) {
						if ( j in aFanDefault && aFanMain[i] == aFanDefault[j] ) {
							aFanDefault[j] = ""
						}
					}
				}
			}
			# now see if you can find the fast little mobo fan, > 5000 rpm and put it as mobo
			# note that gawk is returning true for some test cases when aFanDefault[j] < 5000
			# which has to be a gawk bug, unless there is something really weird with arrays
			# note: 500 > aFanDefault[j] < 1000 is the exact trigger, and if you manually 
			# assign that value below, the > 5000 test works again, and a print of the value
			# shows the proper value, so the corruption might be internal in awk. 
			# Note: gensub is the culprit I think, assigning type string for range 501-1000 but 
			# type integer for all others, this triggers true for >
			for (j = 1; j <= indexCountaFanDefault; j++) {
				if ( j in aFanDefault && int( aFanDefault[j] ) > 5000 && aFanMain[2] == "" ) {
					aFanMain[2] = aFanDefault[j]
					aFanDefault[j] = ""
					# then add one if required for output
					if ( indexCountaFanMain < 2 ) {
						indexCountaFanMain = 2
					}
				}
			}
			# then construct the sys_fan string for echo, note that iteration 1
			# makes: fanDefaultString separator null, ie, no space or ,
			for (j = 1; j <= indexCountaFanDefault; j++) {
				fanDefaultString = fanDefaultString separator aFanDefault[j]
				separator=","
			}
			separator="" # reset to null for next loop
			# then construct the sys_fan string for echo
			for (j = 1; j <= indexCountaFanMain; j++) {
				fanMainString = fanMainString separator aFanMain[j]
				separator=","
			}
			
			# and then build the temps:
			if ( moboTempReal != "" ) {
				moboTempReal = moboTempReal tempUnit
			}
			if ( cpuTempReal != "" ) {
				cpuTempReal = cpuTempReal tempUnit
			}
			# if they are ALL null, print error message. psFan is not used in output currently
			if ( cpuTempReal == "" && moboTempReal == "" && aFanMain[1] == "" && aFanMain[2] == "" && aFanMain[3] == "" && fanDefaultString == "" ) {
				print "No active sensors found. Have you configured your sensors yet?"
			}
			else {
				# then build array arrays: 
				print cpuTempReal "," moboTempReal "," psuTemp
				# this is for output, a null print line does NOT create a new array index in bash
				if ( fanMainString == "" ) {
					fanMainString=","
				}
				print fanMainString
				print fanDefaultString
			}
		}' <<< "$Sensors_Data" ) )
	fi
	
	IFS="$ORIGINAL_IFS"
	a_temp=${A_SENSORS_DATA[@]}
	log_function_data "A_SENSORS_DATA: $a_temp"
# 	echo "A_SENSORS_DATA: ${A_SENSORS_DATA[@]}"
	eval $LOGFE
}

get_sensors_output()
{
	local sensors_data=''
	
	if type -p sensors &>/dev/null;then
		sensors_data="$( sensors 2>/dev/null )"
		if [[ -n "$sensors_data" ]];then
			# make sure the file ends in newlines then characters, the newlines are lost in the echo unless
			# the data ends in some characters
			sensors_data="$sensors_data\n\n###" 
		fi
	fi
	echo -e "$sensors_data"
}

get_shell_data()
{
	eval $LOGFS

	local shell_type="$( ps -p $PPID -o comm= 2>/dev/null )"
	local shell_version='' 
	
	if [[ $B_EXTRA_DATA == 'true' && -n $shell_type ]];then
		case $shell_type in
			bash)
				shell_version=$( get_program_version "$shell_type" "^GNU[[:space:]]bash,[[:space:]]version" "4" | \
				sed $SED_RX 's/(\(.*|-release|-version)//' )
				;;
			# csh/dash use dpkg package version data, debian/buntu only
			csh)
				shell_version=$( get_program_version "$shell_type" "^tcsh" "2" )
				;;
			dash)
				shell_version=$( get_program_version "$shell_type" "$shell_type" "3" )
				;;
			ksh)
				shell_version=$( get_program_version "$shell_type" "version" "5" )
				;;
			tcsh)
				shell_version=$( get_program_version "$shell_type" "^tcsh" "2" )
				;;
			zsh)
				shell_version=$( get_program_version "$shell_type" "^zsh" "2" )
				;;
		esac
	fi
	if [[ -n $shell_version ]];then
		shell_type="$shell_type $shell_version"
	fi
	echo $shell_type
	log_function_data "shell type: $shell_type"
	eval $LOGFE
}

get_shell_parent()
{
	eval $LOGFS
	local shell_parent='' script_parent='' 
	
	# removed --no-headers to make bsd safe, adding in -j to make output the same
	script_parent=$( ps -j -fp $PPID 2>/dev/null | gawk '/'"$PPID"'/ { print $3 }' )
	log_function_data "script parent: $script_parent"
	shell_parent=$( ps -j -p $script_parent 2>/dev/null | gawk '/'"$script_parent"'/ { print $NF}' )
	# no idea why have to do script_parent action twice in su case, but you do, oh well.
	if [[ $shell_parent == 'su' ]];then
		script_parent=$( ps -j -fp $script_parent 2>/dev/null | gawk '/'"$script_parent"'/ { print $3 }' )
		script_parent=$( ps -j -fp $script_parent 2>/dev/null | gawk '/'"$script_parent"'/ { print $3 }' )
		shell_parent=$( ps -j -p $script_parent 2>/dev/null | gawk '/'"$script_parent"'/ { print $NF}' )
	fi
	echo $shell_parent
	log_function_data "shell parent final: $shell_parent"
	eval $LOGFE
}

# this will be used for some bsd data types
# args: $1 - option type
get_sysctl_data()
{
	eval $LOGFS
	
	local sysctl_data=''
	
	if [[ $B_SYSCTL ]];then
		# darwin sysctl has BOTH = and : separators, and repeats data. Why? No bsd discipline, that's for sure
		if [[ $BSD_VERSION == 'darwin' ]];then
			sysctl_data="$( sysctl -$1 | sed 's/[[:space:]]*=[[:space:]]*/: /' )"
		else
			sysctl_data="$( sysctl -$1 )"
		fi
	fi
	if [[ $1 == 'a' ]];then
		SYSCTL_A_DATA="$sysctl_data"
	fi
	log_function_data "sysctl_data: $sysctl_data"
	
	eval $LOGFE
}

get_tty_console_irc()
{
	eval $LOGFS
	local tty_number=''
	if [[ -n $IRC_CLIENT ]];then
		tty_number=$( gawk '
			BEGIN {
				IGNORECASE=1
			}
			# if multiple irc clients open, can give wrong results
			# so make sure to also use the PPID number to get the right tty
			/.*'$PPID'.*'$IRC_CLIENT'/ {
				gsub(/[^0-9]/, "", $7)
				print $7
				exit
			}' <<< "$Ps_aux_Data" )
	fi
	log_function_data "tty_number: $tty_number"
	echo $tty_number
	eval $LOGFE
}

get_tty_number()
{
	eval $LOGFS
	
	local tty_number=$( tty 2>/dev/null | sed 's/[^0-9]*//g' )
	tty_number=${tty_number##*/}
	echo ${tty_number##*/}
	
	eval $LOGFE
}

get_unmounted_partition_data()
{
	eval $LOGFS
	local a_unmounted_working='' mounted_partitions='' separator='|' unmounted_fs=''
	local dev_working='' uuid_working='' label_working='' a_raid_working='' raid_partitions=''
	
	if [[ $B_PARTITIONS_FILE == 'true' ]];then
		# set dev disk label/uuid data globals
		get_partition_dev_data 'label'
		get_partition_dev_data 'uuid'
		# load the raid data array here so we can exclude its partitions
		if [[ $B_RAID_SET != 'true' ]];then
			get_raid_data
		fi
		# sr0 type cd drives are showing up now as unmounted partitions.
		mounted_partitions="scd[0-9]+|sr[0-9]+|cdrom[0-9]*|cdrw[0-9]*|dvd[0-9]*|dvdrw[0-9]*|fd[0-9]|ram[0-9]*"
		# create list for slicing out the mounted partitions
		for (( i=0; i < ${#A_PARTITION_DATA[@]}; i++ ))
		do
			IFS=","
			a_unmounted_working=( ${A_PARTITION_DATA[i]} )
			IFS="$ORIGINAL_IFS"
			if [[ -n ${a_unmounted_working[6]} ]];then
				# escape '/' for remote mounts, the path would be: [domain|ip]:/path/in/remote
				mounted_partitions="$mounted_partitions$separator${a_unmounted_working[6]//\//\\/}"
			fi
		done
		# now we need to exclude the mdraid partitions from the unmounted partition output as well
		for (( i=0; i < ${#A_RAID_DATA[@]}; i++ ))
		do
			IFS=","
			a_raid_working=( ${A_RAID_DATA[i]} )
			IFS="$ORIGINAL_IFS"
			if [[ -n ${a_raid_working[3]} ]];then
				raid_partitions=$( sed $SED_RX 's/(\([^\)]*\)|\[[^\]]*\])//g' <<< ${a_raid_working[3]}\
				| sed 's/[[:space:]]\+/|/g' )
				mounted_partitions="$mounted_partitions$separator$raid_partitions"
			fi
		done
		# grep -Ev '[[:space:]]('$mounted_partitions')$' $FILE_PARTITIONS | 
		A_UNMOUNTED_PARTITION_DATA=( $( gawk '
		BEGIN {
			IGNORECASE=1
		}
		# note that size 1 means it is a logical extended partition container
		# lvm might have dm-1 type syntax
		# need to exclude loop type file systems, squashfs for example
		/[a-z][0-9]+$|dm-[0-9]+$/ && $3 != 1 && $NF !~ /loop/ && $NF !~ /'$mounted_partitions'/ {
			size = sprintf( "%.2f", $3*1024/1000**3 )
			print $4 "," size "G"
		}' $FILE_PARTITIONS ) )

		for (( i=0; i < ${#A_UNMOUNTED_PARTITION_DATA[@]}; i++ ))
		do
			IFS=","
			a_unmounted_working=( ${A_UNMOUNTED_PARTITION_DATA[i]} )
			IFS="$ORIGINAL_IFS"
			
			label_working=$( grep -E "${a_unmounted_working[0]}$" <<< "$DEV_DISK_LABEL"  | gawk '{
				print $(NF - 2)
			}' )
			uuid_working=$( grep -E "${a_unmounted_working[0]}$" <<< "$DEV_DISK_UUID"  | gawk '{
				print $(NF - 2)
			}' )
			unmounted_fs=$( get_unmounted_partition_filesystem "/dev/${a_unmounted_working[0]}" )
			
			IFS=","
			A_UNMOUNTED_PARTITION_DATA[i]=${a_unmounted_working[0]}","${a_unmounted_working[1]}","$label_working","$uuid_working","$unmounted_fs
			IFS="$ORIGINAL_IFS"
		done
	fi
#	echo "${A_PARTITION_DATA[@]}"
# 	echo "${A_UNMOUNTED_PARTITION_DATA[@]}"
	eval $LOGFE
}

# a few notes, normally file -s requires root, but you can set user rights in /etc/sudoers.
# list of file systems: http://en.wikipedia.org/wiki/List_of_file_systems
# args: $1 - /dev/<disk><part> to be tested for
get_unmounted_partition_filesystem()
{
	eval $LOGFS
	local partition_filesystem='' sudo_command=''
	
	if [[ $B_FILE_TESTED != 'true' ]];then
		B_FILE_TESTED='true'
		FILE_PATH=$( type -p file )
	fi
	
	if [[ $B_SUDO_TESTED != 'true' ]];then
		B_SUDO_TESTED='true'
		SUDO_PATH=$( type -p sudo )
	fi
	
	if [[ -n $FILE_PATH && -n $1 ]];then
		# only use sudo if not root, -n option requires sudo -V 1.7 or greater. sudo will just error out
		# which is the safest course here for now, otherwise that interactive sudo password thing is too annoying
		# important: -n makes it non interactive, no prompt for password
		if [[ $B_ROOT != 'true' && -n $SUDO_PATH ]];then
			sudo_command='sudo -n '
		fi
		# this will fail if regular user and no sudo present, but that's fine, it will just return null
		# note the hack that simply slices out the first line if > 1 items found in string
		# also, if grub/lilo is on partition boot sector, no file system data is available
		# BSD fix: -Eio -Em 1
		partition_filesystem=$( eval $sudo_command $FILE_PATH -s $1 | grep -Eio '(ext2|ext3|ext4|ext5|ext[[:space:]]|ntfs|fat32|fat16|fat[[:space:]]\(.*\)|vfat|fatx|tfat|swap|btrfs|ffs[[:space:]]|hfs\+|hfs[[:space:]]plus|hfs[[:space:]]extended[[:space:]]version[[:space:]][1-9]|hfsj|hfs[[:space:]]|jfs[[:space:]]|nss[[:space:]]|reiserfs|reiser4|ufs2|ufs[[:space:]]|xfs[[:space:]]|zfs[[:space:]])' | grep -Em 1 '.*' )
		if [[ -n $partition_filesystem ]];then
			echo $partition_filesystem
		fi
	fi
	eval $LOGFE
}

## return uptime string
get_uptime()
{
	eval $LOGFS
	local uptime_value=''
	## note: removing gsub(/ /,"",a); to get get space back in there, goes right before print a
	if type -p uptime &>/dev/null;then
		uptime_value="$( uptime | gawk '{
			a = gensub(/^.*up *([^,]*).*$/,"\\1","g",$0)
			print a
		}' )"
	fi
	log_function_data "uptime_value: $uptime_value"
	UP_TIME="$uptime_value"
	eval $LOGFE
}

get_weather_data()
{
	eval $LOGFS
	
	local location_site='http://geoip.ubuntu.com/lookup'
	local weather_feed='http://api.wunderground.com/auto/wui/geo/WXCurrentObXML/index.xml?query='
	local weather_spider='http://wunderground.com/'
	local data_grab_error='' downloader_error=0 
	local b_test_loc=false b_test_weather=false b_debug=false
	local test_dir="$HOME/bin/scripts/inxi/data/weather/"
	local test_location='location2.xml' test_weather='weather-feed.xml'
	local location_data='' location='' weather_data='' location_array_value='' a_location=''
	local weather_array_value='' site_elevation='' a_temp=''
	
	# first we get the location data, once that is parsed and handled, we move to getting the 
	# actual weather data, assuming no errors
	if [[ -n $ALTERNATE_WEATHER_LOCATION ]];then
		# note, this api does not support spaces in names, replace spaces with + sign.
		location=$ALTERNATE_WEATHER_LOCATION
		# echo $ALTERNATE_WEATHER_LOCATION;exit
	else
		if [[ $b_test_loc != 'true' ]];then
			case $DOWNLOADER in
				curl)
					location_data="$( curl $NO_SSL_OPT -y $DL_TIMEOUT -s $location_site )" || downloader_error=$?
					;;
				fetch)
					location_data="$( fetch $NO_SSL_OPT -T $DL_TIMEOUT -q -o - $location_site )" || downloader_error=$?
					;;
				ftp)
					location_data="$( ftp $NO_SSL_OPT -o - $location_site 2>/dev/null )" || downloader_error=$?
					;;
				wget)
					location_data="$( wget $NO_SSL_OPT -t 1 -T $DL_TIMEOUT -q -O - $location_site )" || downloader_error=$?
					;;
				no-downloader)
					downloader_error=100
					;;
			esac
			log_function_data "$location_data"
			
			if [[ $downloader_error -ne 0 ]];then
				if [[ $downloader_error -eq 100 ]];then
					data_grab_error="Error: No downloader tool available. Install wget, curl, or fetch."
				else
					data_grab_error="Error: location server up but download error - $DOWNLOADER: $downloader_error"
				fi
			fi
			downloader_error=0
		else
			if [[ -f $test_dir$test_location ]];then
				location_data="$( cat $test_dir$test_location )"
			else
				data_grab_error="Error: location xml local file not found."
			fi
		fi
		if [[ -n $data_grab_error ]];then
			:
		elif [[ -z $( grep -i '<Response' <<< $location_data ) ]];then
			data_grab_error="Error: location downloaded but data contains no xml."
		else
			# clean up xml and make easy to process with newlines, note, bsd sed has no support for inserting
			# \n dircctly so we have to use this hack
			# location_data="$( sed $SED_RX 's|><|>\n<|g' <<< $location_data )"
			location_data="$( sed $SED_RX 's|><|>\
<|g' <<< $location_data )"
			# echo -e "ld:\n$location_data"
			location_array_value=$( gawk '
			function clean(data) {
				returnData=""
				# some lines might be empty, so ignore those
				if (data !~ /^<[^>]+>$/ ) {
					returnData=gensub(/(.*>)([^<]*)(<.*)/, "\\2", 1, data)
				}
				return returnData
			}
			BEGIN {
				IGNORECASE=1
				locationString=""
				countryCode=""
				countryCode3=""
				countryName=""
				regionCode=""
				regionName=""
				city=""
				postalCode=""
				latitude=""
				longitude=""
				timeZone=""
				areaCode=""
			}
			/CountryCode/ {
				if ( $0 ~ /CountryCode3/ ){
					countryCode3=clean($0)
				}
				else {
					countryCode=clean($0)
				}
			}
			/CountryName/ {
				countryName = clean($0)
			}
			/RegionCode/ {
				regionCode = clean($0)
			}
			/RegionName/ {
				regionName = clean($0)
			}
			/City/ {
				city = clean($0)
			}
			/ZipPostalCode/ {
				postalCode = clean($0)
			}
			/Latitude/ {
				latitude = clean($0)
			}
			/Longitude/ {
				longitude = clean($0)
			}
			/TimeZone/ {
				timeZone = clean($0)
			}
			END {
				locationString = city ";" regionCode ";" regionName ";" countryName ";" countryCode ";" countryCode3 
				locationString = locationString  ";" latitude "," longitude ";" postalCode ";" timeZone
				print locationString
			}' <<< "$location_data" )
		fi
		A_WEATHER_DATA[0]=$location_array_value
		IFS=";"
		a_location=( ${A_WEATHER_DATA[0]} )
		IFS="$ORIGINAL_IFS"
		
		# assign location, cascade from most accurate
		# latitude,longitude first
		if [[ -n ${a_location[6]} ]];then
			location="${a_location[6]}"
		# city,state next
		elif [[ -n ${a_location[0]} && -n ${a_location[1]} ]];then
			location="${a_location[0]},${a_location[1]}"
		# postal code last, that can be a very large region
		elif [[ -n ${a_location[7]} ]];then
			location=${a_location[7]}
		fi
	fi
	if [[ $b_debug == 'true' ]];then
		echo -e "location array:\n${A_WEATHER_DATA[0]}"
		echo "location: $location"
	fi
	log_function_data "location: $location"
	
	if [[ -z $location && -z $data_grab_error ]];then
		data_grab_error="Error: location data downloaded but no location detected."
	fi

	# now either dump process or go on to get weather data
	if [[ -z $data_grab_error ]];then
		if [[ $b_test_weather != 'true' ]];then
			case $DOWNLOADER in
				curl)
					weather_data="$( curl $NO_SSL_OPT -y $DL_TIMEOUT -s $weather_feed"$location" )" || downloader_error=$?
					;;
				fetch)
					weather_data="$( fetch $NO_SSL_OPT -T $DL_TIMEOUT -q -o - $weather_feed"$location" )" || downloader_error=$?
					;;
				ftp)
					weather_data="$( ftp $NO_SSL_OPT -o - $weather_feed"$location" 2>/dev/null )" || downloader_error=$?
					;;
				wget)
					weather_data="$( wget $NO_SSL_OPT -t 1 -T $DL_TIMEOUT -q -O - $weather_feed"$location" )" || downloader_error=$?
					;;
				no-downloader)
					downloader_error=100
					;;
			esac
			if [[ $downloader_error -ne 0 ]];then
				if [[ $downloader_error -eq 100 ]];then
					data_grab_error="Error: No downloader tool available. Install wget, curl, or fetch."
				else
					data_grab_error="Error: weather server up but download error - $DOWNLOADER: $downloader_error"
				fi
			fi
			log_function_data "$weather_data"
		else
			if [[ -f $test_dir$test_weather ]];then
				weather_data="$( cat $test_dir$test_weather)"
			else
				data_grab_error="Error: weather feed xml local file not found."
			fi
		fi
		if [[ -z $data_grab_error && -z $( grep -i '<current_observation' <<< $weather_data ) ]];then
			data_grab_error="Error: weather data downloaded but shows no xml start."
		fi
		if [[ -z $data_grab_error ]];then
			# trim off zeros
			weather_data=$( sed 's/^[[:space:]]*//' <<< "$weather_data" )
			site_elevation=$( grep -im 1 '<elevation>' <<< "$weather_data" | sed $SED_RX -e 's/<[^>]*>//g' \
			-e 's/\.[0-9]*//' )
			# we need to grab the location data from the feed for remote checks 
			if [[ -n $ALTERNATE_WEATHER_LOCATION && -n $weather_data ]];then
				location_data=$( sed -e '/<current_observation>/,/<display_location>/d' -e '/<\/display_location>/,/<\/current_observation>/d' <<< "$weather_data" )
				# echo -e "ld1:\n$location_data"
				A_WEATHER_DATA[0]=$( gawk '
				function clean(data) {
					returnData=""
					# some lines might be empty, so ignore those
					if (data !~ /^<[^>]+>$/ ) {
						returnData=gensub(/(.*>)([^<]*)(<.*)/, "\\2", 1, data)
						gsub(/^[[:space:]]+|[[:space:]]+$|^NA$|^N\/A$/, "", returnData)
					}
					return returnData
				}
				BEGIN {
					IGNORECASE=1
					city=""
					state=""
					country=""
				}
				/<city>/ {
					city=clean($0)
				}
				/<state>/ {
					state=clean($0)
				}
				/<country>/ {
					country=clean($0)
				}
				END {
					print city ";" state ";;;;" country
				}' <<< "$location_data" )
				# echo -e "location:\n${A_WEATHER_DATA[0]}"
			fi
			
			# clean off everything before/after observation_location
			weather_data=$( sed -e '/<current_observation>/,/<observation_location>/d' \
			-e '/<icons>/,/<\/current_observation>/d' <<< "$weather_data" -e 's/^[[:space:]]*$//g' -e '/^$/d' )
			
			# echo "$weather_data";exit 
			weather_array_value=$( gawk -v siteElevation="$site_elevation" '
			function clean(data) {
				returnData=""
				# some lines might be empty, so ignore those
				if (data !~ /^<[^>]+>$/ ) {
					returnData=gensub(/(.*>)([^<]*)(<.*)/, "\\2", 1, data)
					gsub(/^[[:space:]]+|[[:space:]]+$|^NA$|^N\/A$/, "", returnData)
				}
				return returnData
			}
			BEGIN {
				IGNORECASE=1
				observationTime=""
				localTime=""
				weather=""
				tempString=""
				humidity=""
				windString=""
				pressureString=""
				dewpointString=""
				heatIndexString=""
				windChillString=""
				weatherString=""
			}
			/observation_time>/ {
				observationTime=clean($0)
				sub(/Last Updated on /, "", observationTime )
			}
			/local_time>/ {
				localTime=clean($0)
			}
			/<weather/ {
				weather=clean($0)
			}
			/temperature_string/ {
				tempString=clean($0)
			}
			/relative_humidity/ {
				humidity=clean($0)
			}
			/wind_string/ {
				windString=clean($0)
			}
			/pressure_string/ {
				pressureString=clean($0)
			}
			/heat_index_string/ {
				heatIndexString=clean($0)
			}
			/windchill_string/ {
				windChillString=clean($0)
			}
			END {
				weatherString = observationTime ";" localTime ";" weather ";" tempString ";" humidity 
				weatherString = weatherString ";" windString ";" pressureString ";" dewpointString ";" heatIndexString
				weatherString = weatherString ";" windChillString ";" siteElevation
				print weatherString
			}' <<< "$weather_data" )
		fi
		if [[ -z $weather_array_value ]];then
			data_grab_error="Error: weather info downloaded but no data detected."
		else
			A_WEATHER_DATA[1]=$weather_array_value
		fi
	fi
	# now either dump process or go on to get weather data
	if [[ -n $data_grab_error ]];then
		A_WEATHER_DATA=$data_grab_error
		log_function_data "data grab error: $data_grab_error"
	fi
	
	if [[ $b_debug == 'true' ]];then
		echo "site_elevation: $site_elevation"
		echo "${A_WEATHER_DATA[1]}"
	fi
	a_temp=${A_WEATHER_DATA[@]}
	log_function_data "A_WEATHER_DATA: $a_temp"
	
	eval $LOGFE
}
# ALTERNATE_WEATHER_LOCATION='portland,or'
# get_weather_data;exit

#### -------------------------------------------------------------------
#### special data handling for specific options and conditions
#### -------------------------------------------------------------------

# args: $1 - string to strip color code characters out of
# returns count of string length minus colors
# note; this cleanup may not be working on bsd sed
calculate_line_length()
{
	local string=$1
	# ansi: [1;34m irc: \x0312
	# note: using special trick for bsd sed, tr - NOTE irc sed must use " double quote
	string=$( sed -e 's/'$ESC'\[[0-9]\{1,2\}\(;[0-9]\{1,2\}\)\{0,2\}m//g' -e "s/\\\x0[0-9]\{1,3\}//g" <<< $string )
	#echo $string
	LINE_LENGTH=${#string}
	# echo ${#string}
}

## multiply the core count by the data to be calculated, bmips, cache
# args: $1 - string to handle; $2 - cpu count
calculate_multicore_data()
{
	eval $LOGFS
	local string_number=$1 string_data=''

	if [[ -n $( grep -Ei '( mb| kb)' <<< $1 ) ]];then
		string_data=" $( gawk '{print $2}' <<< $1 )" # add a space for output
		string_number=$( gawk '{print $1}' <<< $1 )
	fi
	# handle weird error cases where it's not a number
	if [[ -n $( grep -E '^[0-9\.,]+$' <<< $string_number ) ]];then
		string_number=$( echo $string_number $2 | gawk '{
			total = $1*$2
			print total
		}' )
	elif [[ $string_number == '' ]];then
		string_number='N/A'
	else
		# I believe that the above returns 'unknown' by default so no need for extra text
		string_number="$string_number "
	fi
	echo "$string_number$string_data"
	log_function_data "string_numberstring_data: $string_number$string_data"
	eval $LOGFE
}

# prints out shortened list of flags, the main ones of interest
# args: $1 - string of cpu flags to process
process_cpu_flags()
{
	eval $LOGFS
	
	local cpu_flags_working=$1
	local bits=$( uname -m | grep 64 )
	
	# no need to show pae for 64 bit cpus, it's pointless
	if [[ -n $bits ]];then
		cpu_flags_working=$( sed 's/[[:space:]]*pae//' <<< "$cpu_flags_working" )
	fi
	# must have a space after last item in list for RS=" "
	cpu_flags_working="$cpu_flags_working "
	
	# nx = AMD stack protection extensions
	# lm = Intel 64bit extensions
	# sse, sse2, pni = sse1,2,3,4,5 gfx extensions
	# svm = AMD pacifica virtualization extensions
	# vmx = Intel IVT (vanderpool) virtualization extensions
	cpu_flags=$( gawk '
	BEGIN {
		RS=" "
		count = 0
		i = 1 # start at one because of for increment issue
		flag_string = ""
	}
	
	/^(lm|nx|pae|pni|svm|vmx|(sss|ss)e([2-9])?([a-z])?(_[0-9])?)$/ {
		if ( $0 == "pni" ){
			a_flags[i] = "sse3"
		}
		else {
			a_flags[i] = $0
		}
		i++
	}
	END {
		count = asort( a_flags )
		# note: why does gawk increment before the loop and not after? weird.
		for ( i=0; i <= count; i++ ){
			if ( flag_string == "" ) {
				flag_string = a_flags[i] 
			}
			else {
				flag_string = flag_string " " a_flags[i]
			}
		}
		print flag_string
	}' <<< "$cpu_flags_working" )

	#grep -oE '\<(nx|lm|sse[0-9]?|pni|svm|vmx)\>' | tr '\n' ' '))
	if [[ -z $cpu_flags ]];then
		cpu_flags="-"
	fi
	echo "$cpu_flags"
	log_function_data "cpu_flags: $cpu_flags"
	eval $LOGFE
}

#### -------------------------------------------------------------------
#### print and processing of output data
#### -------------------------------------------------------------------

#### MASTER PRINT FUNCTION - triggers all line item print functions
## main function to print out, master for all sub print functions.
print_it_out()
{
	eval $LOGFS
	# note that print_it_out passes local variable values on to its children,
	# and in some cases, their children, if variable syntax: Xxxx_Yyyy
	
	if [[ -n $BSD_TYPE ]];then
		get_sysctl_data 'a' # set: SYSCTL_A_DATA
		get_dmesg_boot_data # set: DMESG_BOOT_DATA
	fi
	if [[ $B_SHOW_SHORT_OUTPUT == 'true' ]];then
		print_short_data
	else
		get_lspci_data 'v' # set: LSPCI_V_DATA
		if [[ $B_EXTRA_EXTRA_DATA == 'true' ]];then
			get_lspci_data 'n' # set: LSPCI_N_DATA
		fi
		if [[ $B_SHOW_SYSTEM == 'true' ]];then
			print_system_data
		fi
		if [[ $B_SHOW_MACHINE == 'true' ]];then
			print_machine_data
		fi
		if [[ $B_SHOW_BATTERY == 'true' ]];then
			print_battery_data
		fi
		if [[ $B_SHOW_BASIC_CPU == 'true' || $B_SHOW_CPU == 'true' ]];then
			print_cpu_data
		fi
		if [[ $B_SHOW_MEMORY == 'true' ]];then
			print_ram_data
		fi
		if [[ $B_SHOW_GRAPHICS == 'true' ]];then
			print_graphics_data
		fi
		if [[ $B_SHOW_AUDIO == 'true' ]];then
			print_audio_data
		fi
		if [[ $B_SHOW_NETWORK == 'true' ]];then
			print_networking_data
		fi
		if [[ $B_SHOW_DISK_TOTAL == 'true' || $B_SHOW_BASIC_DISK == 'true' || $B_SHOW_DISK == 'true' ]];then
			print_hard_disk_data
		fi
		if [[ $B_SHOW_PARTITIONS == 'true' ]];then
			print_partition_data
		fi
		if [[ $B_SHOW_RAID == 'true' || $B_SHOW_BASIC_RAID == 'true' ]];then
			print_raid_data
		fi
		if [[ $B_SHOW_UNMOUNTED_PARTITIONS == 'true' ]];then
			print_unmounted_partition_data
		fi
		if [[ $B_SHOW_SENSORS == 'true' ]];then
			print_sensors_data
		fi
		if [[ $B_SHOW_REPOS == 'true' ]];then
			print_repo_data
		fi
		if [[ $B_SHOW_PS_CPU_DATA == 'true' || $B_SHOW_PS_MEM_DATA == 'true' ]];then
			print_ps_data
		fi
		if [[ $B_SHOW_WEATHER == 'true' ]];then
			print_weather_data
		fi
		if [[ $B_SHOW_INFO == 'true' ]];then
			print_info_data
		fi
	fi
	## last steps, clear any lingering colors
	if [[ $B_IRC == 'false' && $SCHEME -gt 0 ]];then
		echo -n "[0m"
	fi
	
	eval $LOGFE
}

#### SHORT OUTPUT PRINT FUNCTION, ie, verbosity 0
# all the get data stuff is loaded here to keep execution time down for single line print commands
# these will also be loaded in each relevant print function for long output
print_short_data()
{
	eval $LOGFS
	local processes=$(( $( wc -l <<< "$Ps_aux_Data" ) - 1 ))
	local short_data='' i='' b_background_black='false'
	if [[ -z $UP_TIME ]];then
		UP_TIME='N/A - missing uptime?'
	fi
	get_uptime
	get_kernel_version
	get_memory_data
	get_patch_version_string
	# load A_CPU_DATA
	get_cpu_data
	# load A_HDD_DATA
	get_hdd_data_basic
	# set A_CPU_CORE_DATA
	get_cpu_core_count
	local cpc_plural='' cpu_count_print='' model_plural='' current_max_clock=''
	local cpu_physical_count=${A_CPU_CORE_DATA[0]}
	local cpu_core_count=${A_CPU_CORE_DATA[3]}
	local cpu_core_alpha=${A_CPU_CORE_DATA[1]}
	local cpu_type=${A_CPU_CORE_DATA[2]}
	local kernel_os='' speed_starter='speed'
	local cpu_data_string=''
	
	if [[ -z $BSD_TYPE || -n $cpu_type ]];then
		cpu_type=" ($cpu_type)"
	fi
	if [[ $BSD_TYPE == 'bsd' ]];then
		kernel_os="${C1}OS${C2}$SEP1$( uname -rsp )" 
	else
		kernel_os="${C1}Kernel${C2}$SEP1$CURRENT_KERNEL"
	fi
	if [[ $cpu_physical_count -gt 1 ]];then
		cpc_plural='(s)'
		model_plural='s'
		cpu_count_print="$cpu_physical_count "
		# for multicpu systems, divide total cores by cpu count to get per cpu cores
		$cpu_core_count=$(($cpu_core_count/$cpu_physical_count))
	fi
	if [[ -z $BSD_TYPE ]];then
		cpu_data_string="$cpu_count_print$cpu_core_alpha core"
	else
		cpu_data_string="$cpu_count_print$cpu_core_count core"
	fi
# 	local cpu_core_count=${A_CPU_CORE_DATA[0]}
	
	## note: if hdd_model is declared prior to use, whatever string you want inserted will
	## be inserted first. In this case, it's desirable to print out (x) before each disk found.
	local a_hdd_data_count=$(( ${#A_HDD_DATA[@]} - 1 ))
	IFS=","
	local a_hdd_basic_working=( ${A_HDD_DATA[$a_hdd_data_count]} )
	IFS="$ORIGINAL_IFS"
	local hdd_capacity=${a_hdd_basic_working[0]}
	local hdd_used=${a_hdd_basic_working[1]}
	
	IFS=","
	local a_cpu_working=(${A_CPU_DATA[0]})
	# this gets that weird min/max final array item, which almost never contains any data of use
	local current_max_clock_nu=$(( ${#A_CPU_DATA[@]} - 1 ))
	local a_cpu_info=(${A_CPU_DATA[$current_max_clock_nu]})
	IFS="$ORIGINAL_IFS"
	local cpu_model="${a_cpu_working[0]}"
	## assemble data for output
	local cpu_clock="${a_cpu_working[1]}" # old CPU3
	# echo $cpu_clock
	# if [[ -z ${a_cpu_working[1]} || ${a_cpu_working[1]} < 50 ]];then
	#	a_cpu_working[1]=$(get_cpu_speed_hack)
	# fi
	
	# this handles the case of for example ARM cpus, which will not have data for
	# min/max, since they don't have speed. Since that sets a flag, not found, just
	# look for that and use the speed from the first array array, same where we got 
	# model from
	# index: 0 speed ; 1 min ; 2 max
	# this handles bsd types which always should show N/A unless we get a way to get min / max data
	if [[ "${a_cpu_info[0]}" == 'N/A' && ${a_cpu_working[1]} != '' ]];then
		current_max_clock="${a_cpu_working[1]} MHz"
	else
		if [[ ${a_cpu_info[2]} != 0 ]];then
			if [[ ${a_cpu_info[0]} == ${a_cpu_info[2]} ]];then
				current_max_clock="${a_cpu_info[0]} MHz (max)"
			else
				current_max_clock="${a_cpu_info[0]}/${a_cpu_info[2]} MHz"
				speed_starter='speed/max'
			fi
		fi
	fi
	
	#set_color_scheme 12
	if [[ $B_IRC == 'true' ]];then
		for i in $C1 $C2 $CN
		do
			case "$i" in
				"$GREEN"|"$WHITE"|"$YELLOW"|"$CYAN")
					b_background_black='true'
					;;
			esac
		done
		if [[ $b_background_black == 'true' ]];then
			for i in C1 C2 CN
			do
				## these need to be in quotes, don't know why
				if [[ ${!i} == $NORMAL ]];then
					declare $i="${!i}15,1"
				else
					declare $i="${!i},1"
				fi
			done
			#C1="${C1},1"; C2="${C2},1"; CN="${CN},1"
		fi
	fi
	short_data="${C1}CPU$cpc_plural${C2}$SEP1$cpu_data_string $cpu_model$model_plural$cpu_type ${C1}$speed_starter${C2}$SEP1$current_max_clock$SEP2$kernel_os$SEP2${C1}Up${C2}$SEP1$UP_TIME$SEP2${C1}Mem${C2}$SEP1$MEMORY$SEP2${C1}HDD${C2}$SEP1$hdd_capacity($hdd_used)$SEP2${C1}Procs${C2}$SEP1$processes$SEP2"

	if [[ $SHOW_IRC -gt 0 ]];then
		short_data="$short_data${C1}Client${C2}$SEP1$IRC_CLIENT$IRC_CLIENT_VERSION$SEP2"
	fi
	short_data="$short_data${C1}$SELF_NAME${C2}$SEP1$SELF_VERSION$SELF_PATCH$SEP2${CN}"
	if [[ $SCHEME -gt 0 ]];then
		short_data="$short_data $NORMAL"
	fi
	print_screen_output "$short_data"
	eval $LOGFE
}

#### LINE ITEM PRINT FUNCTIONS

# print sound card data
print_audio_data()
{
	eval $LOGFS
	local i='' card_id='' audio_data='' a_audio_data='' port_data='' pci_bus_id='' card_string=''
	local a_audio_working='' audio_driver='' alsa_data='' port_plural='' module_version='' chip_id=''
	local bus_usb_text='' bus_usb_id='' line_starter='Audio:' alsa='' alsa_version='' print_data=''
	local driver=''
	# set A_AUDIO_DATA and get alsa data
	if [[ $BSD_TYPE == 'bsd' ]];then
		if [[ $B_PCICONF == 'true' ]];then
			if [[ $B_PCICONF_SET == 'false' ]];then
				get_pciconf_data
			fi
			get_pciconf_card_data 'audio'
		elif [[ $B_LSPCI == 'true' ]];then
			get_audio_data
		fi
	else
		get_audio_data
	fi
	
	get_audio_alsa_data
	# alsa driver data now prints out no matter what
	if [[ -n $A_ALSA_DATA ]];then
		IFS=","
		if [[ -n ${A_ALSA_DATA[0]} ]];then
			alsa=${A_ALSA_DATA[0]}
		else
			alsa='N/A'
		fi
		if [[ -n ${A_ALSA_DATA[1]} ]];then
			alsa_version=${A_ALSA_DATA[1]}
		else
			alsa_version='N/A'
		fi
		alsa_data="${C1}Sound$SEP3${C2} $alsa ${C1}v$SEP3${C2} $alsa_version"
		IFS="$ORIGINAL_IFS"
	fi
	# note, error handling is done in the get function, so this will never be null, but
	# leaving the test just in case it's changed.
	if [[ -n ${A_AUDIO_DATA[@]} ]];then
		for (( i=0; i< ${#A_AUDIO_DATA[@]}; i++ ))
		do
			IFS=","
			a_audio_working=( ${A_AUDIO_DATA[i]} )
			IFS="$ORIGINAL_IFS"
			port_data=''
			audio_driver=''
			audio_data=''
			card_string=''
			port_plural=''
			module_version=''
			pci_bus_id=''
			bus_usb_text=''
			bus_usb_id=''
			print_data=''
			chip_id=''
			
			if [[ ${#A_AUDIO_DATA[@]} -gt 1 ]];then
				card_id="-$(( $i + 1 ))"
			fi
			if [[ $BSD_TYPE != 'bsd' ]];then
				if [[ -n ${a_audio_working[3]} && $B_EXTRA_DATA == 'true' ]];then
					module_version=$( print_module_version "${a_audio_working[3]}" 'audio' )
				elif [[ -n ${a_audio_working[1]} && $B_EXTRA_DATA == 'true' ]];then
					module_version=$( print_module_version "${a_audio_working[1]}" 'audio' )
				fi
			fi
			# we're testing for the presence of the 2nd array item here, which is the driver name
			if [[ -n ${a_audio_working[1]} ]];then
				# note: linux drivers can have numbers, like tg3
				if [[ $BSD_TYPE == 'bsd' ]];then
					driver=$( sed 's/[0-9]$//' <<< ${a_audio_working[1]} )
				else
					driver=${a_audio_working[1]}
				fi
				audio_driver="${C1}driver$SEP3${C2} $driver "
			fi
			if [[ -n ${a_audio_working[2]} && $B_EXTRA_DATA == 'true' ]];then
				if [[ $( wc -w <<< ${a_audio_working[2]} ) -gt 1 ]];then
					port_plural='s'
				fi
				port_data="${C1}port$port_plural$SEP3${C2} ${a_audio_working[2]} "
			fi
			if [[ -n ${a_audio_working[4]} && $B_EXTRA_DATA == 'true' ]];then
				if [[ ${a_audio_working[1]} != 'USB Audio' ]];then
					bus_usb_text='bus-ID'
					if [[ $B_EXTRA_EXTRA_DATA == 'true' ]];then
						if [[ $BSD_TYPE != 'bsd' ]];then
							chip_id=$( get_lspci_chip_id "${a_audio_working[4]}" )
						else
							chip_id=${a_audio_working[6]}
						fi
					fi
				else
					bus_usb_text='usb-ID'
					if [[ $B_EXTRA_EXTRA_DATA == 'true' ]];then
						chip_id=${a_audio_working[5]}
					fi
				fi
				bus_usb_id=${a_audio_working[4]}
				pci_bus_id="${C1}$bus_usb_text$SEP3${C2} $bus_usb_id "
				if [[ -n $chip_id ]];then
					chip_id="${C1}chip-ID$SEP3${C2} $chip_id "
				fi
			fi
			if [[ -n ${a_audio_working[0]} ]];then
				card_string="${C1}Card$card_id$EP3${C2} ${a_audio_working[0]} "
				audio_data="$audio_driver$port_data$pci_bus_id$chip_id"
			fi
			# only print alsa on last line if short enough, otherwise print on its own line
			if [[ $i -eq 0 ]];then
				calculate_line_length "$card_string$audio_data$alsa_data"
				if [[ -n $alsa_data && $LINE_LENGTH -lt $COLS_INNER ]];then
					audio_data="$audio_data$alsa_data"
					alsa_data=''
				fi
			fi
			if [[ -n $audio_data ]];then
				calculate_line_length "$card_string$audio_data"
				if [[ $LINE_LENGTH -lt $COLS_INNER ]];then
					print_data=$( create_print_line "$line_starter" "$card_string$audio_data" )
					print_screen_output "$print_data"
				# print the line
				else
					# keep the driver on the same line no matter what, looks weird alone on its own line
					if [[ $LINE_LENGTH -gt $COLS_INNER ]];then
						print_data=$( create_print_line "$line_starter" "$card_string" )
						print_screen_output "$print_data"
						line_starter=' '
						print_data=$( create_print_line "$line_starter" "$audio_data" )
						print_screen_output "$print_data"
					else
						print_data=$( create_print_line "$line_starter" "$card_string$audio_data" )
						print_screen_output "$print_data"
					fi
				fi
				line_starter=' '
			fi
		done
	fi
	if [[ -n $alsa_data ]];then
		calculate_line_length "${alsa_data/ALSA/Advanced Linux Sound Architecture}"
		if [[ $LINE_LENGTH -lt $COLS_INNER ]];then
			# alsa_data=$( sed 's/ALSA/Advanced Linux Sound Architecture/' <<< $alsa_data )
			alsa_data=${alsa_data/ALSA/Advanced Linux Sound Architecture}
		fi
		alsa_data=$( create_print_line "$line_starter" "$alsa_data" )
		print_screen_output "$alsa_data"
	fi
	eval $LOGFE
}

print_battery_data()
{
	eval $LOGFS
	local line_starter='Battery' print_data='' 
	get_battery_data
	if [[ -n ${A_BATTERY_DATA[@]} ]];then
		local battery_data='' battery_string=''
		local present='' chemistry='' cycles='' voltage_min_design='' voltage_now=''
		local power_now='' capacity='' capacity_level='' model='' company='' serial='' 
		local of_orig='' model='' condition='' power=''
		
		# echo ${A_BATTERY_DATA[@]}
		for (( i=0; i< ${#A_BATTERY_DATA[@]}; i++ ))
		do
			battery_data='' 
			print_data=''
			battery_string=''
			charge=''
			model=''
			condition=''
			voltage=''
			name=''
			status=''
			present=''
			chemistry=''
			cycles=''
			voltage_min_design=''
			voltage_now=''
			power_now=''
			capacity=''
			capacity_level=''
			of_orig=''
			model=''
			company=''
			serial=''
			location='' # dmidecode only
			IFS=","
			a_battery_working=( ${A_BATTERY_DATA[i]} )
			IFS="$ORIGINAL_IFS"
			bat_id="$(( $i + 1 ))"
			
			if [[ -n ${a_battery_working[10]} ]];then
				charge="${a_battery_working[10]} Wh "
			fi
			if [[ -n ${a_battery_working[11]} ]];then
				charge="$charge${a_battery_working[11]} "
			fi
			if [[ $charge == '' ]];then
				charge='N/A '
			fi
			charge="${C1}charge$SEP3${C2} $charge"
			if [[ -n ${a_battery_working[9]} ]];then
				condition="${a_battery_working[9]}"
			else
				condition='NA'
			fi
			if [[ -n ${a_battery_working[8]} ]];then
				condition="$condition/${a_battery_working[8]} Wh "
			else
				condition="$condition/NA Wh "
			fi
			if [[ -n ${a_battery_working[13]} ]];then
				condition="$condition(${a_battery_working[13]}) "
			fi
			if [[ $condition == '' ]];then
				condition='N/A '
			fi
			condition="${C1}condition$SEP3${C2} $condition"
			if [[ $B_EXTRA_DATA == 'true' ]];then
				if [[ -n ${a_battery_working[15]} ]];then
					model="${a_battery_working[15]} "
				fi
				if [[ -n ${a_battery_working[14]} ]];then
					model="$model${a_battery_working[14]} "
				fi
				if [[ $model == '' ]];then
					model='N/A '
				fi
				model="${C1}model$SEP3${C2} $model"
			
				if [[ -n ${a_battery_working[1]} ]];then
					status="${a_battery_working[1]} "
				else
					status="N/A "
				fi
				status="${C1}status$SEP3${C2} $status"
			fi
			if [[ $B_EXTRA_EXTRA_DATA == 'true' ]];then
				if [[ -n ${a_battery_working[16]} ]];then
					if [[ $B_OUTPUT_FILTER == 'true' ]];then
						serial=$FILTER_STRING
					else
						serial="${a_battery_working[16]} "
					fi
				else 
					serial='N/A '
				fi
				serial="${C1}serial$SEP3${C2} $serial"
				if [[ -n ${a_battery_working[6]} ]];then
					voltage="${a_battery_working[6]}"
				fi
				if [[ -n ${a_battery_working[5]} ]];then
					if [[ $voltage == '' ]];then
						voltage='NA'
					fi
					voltage="$voltage/${a_battery_working[5]} "
				fi
				if [[ $voltage == '' ]];then
					voltage='NA '
				fi
				voltage="${C1}volts$SEP3${C2} $voltage"
			fi
			if [[ $B_EXTRA_EXTRA_EXTRA_DATA == 'true' ]];then
				if [[ -n ${a_battery_working[3]} ]];then
					chemistry="${a_battery_working[3]} "
				fi
				if [[ -n ${a_battery_working[4]} ]];then
					cycles="${C1}cycles$SEP3${C2} ${a_battery_working[4]} "
				fi
				# location is dmidecode only
				if [[ -n ${a_battery_working[17]} ]];then
					location="${C1}loc$SEP3${C2} ${a_battery_working[17]} "
				fi
			fi
			if [[ -n ${a_battery_working[15]} ]];then
				battery_string="${C1}${a_battery_working[0]}$SEP3${C2} $charge$condition"
				battery_data="$model$chemistry$serial$status$cycles$location"
			fi
			
			if [[ ${A_BATTERY_DATA[0]} == 'dmidecode-error-'* ]];then
				error_string=$( print_dmidecode_error 'bat' "${A_BATTERY_DATA[0]}" )
				battery_string=${C2}$error_string
				battery_data=''
				voltage=''
			fi
			
			if [[ -n $battery_string ]];then
				calculate_line_length "$battery_string$voltage$battery_data"
				if [[ $LINE_LENGTH -lt $COLS_INNER ]];then
					#echo one
					print_data=$( create_print_line "$line_starter" "$battery_string$voltage$battery_data" )
					print_screen_output "$print_data"
				# print the line
				else
					# keep the driver on the same line no matter what, looks weird alone on its own line
					if [[ $LINE_LENGTH -gt $COLS_INNER ]];then
						calculate_line_length "$battery_string$voltage"
						if [[ $LINE_LENGTH -gt $COLS_INNER ]];then
							print_data=$( create_print_line "$line_starter" "$battery_string" )
							print_screen_output "$print_data"
							line_starter=' '
							battery_string=''
							print_data=$( create_print_line "$line_starter" "$voltage" )
							print_screen_output "$print_data"
							voltage=''
						else 
							print_data=$( create_print_line "$line_starter" "$battery_string$voltage" )
							print_screen_output "$print_data"
							line_starter=' '
							voltage=''
							battery_string=''
						fi
						#echo two
						if [[ $battery_data != '' ]];then
							print_data=$( create_print_line "$line_starter" "$battery_data" )
							print_screen_output "$print_data"
						fi
					else
						#echo three
						print_data=$( create_print_line "$line_starter" "$battery_string$voltage$battery_data" )
						print_screen_output "$print_data"
					fi
				fi
				line_starter=' '
			fi
		done
	elif [[ $B_SHOW_BATTERY_FORCED == 'true' ]];then
		print_data=$( create_print_line "$line_starter" "No battery data found in /sys or dmidecode. Is one present?" )
		print_screen_output "$print_data"
	fi
	eval $LOGFE
}

print_cpu_data()
{
	eval $LOGFS
	local cpu_data='' i='' cpu_clock_speed='' cpu_multi_clock_data='' a_cpu_info=''
	local bmip_data='' cpu_cache='' cpu_vendor='' cpu_flags='' flag_feature='flags'
	local a_cpu_working='' cpu_model='' cpu_clock='' cpu_null_error='' max_speed=''
	local cpc_plural='' cpu_count_print='' model_plural='' cpu_data_string=''
	local cpu_physical_count='' cpu_core_count='' cpu_core_alpha='' cpu_type=''
	local cpu_2_data='' working_cpu='' temp1='' per_cpu_cores='' current_max_clock_nu=''
	local line_starter="CPU:" multi_cpu_starter="${C1}clock speeds$SEP3${C2} "
	local speed_starter='speed' arch_data='' arm=' (ARM)' rev='' arch_cache='' cache_data=''
	local flags_bmip=''

	##print_screen_output "A_CPU_DATA[0]=\"${A_CPU_DATA[0]}\""
	# Array A_CPU_DATA always has one extra element: max clockfreq found.
	# that's why its count is one more than you'd think from cores/cpus alone
	# load A_CPU_DATA
	get_cpu_data

	IFS=","
	a_cpu_working=(${A_CPU_DATA[0]})
	current_max_clock_nu=$(( ${#A_CPU_DATA[@]} - 1 ))
	a_cpu_info=(${A_CPU_DATA[$current_max_clock_nu]})
	IFS="$ORIGINAL_IFS"
	
	if [[ $B_EXTRA_DATA == 'true' ]];then
		if [[ ${a_cpu_info[3]} != '' ]];then
			get_cpu_architecture "${a_cpu_info[3]}" "${a_cpu_info[4]}" "${a_cpu_info[5]}"
			# note: arm model names usually say what revision it is
			if [[ ${a_cpu_info[3]} != 'arm' && "${a_cpu_info[6]}" != '' ]];then
				if [[ -n "${ARCH/*rev*/}" ]];then
					rev=" rev.${a_cpu_info[6]}"
				fi
			fi
		fi
		if [[ $ARCH == '' ]];then
			ARCH='N/A'
		else
			arm='' # note: to avoid redundant output, only show this without -x option
		fi
		arch_data="${C1}arch$SEP3${C2} $ARCH$rev "
	fi
	# Strange (and also some expected) behavior encountered. If print_screen_output() uses $1
	# as the parameter to output to the screen, then passing "<text1> ${ARR[@]} <text2>"
	# will output only <text1> and first element of ARR. That "@" splits in elements and "*" _doesn't_,
	# is to be expected. However, that text2 is consecutively truncated is somewhat strange, so take note.
	# This has been confirmed by #bash on freenode.
	# The above mentioned only emerges when using the debugging markers below
	## print_screen_output "a_cpu_working=\"***${a_cpu_working[@]} $hostName+++++++\"----------"
	# unless all these are null, process whatever you have
	if [[ -n ${a_cpu_working[0]} || -n ${a_cpu_working[1]} || -n ${a_cpu_working[2]} || -n ${a_cpu_working[3]} ]];then
		cpu_model="${a_cpu_working[0]}";
		## assemble data for output
		cpu_clock="${a_cpu_working[1]}"
		cpu_vendor=${a_cpu_working[5]}
		# set A_CPU_CORE_DATA
		get_cpu_core_count
		cpu_physical_count=${A_CPU_CORE_DATA[0]}
		cpu_core_count=${A_CPU_CORE_DATA[3]}
		cpu_core_alpha=${A_CPU_CORE_DATA[1]}
		cpu_type=${A_CPU_CORE_DATA[2]}
		
		if [[ $cpu_physical_count -gt 1 ]];then
			cpc_plural='(s)'
			cpu_count_print="$cpu_physical_count "
			model_plural='s'
		fi
		line_starter="CPU$cpc_plural:"
		if [[ -z $BSD_TYPE ]];then
			cpu_data_string="$cpu_count_print$cpu_core_alpha core"
			cpu_data="${C1}$cpu_data_string${C2} $cpu_model$model_plural ($cpu_type) "
		else
			if [[ $cpu_physical_count -gt 1 ]];then
				per_cpu_cores=$(($cpu_core_count/$cpu_physical_count))
				cpu_data_string="${C1}Cores$SEP3${C2} $cpu_core_count ($cpu_physical_count $per_cpu_cores core cpus) "
			else
				cpu_data_string="${C1}Cores$SEP3${C2} $cpu_core_count "
			fi
			if [[ -n $cpu_type ]];then
				cpu_type=" ($cpu_type)"
			fi
			cpu_data="$cpu_data_string${C1}model$SEP3${C2} $cpu_model$cpu_type "
		fi
		if [[ $B_SHOW_CPU == 'true' ]];then
			# update for multicore, bogomips x core count.
			if [[ $B_EXTRA_DATA == 'true' ]];then
	# 			if [[ $cpu_vendor != 'intel' ]];then
				# ARM may use the faked 1 cpucorecount to make this work
				# echo $cpu_core_count $cpu_physical_count
				if [[ -n ${a_cpu_working[4]} ]];then
					# new arm shows bad bogomip value, so don't use it
					if [[ ${a_cpu_working[4]%.*} -gt 50 ]];then
						bmip_data=$( calculate_multicore_data "${a_cpu_working[4]}" "$(( $cpu_core_count * $cpu_physical_count ))" )
					fi
					bmip_data=${bmip_data%.*}
				fi
	# 			else
	# 				bmip_data="${a_cpu_working[4]}"
	# 			fi
				# bogomips are a linux thing, but my guess is over time bsds will use them somewhere anyway
				if [[ -n $BSD_TYPE && -z $bmip_data ]];then
					bmip_data=''
				else
					bmip_data="${C1}bmips$SEP3${C2} $bmip_data "
				fi
				
			fi
			## note: this handles how intel reports L2, total instead of per core like AMD does
			# note that we need to multiply by number of actual cpus here to get true cache size
			if [[ -n ${a_cpu_working[2]} ]];then
				if [[ -z $BSD_TYPE ]];then
					# AMD SOS chips appear to report full L2 cache per core
					if [[ "${a_cpu_info[3]}" == 'amd' ]] && [[ "${a_cpu_info[4]}" == '14' || "${a_cpu_info[4]}" == '16' ]];then
						cpu_cache=$( calculate_multicore_data "${a_cpu_working[2]}" "$cpu_physical_count"  )
					elif [[ $cpu_vendor != 'intel' ]];then
						cpu_cache=$( calculate_multicore_data "${a_cpu_working[2]}" "$(( $cpu_core_count * $cpu_physical_count ))"  )
					else
						cpu_cache=$( calculate_multicore_data "${a_cpu_working[2]}" "$cpu_physical_count"  )
					fi
				else
					cpu_cache=${a_cpu_working[2]}
				fi
			else
				cpu_cache='N/A'
			fi
			# only print shortened list
			if [[ $B_CPU_FLAGS_FULL != 'true' ]];then
				# gawk has already sorted this output, no flags returns -
				if [[ $B_EXTRA_DATA == 'true' ]];then
					cpu_flags=$( process_cpu_flags "${a_cpu_working[3]}" "${a_cpu_working[6]}" )
					cpu_flags="($cpu_flags)"
					if [[ ${a_cpu_working[6]} == 'true' ]];then
						flag_feature='features'
					fi
					cpu_flags="${C1}$flag_feature$SEP3${C2} $cpu_flags "
				fi
			fi
			# arm cpus do not have flags or cache
			if [[ ${a_cpu_working[6]} != 'true' ]];then
				cpu_data="$cpu_data${C2}"
				cache_data="${C1}cache$SEP3${C2} $cpu_cache "
				flags_bmip="$cpu_flags$bmip_data"
			else
				cpu_data="$cpu_data${C2}$arm $bmip_data"
			fi
		fi
		# we don't this printing out extra line unless > 1 cpu core
		if [[ ${#A_CPU_DATA[@]} -gt 2 && $B_SHOW_CPU == 'true' ]];then
			cpu_clock_speed='' # null < verbosity level 5
		else
			if [[ -z ${a_cpu_working[1]} ]];then
				if [[ -z ${cpu_data/*ARM*/} ]];then
					temp1="$arm"
				fi
				a_cpu_working[1]="N/A$temp1"
			else
				a_cpu_working[1]="${a_cpu_working[1]%.*} MHz"
			fi
			# this handles bsd case unless we get a way to get max/min cpu speeds
			if [[ ${a_cpu_info[0]} != 'N/A' && ${a_cpu_info[2]} != 0 ]];then
				if [[ $B_EXTRA_EXTRA_DATA == 'true' && ${#A_CPU_DATA[@]} -eq 2 && 
				      $B_SHOW_CPU == 'true' && ${a_cpu_info[1]} != 0 ]];then
					a_cpu_working[1]="${a_cpu_info[0]}/${a_cpu_info[1]}/${a_cpu_info[2]} MHz"
					speed_starter='speed/min/max'
				else
					if [[ ${a_cpu_info[0]} == ${a_cpu_info[2]} ]];then
						a_cpu_working[1]="${a_cpu_info[0]} MHz (max)"
					else
						a_cpu_working[1]="${a_cpu_info[0]}/${a_cpu_info[2]} MHz"
						speed_starter='speed/max'
					fi
				fi
			fi
			cpu_clock_speed="${C1}$speed_starter$SEP3${C2} ${a_cpu_working[1]}"
		fi
		if [[ $B_CPU_FLAGS_FULL == 'true' ]];then
			cpu_2_data=""
			arch_cache="$arch_data$cache_data$bmip_data"
		else
			cpu_2_data="$flags_bmip$cpu_clock_speed"
			arch_cache="$arch_data$cache_data"
		fi
	else
		if [[ $BSD_TYPE == 'bsd' && $B_ROOT != 'true' ]];then
			cpu_null_error=' No permissions for sysctl use?'
		fi
		cpu_data="${C2}No CPU data available.$cpu_null_error"
	fi
# 	echo $cpu_data $cpu_2_data
# 	echo ln: $( calculate_line_length "$cpu_data $cpu_2_data" )
# 	echo cpl: $( create_print_line "$line_starter" "$cpu_2_data" ):
# 	echo icols: $COLS_INNER
# 	echo tc: $TERM_COLUMNS
	# echo :${cpu_2_data}:
	calculate_line_length "$cpu_data $arch_cache"
	if [[ $LINE_LENGTH -gt $COLS_INNER ]];then
		#echo one
		cpu_data=$( create_print_line "$line_starter" "$cpu_data" )
		print_screen_output "$cpu_data"
		cpu_data=$( create_print_line " " "$arch_cache" )
		print_screen_output "$cpu_data"
		line_starter=' '
		cpu_data=''
		arch_cache=''
	fi
	calculate_line_length "$cpu_data$arch_cache$cpu_2_data"
	if [[ -n $cpu_2_data && $LINE_LENGTH -gt $COLS_INNER ]];then
		#echo two
		calculate_line_length "$cpu_data$arch_cache"
		if [[ $LINE_LENGTH -gt $COLS_INNER ]];then
			cpu_data=$( create_print_line "$line_starter" "$cpu_data" )
			print_screen_output "$cpu_data"
		else
			cpu_data=$( create_print_line "$line_starter" "$cpu_data$arch_cache" )
			print_screen_output "$cpu_data"
			arch_cache=''
		fi
		line_starter=' '
		cpu_data=$( create_print_line " " "$arch_cache$cpu_2_data" )
		print_screen_output "$cpu_data"
	else
		#echo three
		if [[ -n "$cpu_data$arch_cache$cpu_2_data" ]];then
			cpu_data=$( create_print_line "$line_starter" "$cpu_data$arch_cache$cpu_2_data" )
			print_screen_output "$cpu_data"
		fi
	fi
	# we don't do this printing out extra line unless > 1 cpu core
	# note the numbering, the last array item is the min/max/not found for cpu speeds
	if [[ ${#A_CPU_DATA[@]} -gt 2 && $B_SHOW_CPU == 'true' ]];then
		if [[ ${a_cpu_info[2]} != 0 ]];then
			if [[ $B_EXTRA_EXTRA_DATA == 'true' && ${a_cpu_info[1]} != 0 ]];then
				max_speed="${C1}min/max$SEP3${C2} ${a_cpu_info[1]}/${a_cpu_info[2]} MHz "
			else
				max_speed="${C1}max$SEP3${C2} ${a_cpu_info[2]} MHz "
			fi
		fi
		for (( i=0; i < ${#A_CPU_DATA[@]}-1; i++ ))
		do
			IFS=","
			a_cpu_working=(${A_CPU_DATA[i]})
			IFS="$ORIGINAL_IFS"
			# note: the first iteration will create a first space, for color code separation below
			# someone actually appeared with a 16 core system, so going to stop the cpu core throttle
			# if this had some other purpose which we can't remember we'll add it back in
			#if [[ $i -gt 10 ]];then
			#	break
			#fi
			# echo $(calculate_line_length "$multi_cpu_starter$SEP3 $cpu_multi_clock_data" )
			working_cpu="$max_speed${C1}$(( i + 1 ))$SEP3${C2} ${a_cpu_working[1]%.*} MHz "
			max_speed=''
			calculate_line_length "$multi_cpu_starter$cpu_multi_clock_data$working_cpu"
			if [[ -n $cpu_multi_clock_data && $LINE_LENGTH -gt $COLS_INNER ]];then
				cpu_multi_clock_data=$( create_print_line " " "$multi_cpu_starter$cpu_multi_clock_data" )
				print_screen_output "$cpu_multi_clock_data"
				multi_cpu_starter=''
				cpu_multi_clock_data="$working_cpu"
			else
				cpu_multi_clock_data="$cpu_multi_clock_data$working_cpu"
			fi
		done
	fi
	# print the last line if it exists after loop
	if [[ -n $cpu_multi_clock_data ]];then
		cpu_multi_clock_data=$( create_print_line " " "$multi_cpu_starter$cpu_multi_clock_data" )
		print_screen_output "$cpu_multi_clock_data"
	fi
	if [[ $B_CPU_FLAGS_FULL == 'true' ]];then
		print_cpu_flags_full "${a_cpu_working[3]}" "${a_cpu_working[6]}"
	fi
	eval $LOGFE
}

# takes list of all flags, split them and prints x per line
# args: $1 - cpu flag string; $2 - arm true/false
print_cpu_flags_full()
{
	eval $LOGFS
	# note: sort only sorts lines, not words in a string, so convert to lines
	local cpu_flags_full="$( echo $1 | tr " " "\n" | sort )" 
	local a_cpu_flags='' line_starter='' temp_string=''
	local i=0 counter=0 starter_length=0 flag='' flag_data=''
	local line_length='' flag_feature='Flags' spacer='' flag_string=''
	
	if [[ $2 == 'true' ]];then
		flag_feature='Features'
	fi
	line_starter="CPU $flag_feature$SEP3"
	starter_length=$(( ${#line_starter} + 1 ))
	line_starter="${C1}$line_starter${C2} "
	line_length=$(( $COLS_INNER - $starter_length ))
	# build the flag line array
	for flag in $cpu_flags_full
	do
		temp_string="$flag_string$spacer$flag"
		spacer=' '
		# handle inner line starter
		if [[ $counter -gt 0 ]];then
			line_length=$COLS_INNER
		fi
		if [[ $line_length -ge ${#temp_string} ]];then
			flag_string=$temp_string
		else
			a_cpu_flags[$counter]=$flag_string
			flag_string=$flag
			(( counter++ ))
		fi	
		temp_string=''
	done
	if [[ -n $flag_string ]];then
		a_cpu_flags[$counter]=$flag_string
	else
		a_cpu_flags[$counter]='No CPU flag data found.'
	fi
	# then print it out
	for (( i=0; i < ${#a_cpu_flags[@]};i++ ))
	do
		if [[ $i -gt 0 ]];then
			line_starter=''
		fi
		flag_data=$( create_print_line " " "$line_starter${a_cpu_flags[$i]}" )
		print_screen_output "$flag_data"
	done
	eval $LOGFE
}

# args: $1 - type [sys/bat/default]; $2 - get_dmidecode_data error return
print_dmidecode_error()
{
	eval $LOGFS
	local error_message='Unknown dmidecode error.'
	local sysDmiError='Using '
	
	if [[ $1 == 'sys' || $1 == 'bat' ]];then
		if [[ $B_FORCE_DMIDECODE == 'true' ]];then
			sysDmiError='Forcing '
		# dragonfly has /sys, but it's empty
		elif [[ $1 == 'sys' ]] && [[ $BSD_TYPE == '' || -d /sys/devices ]];then
			sysDmiError='No /sys/class/dmi; using '
		#elif [[ $1 == 'bat' ]] && [[ $BSD_TYPE == '' || -d /sys/devices ]];then
		#	sysDmiError='No /sys/ battery; using '
		else
			sysDmiError='Using '
		fi
	fi
	if [[ $2 == 'dmidecode-error-requires-root' ]];then
		error_message="${sysDmiError}dmidecode: root required for dmidecode"
	elif [[ $2 == 'dmidecode-error-not-installed' ]];then
		error_message="${sysDmiError}dmidecode: dmidecode is not installed."
	elif [[ $2 == 'dmidecode-error-no-smbios-dmi-data' ]];then
		error_message="${sysDmiError}dmidecode: no smbios data. Old system?"
	elif [[ $2 == 'dmidecode-error-no-battery-data' ]];then
		error_message="${sysDmiError}dmidecode: no battery data."
	elif [[ $2 == 'dmidecode-error-unknown-error' ]];then
		error_message="${sysDmiError}dmidecode: unknown error occurred"
	fi
	echo $error_message
	eval $LOGFE
}

print_graphics_data()
{
	eval $LOGFS
	local graphics_data='' card_id='' i='' root_alert='' root_x_string='' a_graphics_working=''
	local b_is_mesa='false' display_full_string='' card_bus_id='' card_data='' 
	local res_tty='Resolution' xorg_data='' display_server_string='' chip_id='' sep_pci=''
	local spacer='' driver='' driver_string='' driver_plural='' direct_render_string=''
	local sep_loaded='' sep_unloaded='' sep_failed='' b_pci_driver='false' res_string=''
	local loaded='' unloaded='' failed='' display_server_string='' b_force_tty='false'
	local line_starter='Graphics:' part_1_data='' part_2_data='' b_advanced='true'
	local screen_resolution="$( get_graphics_res_data 'reg' )"
	
	# set A_DISPLAY_SERVER_DATA
	get_graphics_display_server_data
	
	local display_vendor=${A_DISPLAY_SERVER_DATA[0]}
	local display_version=${A_DISPLAY_SERVER_DATA[1]}
	local display_server=${A_DISPLAY_SERVER_DATA[2]}
	local compositor=${A_DISPLAY_SERVER_DATA[3]} compositor_string=''
	
	# set A_GLX_DATA
	get_graphics_glx_data
	# oglr, oglv, dr, oglcpv, compatVersion
	local glx_renderer="${A_GLX_DATA[0]}"
	local glx_version="${A_GLX_DATA[1]}"
	# this can contain a long No case debugging message, so it's being sliced off
	# note: using grep -ioE '(No|Yes)' <<< ${A_GLX_DATA[2]} did not work in Arch, no idea why
	local direct_rendering=$( gawk '{print $1}' <<< "${A_GLX_DATA[2]}" )
	local glx_core_version="${A_GLX_DATA[3]}"
	local glx_compat_version_nu="${A_GLX_DATA[4]}"
	
	# set A_GRAPHICS_CARD_DATA
	if [[ $BSD_TYPE == 'bsd' ]];then
		if [[ $B_PCICONF == 'true' ]];then
			if [[ $B_PCICONF_SET == 'false' ]];then
				get_pciconf_data
			fi
			get_pciconf_card_data 'display'
		elif [[ $B_LSPCI == 'true' ]];then
			get_graphics_card_data
		fi
	else
		get_graphics_card_data
	fi
	# set A_GRAPHIC_DRIVERS
	get_graphics_driver
	
	if [[ ${#A_GRAPHIC_DRIVERS[@]} -eq 0 ]];then
		driver=''
		b_pci_driver='true'
	else
		for (( i=0; i < ${#A_GRAPHIC_DRIVERS[@]}; i++ ))
		do
			IFS=","
			a_graphics_working=( ${A_GRAPHIC_DRIVERS[i]} )
			IFS="$ORIGINAL_IFS"
			case ${a_graphics_working[1]} in
				loaded)
					loaded="$loaded$sep_loaded${a_graphics_working[0]}"
					sep_loaded=','
					;;
				unloaded)
					unloaded="$unloaded$sep_unloaded${a_graphics_working[0]}"
					sep_unloaded=','
					;;
				failed)
					failed="$failed$sep_failed${a_graphics_working[0]}"
					sep_failed=','
					;;		
			esac
		done
	fi
	if [[ -n $loaded ]];then
		driver="$driver $loaded"
	fi
	if [[ -n $unloaded ]];then
		driver="$driver (unloaded: $unloaded)"
	fi
	if [[ -n $failed ]];then
		driver="$driver ${RED}FAILED$SEP3${C2} $failed"
	fi
	# sometimes for some reason there is no driver found but the array is started
	if [[ -z $driver ]];then
		b_pci_driver='true'
	fi
	if [[ ${#A_GRAPHIC_DRIVERS[@]} -gt 1 ]];then
		driver_plural='s'
	fi
	# some basic error handling:
	if [[ -z $screen_resolution ]];then
		screen_resolution="$( get_graphics_res_data 'tty' )"
		if [[ -z $screen_resolution ]];then
			screen_resolution='N/A'
		else 
			b_force_tty='true'
		fi
	fi
	# note: fix this, we may find a display server that has no version
	if [[ -z "${display_vendor// }" || -z "${display_version// }" ]];then
		display_server_string="N/A "
	else
		# note: sometimes display vendor has leading whitespace
		display_server_string="${display_vendor##*[ ]} $display_version "
	fi
	if [[ $display_server != '' ]];then
		display_server_string="$display_server ($display_server_string) "
	fi
	
	if [[ $B_EXTRA_EXTRA_DATA == '' && $compositor != '' ]] &&\
	   [[ $display_server == 'wayland' || $display_server == 'mir'  ]];then
		compositor_string="${C1}compositor$SEP3${C2} $compositor "
	fi
	
	if [[ $glx_renderer == '' && $B_ROOT == 'true' ]];then
		root_x_string='for root '
		b_advanced='false'
# 		if [[ $B_IRC == 'false' || $B_CONSOLE_IRC == 'true' ]];then
# 			res_tty='tty size'
# 		fi
	fi
	if [[ $B_RUNNING_IN_DISPLAY != 'true' ]];then
		root_x_string="${root_x_string}out of X"
		res_tty='tty size'
	fi
	#  || -n ${screen_resolution/*@*/}
	if [[ $b_force_tty == 'true' || $B_SHOW_DISPLAY_DATA != 'true' || $B_RUNNING_IN_DISPLAY != 'true' ]];then
		res_tty='tty size'
	fi
	if [[ -n $root_x_string ]];then
		root_x_string="${C1}Advanced Data$SEP3${C2} N/A $root_x_string"
	fi
	# note, this comes out with a count of 1 sometimes for null data
	if [[ ${A_GRAPHICS_CARD_DATA[0]} != '' ]];then
		for (( i=0; i < ${#A_GRAPHICS_CARD_DATA[@]}; i++ ))
		do
			IFS=","
			a_graphics_working=( ${A_GRAPHICS_CARD_DATA[i]} )
			IFS="$ORIGINAL_IFS"
			card_bus_id=''
			card_data=${a_graphics_working[0]}
			if [[ $b_pci_driver == 'true' && ${a_graphics_working[2]} != '' ]];then
				if [[ $sep_pci == ',' ]];then
					driver_plural='s'
				else
					driver=' ' # front pad to match other matches
				fi
				driver=$driver$sep_pci${a_graphics_working[2]}
				sep_pci=','
			fi
			if [[ $B_EXTRA_DATA == 'true' ]];then
				if [[ -n ${a_graphics_working[1]} ]];then
					card_bus_id="${a_graphics_working[1]}"
					if [[ $B_EXTRA_EXTRA_DATA == 'true' ]];then
						if [[ $BSD_TYPE != 'bsd' ]];then
							chip_id=$( get_lspci_chip_id "${a_graphics_working[1]}" )
						else
							chip_id=${a_graphics_working[2]}
						fi
					fi
				else
					card_bus_id='N/A'
				fi
			fi
			if [[ -n $card_bus_id ]];then
				card_bus_id="${C1}bus-ID$SEP3${C2} $card_bus_id "
			fi
			if [[ -n $chip_id ]];then
				chip_id="${C1}chip-ID$SEP3${C2} $chip_id"
			fi
			if [[ ${#A_GRAPHICS_CARD_DATA[@]} -gt 1 ]];then
				card_id="-$(($i+1))"
			fi
			
			part_1_data="${C1}Card$card_id$SEP3${C2} $card_data "
			part_2_data="$card_bus_id$chip_id"
			
			if [[ ${#A_GRAPHICS_CARD_DATA[@]} -gt 1 ]];then
				calculate_line_length "$part_1_data$part_2_data"
				if [[ $LINE_LENGTH -gt $COLS_INNER ]];then
					graphics_data=$( create_print_line "$line_starter" "$part_1_data" )
					print_screen_output "$graphics_data"
					part_1_data=''
					line_starter=' '
				fi
				if [[ -n $( grep -vE '^[[:space:]]*$' <<< $part_1_data$part_2_data ) ]];then
					graphics_data=$( create_print_line "$line_starter" "$part_1_data$part_2_data" )
					print_screen_output "$graphics_data"
				fi
				part_1_data=''
				part_2_data=''
				line_starter=' '
				graphics_data=''
			fi
		done
	# handle cases where card detection fails, like in PS3, where lspci gives no output, or headless boxes..
	else
		part_1_data="${C1}Card$SEP3${C2} Failed to Detect Video Card! "
	fi
	# Print cards if not dual card system
	if [[ -n $part_1_data$part_2_data ]];then 
		calculate_line_length "$part_1_data$part_2_data"
		if [[ $LINE_LENGTH -gt $COLS_INNER ]];then
			graphics_data=$( create_print_line "$line_starter" "$part_1_data" )
			print_screen_output "$graphics_data"
			part_1_data=''
			line_starter=' '
		fi
		if [[ -n $( grep -vE '^[[:space:]]*$' <<< $part_1_data$part_2_data ) ]];then
			graphics_data=$( create_print_line "$line_starter" "$part_1_data$part_2_data" )
			print_screen_output "$graphics_data"
		fi
	fi
	line_starter=' '
	graphics_data=''
	if [[ $driver == '' ]];then
		driver=' N/A'
	fi
	res_string="${C1}$res_tty$SEP3${C2} $screen_resolution "
	display_server_string="${C1}Display Server${SEP3}${C2} $display_server_string$compositor_string"
	driver_string="${C1}driver$driver_plural$SEP3${C2}$driver "
	part_2_data="$res_string$root_x_string"
	calculate_line_length "$display_server_string$driver_string$part_2_data"
	if [[ $LINE_LENGTH -gt $COLS_INNER ]];then
		calculate_line_length "$display_server_string$driver_string"
		if [[ $LINE_LENGTH -gt $COLS_INNER ]];then
			#echo one
			graphics_data=$( create_print_line "$line_starter" "$display_server_string" )
			print_screen_output "$graphics_data"
			graphics_data=$( create_print_line "  " "$driver_string" )
			print_screen_output "$graphics_data"
		else
			#echo two
			graphics_data=$( create_print_line "$line_starter" "$display_server_string$driver_string" )
			print_screen_output "$graphics_data"
		fi
		line_starter=' '
		display_server_string=''
		driver_string=''
	else
		#echo three
		graphics_data=$( create_print_line "$line_starter" "$display_server_string$driver_string$part_2_data" )
		print_screen_output "$graphics_data"
		line_starter=' '
		display_server_string=''
		driver_string=''
		part_2_data=''
	fi
	graphics_data=$display_server_string$driver_string$part_2_data
	if [[ -n "${graphics_data// }" ]];then
		#echo four
		graphics_data=$( create_print_line "$line_starter" "$display_server_string$driver_string$part_2_data" )
		print_screen_output "$graphics_data"
		line_starter=' '
	fi
	# if [[ -z $glx_renderer || -z $glx_version ]];then
	# 	b_is_mesa='true'
	# fi

	## note: if glx render or display_version have no content, then mesa is true
	# if [[ $B_SHOW_DISPLAY_DATA == 'true' ]] && [[ $b_is_mesa != 'true' ]];then
	# if [[ $B_SHOW_DISPLAY_DATA == 'true' && $B_ROOT != 'true' ]];then
	if [[ $B_SHOW_DISPLAY_DATA == 'true' && $b_advanced == 'true' ]];then
		if [[ -z $glx_renderer ]];then
			glx_renderer='N/A'
		fi
		if [[ -z $glx_version  ]];then
			glx_version='N/A'
		else
			# non free drivers once filtered and cleaned show the same for core and compat
			if [[ -n $glx_core_version && $glx_core_version != $glx_version ]];then
				glx_version=$glx_core_version
				if [[ $B_EXTRA_EXTRA_DATA == 'true' ]];then
					if [[ $glx_compat_version_nu != '' ]];then
						glx_version="$glx_version (compat-v$SEP3 $glx_compat_version_nu)"
					fi
				fi
			fi
		fi
		
		if [[ -z $direct_rendering ]];then
			direct_rendering='N/A'
		fi
		if [[ $B_HANDLE_CORRUPT_DATA == 'true' || $B_EXTRA_DATA == 'true' ]];then
			direct_render_string=" ${C1}Direct Render$SEP3${C2} $direct_rendering"
		fi
		part_1_data="${C1}OpenGL$SEP3 renderer$SEP3${C2} $glx_renderer "
		part_2_data="${C1}version$SEP3${C2} $glx_version$direct_render_string"
		# echo $line_starter
		calculate_line_length "$part_1_data$part_2_data"
		if [[ $LINE_LENGTH -gt $COLS_INNER ]];then
			graphics_data=$( create_print_line "$line_starter" "$part_1_data" )
			print_screen_output "$graphics_data"
			part_1_data=''
			line_starter=' '
		fi
		if [[ -n $part_1_data$part_2_data ]];then
			graphics_data=$( create_print_line "$line_starter" "$part_1_data$part_2_data" )
			print_screen_output "$graphics_data"
		fi
	fi
	eval $LOGFE
}

print_hard_disk_data()
{
	eval $LOGFS
	local hdd_data='' hdd_data_2='' a_hdd_working='' hdd_temp_data='' hdd_string=''
	local hdd_serial='' dev_string='/dev/' firmware_rev=''
	local dev_data='' size_data='' hdd_model='' usb_data='' hdd_name=''
	local Line_Starter='Drives:' # inherited by print_optical_drives
	# load A_HDD_DATA - this will also populate the full bsd disk data array values
	get_hdd_data_basic
	## note: if hdd_model is declared prior to use, whatever string you want inserted will
	## be inserted first. In this case, it's desirable to print out (x) before each disk found.
	local a_hdd_data_count=$(( ${#A_HDD_DATA[@]} - 1 ))
	IFS=","
	local a_hdd_basic_working=( ${A_HDD_DATA[$a_hdd_data_count]} )
	IFS="$ORIGINAL_IFS"
	local hdd_capacity="${a_hdd_basic_working[0]}"
	local hdd_used=${a_hdd_basic_working[1]}
	local bsd_error="No HDD Info. $FILE_DMESG_BOOT not readable?"
	local hdd_name_temp='' part_1_data='' part_2_data=''
	local row_starter="${C1}HDD Total Size$SEP3${C2} $hdd_capacity ($hdd_used) "
	# in bsd, /dev/wd0c is disk id
	if [[ -n $BSD_TYPE ]];then
		dev_string=''
	fi

	if [[ $B_SHOW_BASIC_DISK == 'true' || $B_SHOW_DISK == 'true' ]];then
		## note: the output part of this should be in the print hdd data function, not here
		get_hard_drive_data_advanced
		
		# temporary message to indicate not yet supported
		if [[ $BSD_TYPE == 'bsd' && -z $DMESG_BOOT_DATA ]];then
			hdd_data=$bsd_error
			hdd_data=$( create_print_line "$Line_Starter" "$hdd_data" )
			print_screen_output "$hdd_data"
			Line_Starter=' '
		else
			for (( i=0; i < ${#A_HDD_DATA[@]} - 1; i++ ))
			do
				# this adds the (x) numbering in front of each disk found, and creates the full disk string
				IFS=","
				a_hdd_working=( ${A_HDD_DATA[i]} )
				IFS="$ORIGINAL_IFS"
				if [[ $B_SHOW_DISK == 'true' ]];then
					if [[ -n ${a_hdd_working[3]} ]];then
						usb_data="${a_hdd_working[3]} "
					else
						usb_data=''
					fi
					size_data=" ${C1}size$SEP3${C2} ${a_hdd_working[1]}"
					if [[ $B_EXTRA_DATA == 'true' ]];then
						hdd_temp_data=${a_hdd_working[5]}
						# error handling is done in get data function
						if [[ -n $hdd_temp_data ]];then
							hdd_temp_data="${C1}temp$SEP3${C2} ${hdd_temp_data}C "
						else
							hdd_temp_data=''
						fi
					fi
					if [[ $B_EXTRA_EXTRA_DATA == 'true' ]];then
						if [[ -n ${a_hdd_working[4]} ]];then
							if [[ $B_OUTPUT_FILTER == 'true' ]];then
								hdd_serial=$FILTER_STRING
							else
								hdd_serial=${a_hdd_working[4]}
							fi
						else
							hdd_serial='N/A'
						fi
						hdd_serial="${C1}serial$SEP3${C2} $hdd_serial "
						if [[ -n ${a_hdd_working[6]} ]];then
							firmware_rev=${a_hdd_working[6]}
							firmware_rev="${C1}firmware$SEP3${C2} $firmware_rev "
						else
							firmware_rev=''
						fi
					fi
					dev_data="$dev_string${a_hdd_working[0]} "
				fi
				if [[ -n ${a_hdd_working[2]} ]];then
					hdd_name_temp=${a_hdd_working[2]}
				else
					hdd_name_temp='N/A'
				fi
				# echo "loop: $i"
				hdd_name="${C1}model$SEP3${C2} $hdd_name_temp"
				hdd_string="${C1}ID-$((i+1))$SEP3${C2} $usb_data$dev_data$hdd_name$size_data"
				part_1_data="$hdd_model$hdd_string "
				part_2_data="$hdd_serial$hdd_temp_data$firmware_rev"
				## Forcing the capacity to print on its own row, and the first drive on its own
				## then each disk prints on its own line, or two lines, depending on console/output width
				if [[ $i -eq 0 ]];then
					#if [[ $( calculate_line_length "$row_starter$part_1_data" ) -gt 80 ]];then
					if [[ -n $row_starter ]];then
						hdd_data=$( create_print_line "$Line_Starter" "$row_starter" )
						print_screen_output "$hdd_data"
						#echo 0
						Line_Starter=' '
						row_starter=''
					fi
					calculate_line_length "$part_1_data$part_2_data"
					if [[ $LINE_LENGTH -gt $COLS_INNER ]];then
						hdd_data=$( create_print_line "$Line_Starter" "$part_1_data" )
						print_screen_output "$hdd_data"
						part_1_data=''
						hdd_data=$( create_print_line "$Line_Starter" "$part_2_data" )
						print_screen_output "$hdd_data"
						part_2_data=''
					else
						hdd_data=$( create_print_line "$Line_Starter" "$part_1_data$part_2_data" )
						print_screen_output "$hdd_data"
						part_1_data=''
						part_2_data=''
					fi
						#echo 1
					#else
					#	hdd_data=$( create_print_line "$Line_Starter" "$row_starter$part_1_data" )
					#	print_screen_output "$hdd_data"
					#	Line_Starter=' '
					#	row_starter=''
					#	part_1_data=''
						#echo 2
					#fi
				else
					calculate_line_length "$part_1_data$part_2_data"
					if [[ $LINE_LENGTH -gt $COLS_INNER ]];then
						hdd_data=$( create_print_line "$Line_Starter" "$part_1_data" )
						print_screen_output "$hdd_data"
						part_1_data=''
						hdd_data=$( create_print_line "$Line_Starter" "$part_2_data" )
						print_screen_output "$hdd_data"
						part_2_data=''
					else
						hdd_data=$( create_print_line "$Line_Starter" "$part_1_data$part_2_data" )
						print_screen_output "$hdd_data"
						part_1_data=''
						part_2_data=''
					fi
				fi
				# calculate_line_length "$part_2_data$part_1_data"
# 				if [[ $LINE_LENGTH -gt $COLS_INNER ]];then
# 					if [[ -n $( grep -vE '^[[:space:]]*$' <<< $part_2_data ) ]];then
# 						hdd_data=$( create_print_line "$Line_Starter" "$part_2_data" )
# 						print_screen_output "$hdd_data"
# 						#echo 3
# 						Line_Starter=' '
# 						#row_starter=''
# 						part_2_data=''
# 					fi
# 					hdd_data=$( create_print_line "$Line_Starter" "$part_1_data" )
# 					print_screen_output "$hdd_data"
# 					part_1_data=''
# 					#echo 4
# 				elif [[ -n $part_2_data && \
# 						$( calculate_line_length "$part_2_data$part_1_data" ) -le $COLS_INNER ]];then
# 					hdd_data=$( create_print_line "$Line_Starter" "$part_2_data$part_1_data" )
# 					print_screen_output "$hdd_data"
# 					#echo 3
# 					Line_Starter=' '
# 					#row_starter=''
# 					part_1_data=''
# 					part_2_data=''
# 				else
# 					part_2_data=$part_1_data
# 				fi
			done
			# then print any leftover items
# 			if [[ -n $part_2_data ]];then
# 				hdd_data=$( create_print_line "$Line_Starter" "$part_2_data" )
# 				print_screen_output "$hdd_data"
# 				#echo 5
# 			fi
		fi
	else
		hdd_data="$row_starter"
		hdd_data=$( create_print_line "$Line_Starter" "$hdd_data" )
		print_screen_output "$hdd_data"
		Line_Starter=' '
	fi
	if [[ $B_SHOW_FULL_OPTICAL == 'true' || $B_SHOW_BASIC_OPTICAL == 'true' ]];then
		print_optical_drive_data
	fi

	eval $LOGFE
}

print_info_data()
{
	eval $LOGFS

	local info_data='' line_starter='Info:' runlvl_default='' runlvl='' runlvl_title='runlevel' 
	local init_data='' init_type='' init_version='' rc_type='' rc_version=''
	local client_data='' shell_data='' shell_parent='' tty_session=''
	local processes=$(( $( wc -l <<< "$Ps_aux_Data" ) - 1 ))
	if [[ -z $UP_TIME ]];then
		UP_TIME='N/A - missing uptime?'
	fi
	get_memory_data
	get_uptime
	get_patch_version_string
	local gcc_installed='' gcc_others='' closing_data='' 
	
	if [[ -z $MEMORY ]];then
		MEMORY='N/A'
	fi
	
	if [[ $B_EXTRA_DATA == 'true' ]];then
		get_gcc_system_version
		if [[ ${#A_GCC_VERSIONS[@]} -gt 0 ]];then
			if [[ -n ${A_GCC_VERSIONS[0]} ]];then
				gcc_installed=${A_GCC_VERSIONS[0]}
			else
				gcc_installed='N/A'
			fi
			if [[ $B_EXTRA_EXTRA_DATA == 'true' && -n ${A_GCC_VERSIONS[1]} ]];then
				# gcc_others=" ${C1}alt$SEP3${C2} $( tr ',' '/' <<< ${A_GCC_VERSIONS[1]} )"
				gcc_others=" ${C1}alt$SEP3${C2} ${A_GCC_VERSIONS[1]//,//}"
			fi
			gcc_installed="${C1}Gcc sys$SEP3${C2} $gcc_installed$gcc_others "
		fi
	fi
	if [[  $B_IRC == 'false' ]];then
		shell_data=$( get_shell_data )
		if [[ -n $shell_data ]];then
			# note, if you start this in tty, it will give 'login' as the parent, which we don't want.
			if [[ $B_EXTRA_EXTRA_DATA == 'true' ]];then
				if [[ $B_RUNNING_IN_DISPLAY != 'true' ]];then
					shell_parent=$( get_tty_number )
					shell_parent="tty $shell_parent"
				else
					shell_parent=$( get_shell_parent )
				fi
				if [[ $shell_parent == 'login' ]];then
					shell_parent=''
				elif [[ -n $shell_parent ]];then
					shell_parent=" running in ${shell_parent##*/}"
				fi
			fi
			IRC_CLIENT="$IRC_CLIENT ($shell_data$shell_parent)"
		fi
	fi

	# Some code could look superfluous but BitchX doesn't like lines not ending in a newline. F*&k that bitch!
	# long_last=$( echo -ne "${C1}Processes$SEP3${C2} $processes${CN} | ${C1}Uptime$SEP3${C2} $UP_TIME${CN} | ${C1}Memory$SEP3${C2} $MEM${CN}" )
	info_data="${C1}Processes$SEP3${C2} $processes ${C1}Uptime$SEP3${C2} $UP_TIME ${C1}Memory$SEP3${C2} $MEMORY "

	# this only triggers if no X data is present or if extra data switch is on
	if [[ $B_SHOW_DISPLAY_DATA != 'true' || $B_EXTRA_DATA == 'true' ]];then
		get_init_data
		if [[ ${A_INIT_DATA[0]} == 'systemd' && -z $( grep -E '^[0-9]$' <<< ${A_INIT_DATA[4]} ) ]];then
			runlvl_title='target'
		fi
		init_type=${A_INIT_DATA[0]}
		if [[ -z $init_type ]];then
			init_type='N/A'
		fi
		if [[ $B_EXTRA_EXTRA_DATA == 'true' ]];then
			init_version=${A_INIT_DATA[1]}
			if [[ -z $init_version ]];then
				init_version='N/A'
			fi
			init_version=" ${C1}v$SEP3${C2} $init_version"
			rc_version=${A_INIT_DATA[3]}
			if [[ -n $rc_version ]];then
				rc_version="${C1}v$SEP3${C2} $rc_version "
			fi
			runlvl_default=${A_INIT_DATA[5]}
		fi
		# currently only using openrc here, otherwise show nothing
		rc_type=${A_INIT_DATA[2]}
		if [[ -n $rc_type ]];then
			rc_type="${C1}rc$SEP3${C2} $rc_type $rc_version"
		fi
		init_type="${C1}Init$SEP3${C2} $init_type$init_version "
		runlvl=${A_INIT_DATA[4]}
		if [[ -n $runlvl ]];then
			runlvl="${C1}$runlvl_title$SEP3${C2} $runlvl "
		fi
		if [[ -n $runlvl_default ]];then
			runlvl_default="${C1}default$SEP3${C2} $runlvl_default "
		fi
		init_data="$init_type$rc_type$runlvl$runlvl_default"
	fi
	if [[ $SHOW_IRC -gt 0 ]];then
		client_data="${C1}Client$SEP3${C2} $IRC_CLIENT$IRC_CLIENT_VERSION "
	fi
	# info_data="$info_data"
	closing_data="$client_data${C1}$SELF_NAME$SEP3${C2} $SELF_VERSION$SELF_PATCH"
	# sometimes gcc is very long, and default runlevel can be long with systemd, so create a gcc-less line first
	calculate_line_length "$info_data$init_data$gcc_installed"
	if [[ $LINE_LENGTH -gt $COLS_INNER ]];then
		# info_data=$info_data
		info_data=$( create_print_line "$line_starter" "$info_data" )
		print_screen_output "$info_data"
		info_data=''
		# closing_data=''
		line_starter=' '
		#echo 1
	fi
	calculate_line_length "$init_data$gcc_installed"
	if [[ $LINE_LENGTH -gt $COLS_INNER ]];then
		info_data=$init_data
		info_data=$( create_print_line "$line_starter" "$info_data" )
		print_screen_output "$info_data"
		info_data=''
		init_data=''
		line_starter=' '
		#echo 2
	fi
	calculate_line_length "$info_data$init_data$gcc_installed$closing_data"
	if [[ $LINE_LENGTH -gt $COLS_INNER ]];then
		info_data=$info_data$init_data$gcc_installed
		info_data=$( create_print_line "$line_starter" "$info_data" )
		print_screen_output "$info_data"
		info_data=''
		gcc_installed=''
		init_data=''
		line_starter=' '
		#echo 3
	fi
	info_data="$info_data$init_data$gcc_installed$closing_data"
	
	info_data=$( create_print_line "$line_starter" "$info_data" )
	if [[ $SCHEME -gt 0 ]];then
		info_data="$info_data ${NORMAL}"
	fi
	print_screen_output "$info_data"
	
	eval $LOGFE
}
#print_info_data;exit 
print_machine_data()
{
	eval $LOGFS
	
	local system_line='' mobo_line='' bios_line='' chassis_line='' #firmware_type='BIOS'
	local mobo_vendor='' mobo_model='' mobo_version='' mobo_serial=''
	local bios_vendor='' bios_version='' bios_date='' bios_rom='' error_string=''
	local system_vendor='' product_name='' product_version='' product_serial='' product_uuid=''
	local chassis_vendor='' chassis_type='' chassis_version='' chassis_serial='' 
	local b_skip_system='false' b_skip_chassis='false'
	local sysDmiNull='No /sys/class/dmi machine data: try newer kernel, or install dmidecode'
	local device=$(get_device_data)
	# set A_MACHINE_DATA
	get_machine_data
	
	IFS=','
	## keys for machine data are:
	# 0-sys_vendor 1-product_name 2-product_version 3-product_serial 4-product_uuid 
	# 5-board_vendor 6-board_name 7-board_version 8-board_serial 
	# 9-bios_vendor 10-bios_version 11-bios_date
	## with extra data: 
	# 12-chassis_vendor 13-chassis_type 14-chassis_version 15-chassis_serial
	## unused: 16-firmware_revision  17-firmware_romsize
	# 
	# a null array always has a count of 1
	if [[ ${#A_MACHINE_DATA[@]} -gt 1 ]];then
		# note: in some case a mobo/version will match a product name/version, do not print those
		# but for laptops, or even falsely id'ed desktops with batteries, let's print it all if it matches
		# there can be false id laptops if battery appears so need to make sure system is filled
		if [[ -z ${A_MACHINE_DATA[0]} ]];then
			b_skip_system='true'
		else
			if [[ $B_POSSIBLE_PORTABLE != 'true'  ]];then
				# ibm / ibm can be true; dell / quantum is false, so in other words, only do this
				# in case where the vendor is the same and the version is the same and not null, 
				# otherwise the version information is going to be different in all cases I think
				if [[ -n ${A_MACHINE_DATA[0]} && ${A_MACHINE_DATA[0]} == ${A_MACHINE_DATA[5]} ]];then
					if [[ -n ${A_MACHINE_DATA[2]} && ${A_MACHINE_DATA[2]} == ${A_MACHINE_DATA[7]} ]] || \
					[[ -z ${A_MACHINE_DATA[2]} && ${A_MACHINE_DATA[1]} == ${A_MACHINE_DATA[6]} ]];then
						b_skip_system='true'
					fi
				fi
			fi
		fi
		# no point in showing chassis if system isn't there, it's very unlikely that would be correct
		if [[ $B_EXTRA_EXTRA_DATA == 'true' && $b_skip_system != 'true' ]];then
			if [[ -n ${A_MACHINE_DATA[7]} && ${A_MACHINE_DATA[14]} == ${A_MACHINE_DATA[7]} ]];then
				b_skip_chassis='true'
			fi
			if [[ -n ${A_MACHINE_DATA[12]} && $b_skip_chassis != 'true' ]];then
				# no need to print the vendor string again if it's the same
				if [[ ${A_MACHINE_DATA[12]} != ${A_MACHINE_DATA[0]} ]];then
					chassis_vendor=" ${A_MACHINE_DATA[12]}"
				fi
				if [[ -n ${A_MACHINE_DATA[13]} ]];then
					chassis_type=" ${C1}type$SEP3${C2} ${A_MACHINE_DATA[13]}"
				fi
				if [[ -n ${A_MACHINE_DATA[14]} ]];then
					chassis_version=" ${C1}v$SEP3${C2} ${A_MACHINE_DATA[14]}"
				fi
				if [[ -n ${A_MACHINE_DATA[15]} ]];then
					if [[ $B_OUTPUT_FILTER == 'true' ]];then
						chassis_serial=$FILTER_STRING
					else
						chassis_serial=${A_MACHINE_DATA[15]}
					fi
				else
					chassis_serial='N/A'
				fi
				chassis_serial=" ${C1}serial$SEP3${C2} $chassis_serial"
				if [[ -n "$chassis_vendor$chassis_type$chassis_version$chassis_serial" ]];then
					chassis_line="${C1}Chassis$SEP3${C2}$chassis_vendor$chassis_type$chassis_version$chassis_serial"
				fi
			fi
		fi
		# echo ${A_MACHINE_DATA[@]}
		if [[ -n ${A_MACHINE_DATA[18]} ]];then
			firmware_type=${A_MACHINE_DATA[18]}
		fi
		if [[ -n ${A_MACHINE_DATA[5]} ]];then
			mobo_vendor=${A_MACHINE_DATA[5]}
		else
			mobo_vendor='N/A'
		fi
		if [[ -n ${A_MACHINE_DATA[6]} ]];then
			mobo_model=${A_MACHINE_DATA[6]}
		else
			mobo_model='N/A'
		fi
		if [[ -n ${A_MACHINE_DATA[7]} ]];then
			mobo_version=" ${C1}v$SEP3${C2} ${A_MACHINE_DATA[7]}"
		fi
		if [[ -n ${A_MACHINE_DATA[8]} ]];then
			if [[ $B_OUTPUT_FILTER == 'true' ]];then
				mobo_serial=$FILTER_STRING
			else
				mobo_serial=${A_MACHINE_DATA[8]}
			fi
		else
			mobo_serial='N/A'
		fi
		mobo_serial=" ${C1}serial$SEP3${C2} $mobo_serial"
		if [[ -n ${A_MACHINE_DATA[9]} ]];then
			bios_vendor=${A_MACHINE_DATA[9]}
		else
			bios_vendor='N/A'
		fi
		if [[ -n ${A_MACHINE_DATA[10]} ]];then
			bios_version=${A_MACHINE_DATA[10]}
			if [[ -n ${A_MACHINE_DATA[16]} ]];then
				bios_version="$bios_version rv ${A_MACHINE_DATA[16]}"
			fi
		else
			bios_version='N/A'
		fi
		if [[ -n ${A_MACHINE_DATA[11]} ]];then
			bios_date=${A_MACHINE_DATA[11]}
		else
			bios_date='N/A'
		fi
		if [[ $B_EXTRA_EXTRA_DATA == 'true' && -n ${A_MACHINE_DATA[17]} ]];then
			bios_rom=" ${C1}rom size$SEP3${C2} ${A_MACHINE_DATA[17]}"
		fi
		mobo_line="${C1}Mobo$SEP3${C2} $mobo_vendor ${C1}model$SEP3${C2} $mobo_model$mobo_version$mobo_serial"
		bios_line="${C1}$firmware_type$SEP3${C2} $bios_vendor ${C1}v$SEP3${C2} $bios_version ${C1}date$SEP3${C2} $bios_date$bios_rom"
		calculate_line_length "$mobo_line$bios_line"
		if [[ $LINE_LENGTH -lt $COLS_INNER ]];then
			mobo_line="$mobo_line $bios_line"
			bios_line=''
		fi
		if [[ $b_skip_system == 'true' ]];then
			system_line="${C1}Device$SEP3${C2} $device $mobo_line"
			mobo_line=''
		else
			# this has already been tested for above so we know it's not null
			system_vendor=${A_MACHINE_DATA[0]}
 			if [[ -n ${A_MACHINE_DATA[1]} ]];then
				product_name=${A_MACHINE_DATA[1]}
			else
				product_name='N/A'
			fi
			if [[ -n ${A_MACHINE_DATA[2]} ]];then
				product_version=" ${C1}v$SEP3${C2} ${A_MACHINE_DATA[2]}"
			fi
			if [[ -n ${A_MACHINE_DATA[3]} ]];then
				if [[ $B_OUTPUT_FILTER == 'true' ]];then
					product_serial=$FILTER_STRING
				else
					product_serial=${A_MACHINE_DATA[3]}
				fi
			else
				product_serial='N/A'
			fi
			product_serial=" ${C1}serial$SEP3${C2} $product_serial "
			system_line="${C1}Device$SEP3${C2} $device ${C1}System$SEP3${C2} $system_vendor ${C1}product$SEP3${C2} $product_name$product_version$product_serial"
			calculate_line_length "$system_line$chassis_line"
			if [[ -n $chassis_line && $LINE_LENGTH -lt $COLS_INNER ]];then
				system_line="$system_line $chassis_line"
				chassis_line=''
			fi
		fi
	else
		system_line="${C2}$sysDmiNull"
	fi
	IFS="$ORIGINAL_IFS"
	# patch to dump all of above if dmidecode was data source and a dmidecode error is present
	if [[ ${A_MACHINE_DATA[0]} == 'dmidecode-error-'* ]];then
		error_string=$( print_dmidecode_error 'sys' "${A_MACHINE_DATA[0]}" )
		system_line=${C2}$error_string
		mobo_line=''
		bios_line=''
		chassis_line=''
	fi
	system_line=$( create_print_line "Machine:" "$system_line" )
	print_screen_output "$system_line"
	if [[ -n $mobo_line ]];then
		mobo_line=$( create_print_line " " "$mobo_line" )
		print_screen_output "$mobo_line"
	fi
	if [[ -n $bios_line ]];then
		bios_line=$( create_print_line " " "$bios_line" )
		print_screen_output "$bios_line"
	fi
	if [[ -n $chassis_line ]];then
		chassis_line=$( create_print_line " " "$chassis_line" )
		print_screen_output "$chassis_line"
	fi
	
	eval $LOGFE
}

# args: $1 - module name (could be > 1, so loop it ); $2 - audio (optional)
print_module_version()
{
	eval $LOGFS
	local module_versions='' module='' version='' prefix='' modules=$1
	
	# note that sound driver data tends to have upper case, but modules are lower
	if [[ $2 == 'audio' ]];then
		if [[ -z $( grep -E '^snd' <<< $modules ) ]];then
			prefix='snd_' # sound modules start with snd_
		fi
		
		if (( "$BASH" >= 4 ));then
			modules="${modules,,}"
		else 
			modules=$( tr '[A-Z]' '[a-z]' <<< "$modules" )
		fi
		modules=${modules//-/_}
		# special intel processing, generally no version info though
		if [[ $modules == 'hda intel' ]];then
			modules='hda_intel'
		elif [[ $modules == 'intel ich' ]];then
			modules='intel8x0'
		fi
	fi

	for module in $modules
	do
		version=$( get_module_version_number "$prefix$module" )
		if [[ -n $version ]];then
			module_versions="$module_versions $version"
		fi
	done

	if [[ -n $module_versions ]];then
		echo " ${C1}v$SEP3${C2}$module_versions"
	fi
	eval $LOGFE
}

print_networking_data()
{
	eval $LOGFS
	local i='' card_id='' network_data='' a_network_working='' port_data='' driver_data=''
	local card_string='' port_plural='' module_version='' pci_bus_id='' bus_usb_text=''
	local bus_usb_id='' line_starter='Network:' card_string='' card_data='' chip_id=''
	local driver='' part_2_data=''
	
	# set A_NETWORK_DATA
	if [[ $BSD_TYPE == 'bsd' ]];then
		if [[ $B_PCICONF == 'true' ]];then
			if [[ $B_PCICONF_SET == 'false' ]];then
				get_pciconf_data
			fi
			get_pciconf_card_data 'network'
		elif [[ $B_LSPCI == 'true' ]];then
			get_networking_data
		fi
	else
		get_networking_data
	fi

	# will never be null because null is handled in get_network_data, but in case we change
	# that leaving this test in place.
	if [[ -n ${A_NETWORK_DATA[@]} ]];then
		for (( i=0; i < ${#A_NETWORK_DATA[@]}; i++ ))
		do
			IFS=","
			a_network_working=( ${A_NETWORK_DATA[i]} )
			IFS="$ORIGINAL_IFS"
			bus_usb_id=''
			bus_usb_text=''
			card_data=''
			card_string=''
			driver_data=''
			module_version=''
			network_data=''
			pci_bus_id=''
			port_data=''
			port_plural=''
			chip_id=''
			part_2_data=''

			if [[ ${#A_NETWORK_DATA[@]} -gt 1 ]];then
				card_id="-$(( $i + 1 ))"
			fi
			if [[ -n ${a_network_working[1]} && $B_EXTRA_DATA == 'true' && $BSD_TYPE != 'bsd' ]];then
				module_version=$( print_module_version "${a_network_working[1]}" )
			fi
			if [[ -n ${a_network_working[1]} ]];then
				# note: linux drivers can have numbers, like tg3
				if [[ $BSD_TYPE == 'bsd' ]];then
					driver=$( sed 's/[0-9]*$//' <<< ${a_network_working[1]} )
				else
					driver=${a_network_working[1]}
				fi
				driver_data="${C1}driver$SEP3${C2} $driver$module_version "
			fi
			if [[ -n ${a_network_working[2]} && $B_EXTRA_DATA == 'true' ]];then
				if [[ $( wc -w <<< ${a_network_working[2]} ) -gt 1 ]];then
					port_plural='s'
				fi
				port_data="${C1}port$port_plural$SEP3${C2} ${a_network_working[2]} "
			fi
			if [[ -n ${a_network_working[4]} && $B_EXTRA_DATA == 'true' ]];then
				if [[ -z $( grep '^usb-' <<< ${a_network_working[4]} ) ]];then
					bus_usb_text='bus-ID'
					bus_usb_id=${a_network_working[4]}
					if [[ $B_EXTRA_EXTRA_DATA == 'true' ]];then
						if [[ $BSD_TYPE != 'bsd' ]];then
							chip_id=$( get_lspci_chip_id "${a_network_working[4]}" )
						else
							chip_id=${a_network_working[10]}
						fi
					fi
				else
					bus_usb_text='usb-ID'
					bus_usb_id=$( cut -d '-' -f '2-4' <<< ${a_network_working[4]} )
					if [[ $B_EXTRA_EXTRA_DATA == 'true' ]];then
						chip_id=${a_network_working[10]}
					fi
				fi
				pci_bus_id="${C1}$bus_usb_text$SEP3${C2} $bus_usb_id"
				if [[ -n $chip_id ]];then
					chip_id=" ${C1}chip-ID$SEP3${C2} $chip_id"
				fi
			fi
			card_string="${C1}Card$card_id$SEP3${C2} ${a_network_working[0]} "
			card_data="$driver_data$port_data"
			part_2_data="$pci_bus_id$chip_id"
			calculate_line_length "$card_string$card_data$part_2_data"
			if [[ $LINE_LENGTH -gt $COLS_INNER ]];then
				network_data=$( create_print_line "$line_starter" "$card_string" )
				line_starter=' '
				card_string=''
				print_screen_output "$network_data"
			fi
			calculate_line_length "$card_string$card_data$part_2_data"
			if [[ $LINE_LENGTH -gt $COLS_INNER ]];then
				network_data=$( create_print_line "$line_starter" "$card_string$card_data" )
				print_screen_output "$network_data"
				line_starter=' '
				card_data=''
				card_string=''
				
			fi
			if [[ -n $card_string$card_data$part_2_data ]];then
				network_data=$( create_print_line "$line_starter" "$card_string$card_data$part_2_data" )
				print_screen_output "$network_data"
				line_starter=' '
				card_data=''
				card_string=''
				part_2_data=''
			fi
			if [[ $B_SHOW_ADVANCED_NETWORK == 'true' ]];then
				print_network_advanced_data
			fi
		done
	else
		network_data="${C1}Card$SEP3${C2} Failed to Detect Network Card! "
		network_data=$( create_print_line "$line_starter" "$network_data" )
		print_screen_output "$network_data"
	fi
	if [[ $B_SHOW_IP == 'true' ]];then
		print_networking_ip_data
	fi
	eval $LOGFE
}

print_network_advanced_data()
{
	eval $LOGFS
	local network_data='' if_id='N/A' duplex='N/A' mac_id='N/A' speed='N/A' oper_state='N/A'
	local b_is_wifi='false' speed_string='' duplex_string='' part_2_data=''
	
		# first check if it's a known wifi id'ed card, if so, no print of duplex/speed
	if [[ -n $( grep -Esi '(wireless|wifi|wi-fi|wlan|802\.11|centrino)' <<< ${a_network_working[0]} ) ]];then
		b_is_wifi='true'
	fi
	if [[ -n ${a_network_working[5]} ]];then
		if_id=${a_network_working[5]}
	fi
	if [[ -n ${a_network_working[6]} ]];then
		oper_state=${a_network_working[6]}
	fi
	# no print out for wifi since it doesn't have duplex/speed data available
	# note that some cards show 'unknown' for state, so only testing explicitly
	# for 'down' string in that to skip showing speed/duplex
	if [[ $b_is_wifi != 'true' && $oper_state != 'down' ]];then
		if [[ -n ${a_network_working[7]} ]];then
			# make sure the value is strictly numeric before appending Mbps
			if [[ -n $( grep -E '^[0-9\.,]+$' <<< "${a_network_working[7]}" ) ]];then
				speed="${a_network_working[7]} Mbps"
			else
				speed=${a_network_working[7]}
			fi
		fi
		speed_string="${C1}speed$SEP3${C2} $speed "
		if [[ -n ${a_network_working[8]} ]];then
			duplex=${a_network_working[8]}
		fi
		duplex_string="${C1}duplex$SEP3${C2} $duplex "
	fi
	if [[ -n ${a_network_working[9]} ]];then
		if [[ $B_OUTPUT_FILTER == 'true' ]];then
			mac_id=$FILTER_STRING
		else
			mac_id=${a_network_working[9]}
		fi
	fi
	network_data="${C1}IF$SEP3${C2} $if_id ${C1}state$SEP3${C2} $oper_state $speed_string$duplex_string"
	part_2_data="${C1}mac$SEP3${C2} $mac_id"
	calculate_line_length "$network_data$part_2_data"
	if [[ $LINE_LENGTH -gt $COLS_INNER ]];then
		network_data=$( create_print_line " " "$network_data" )
		print_screen_output "$network_data"
		network_data=''
	fi
	if [[ -n $network_data$part_2_data ]];then
		network_data=$( create_print_line " " "$network_data$part_2_data" )
		print_screen_output "$network_data"
		network_data=''
	fi
	
	eval $LOGFE
}

print_networking_ip_data()
{
	eval $LOGFS
	# $ip should be IPv4
	local ip=$( get_networking_wan_ip_data )
	local wan_ip_data='' a_interfaces_working='' interfaces='' i=0
	local if_id='' if_ip='' if_ipv6='' if_ipv6_string='' full_string='' if_string=''
	local if_id_string='' if_ip_string='' if_string_holding=''

	# set A_INTERFACES_DATA
	get_networking_local_ip_data
	# first print output for wan ip line. Null is handled in the get function
	if [[ -z $ip ]];then
		ip='N/A'
	else
		if [[ $B_OUTPUT_FILTER == 'true' ]];then
			ip=$FILTER_STRING
		fi
	fi
	wan_ip_data="${C1}WAN IP$SEP3${C2} $ip "
	# then create the list of local interface/ip
	i=0 ## loop starts with 1 by auto-increment so it only shows cards > 1
	while [[ -n ${A_INTERFACES_DATA[i]} ]]
	do
		IFS=","
		a_interfaces_working=(${A_INTERFACES_DATA[i]})
		IFS="$ORIGINAL_IFS"
		if_id='N/A'
		if_ip='N/A'
		if_ipv6='N/A'
		if_ipv6_string=''
		if [[ -z $( grep '^Interface' <<< ${a_interfaces_working[0]} ) ]];then
			if [[ -n ${a_interfaces_working[1]} ]];then
				if [[ $B_OUTPUT_FILTER == 'true' ]];then
					if_ip=$FILTER_STRING
					# we could filter each ipv6 extra address, but that can lead to 
					# a LOT of pointless output depending on the ip tool used and how 
					# many deprecated addresses there are, so just delete the values
					a_interfaces_working[4]=''
				else
					if_ip=${a_interfaces_working[1]}
				fi
			fi
			if_ip_string=" ${C1}ip-v4$SEP3${C2} $if_ip"
			# this is now going to always show as IPv6 starts to really be used globally
			if [[ -n ${a_interfaces_working[3]} ]];then
				if [[ $B_OUTPUT_FILTER == 'true' ]];then
					if_ipv6=$FILTER_STRING
				else
					# may be more than one address here; get them all as one string
					# but this is only the LINK scope, not Site or Global or Temporary
					if_ipv6=${a_interfaces_working[3]/^/, }
				fi
			fi
			if_ipv6_string=" ${C1}ip-v6-link$SEP3${C2} $if_ipv6"
		fi
		if [[ -n ${a_interfaces_working[0]} ]];then
			if_id=${a_interfaces_working[0]}
		fi
		if_string="${C1}IF$SEP3${C2} $if_id$if_ip_string$if_ipv6_string "
		# first line, print wan on its own line, then the next item
		if [[ $i -eq 0 ]];then
			full_string=$( create_print_line " " "$wan_ip_data" )
			print_screen_output "$full_string"
			wan_ip_data=''
		fi
		full_string=$( create_print_line " " "$if_string" )
		print_screen_output "$full_string"
		if_string=''
		if [[ ${a_interfaces_working[4]} != '' && $B_EXTRA_DATA == 'true' ]];then
			IFS="^"
			a_ipv6_ext=(${a_interfaces_working[4]})
			IFS="$ORIGINAL_IFS"
			for (( j=0; j < ${#a_ipv6_ext[@]}; j++ ))
			do
				print_ipv6_ext_line "${a_ipv6_ext[j]}"
			done
		fi
		((i++))
	done
	
	eval $LOGFE
}
print_ipv6_ext_line()
{
	eval $LOGFS
	
	local full_string='' ip_starter='' ip_data='' ip=''
	
	case $1 in
		sg~*)
			ip_starter="ip-v6-global"
			ip=${1/sg~/}
			;;
		ss~*)
			ip_starter="ip-v6-site"
			ip=${1/ss~/}
			;;
		st~*)
			ip_starter="ip-v6-temporary"
			ip=${1/st~/}
			;;
		su~*)
			ip_starter="ip-v6-unknown"
			ip=${1/su~/}
			;;
	esac
	if [[ $B_OUTPUT_FILTER == 'true' ]];then
		ip=$FILTER_STRING
	fi
	ip_data="${C1}$ip_starter$SEP3${C2} $ip"
	full_string=$( create_print_line " " "$ip_data" )
	print_screen_output "$full_string"
	
	eval $LOGFE
}

print_optical_drive_data()
{
	eval $LOGFS
	local a_drives='' drive_data='' counter='' dev_string='/dev/' speed_string='x'
	local drive_id='' drive_links='' vendor='' speed='' multisession='' mcn='' audio=''
	local dvd='' state='' rw_support='' rev='' separator='' drive_string='' part_2_data=''
	local drive_type='Optical' fd_counter=0 opt_counter=0 b_floppy='false'
	if [[ -z $BSD_TYPE ]];then
		get_optical_drive_data
	else
		get_optical_drive_data_bsd
		dev_string=''
		speed_string=''
	fi
	# 0 - true dev path, ie, sr0, hdc
	# 1 - dev links to true path
	# 2 - device vendor - for hdx drives, vendor model are one string from proc
	# 3 - device model
	# 4 - device rev version
	if [[ ${#A_OPTICAL_DRIVE_DATA[@]} -gt 0 ]];then
		for (( i=0; i < ${#A_OPTICAL_DRIVE_DATA[@]}; i++ ))
		do
			IFS=","
			a_drives=(${A_OPTICAL_DRIVE_DATA[i]})
			IFS="$ORIGINAL_IFS"
			audio=''
			drive_data=''
			drive_id=''
			drive_links=''
			dvd='' 
			mcn='' 
			multisession='' 
			rev='' 
			rw_support='' 
			separator=''
			speed='' 
			state='' 
			vendor=''
			if [[ ${#A_OPTICAL_DRIVE_DATA[@]} -eq 1 && -z ${a_drives[0]} && -z ${a_drives[1]} ]];then
				drive_string="No optical drives detected."
				B_SHOW_FULL_OPTICAL='false'
			else
				if [[ -n ${a_drives[0]/fd*/} ]];then
					opt_counter=$(( $opt_counter + 1 ))
					counter="-$opt_counter"
					drive_type='Optical'
					b_floppy='false'
				else
					fd_counter=$(( $fd_counter + 1 ))
					counter="-$fd_counter"
					drive_type='Floppy'
					b_floppy='true'
				fi
				if [[ -z ${a_drives[0]} ]];then
					drive_id='N/A'
				else
					drive_id="$dev_string${a_drives[0]}"
				fi
				if [[ $b_floppy == 'false' ]];then
					drive_links=$( sed 's/~/,/g' <<< ${a_drives[1]} )
					if [[ -z $drive_links ]];then
						drive_links='N/A'
					fi
					if [[ -n ${a_drives[2]} ]];then
						vendor=${a_drives[2]}
						if [[ -n ${a_drives[3]} ]];then
							vendor="$vendor ${a_drives[3]}"
						fi
					fi
					if [[ -z $vendor ]];then
						if [[ -n ${a_drives[3]} ]];then
							vendor=${a_drives[3]}
						else
							vendor='N/A'
						fi
					fi
					if [[ $B_EXTRA_DATA == 'true' ]];then
						if [[ -n ${a_drives[4]} ]];then
							rev=${a_drives[4]}
						else
							rev='N/A'
						fi
						rev="${C1}rev$SEP3${C2} $rev "
					fi
					drive_string="$drive_id ${C1}model$SEP3${C2} $vendor "
					part_2_data="$rev${C1}dev-links$SEP3${C2} $drive_links"
				else
					drive_string="$drive_id"
					part_2_data=''
				fi
			fi
			drive_data="${C1}$drive_type${counter}$SEP3${C2} $drive_string"
			calculate_line_length "$drive_data$part_2_data"
			if [[ $LINE_LENGTH -lt $COLS_INNER ]];then
				drive_data=$( create_print_line "$Line_Starter" "$drive_data$part_2_data" )
				print_screen_output "$drive_data"
				Line_Starter=' '
				drive_data=''
				part_2_data=''
			else
				calculate_line_length "$drive_data"
				if [[ $LINE_LENGTH -gt $COLS_INNER ]];then
					drive_data=$( create_print_line "$Line_Starter" "$drive_data" )
					print_screen_output "$drive_data"
					Line_Starter=' '
					drive_data=''
				fi
				calculate_line_length "$drive_data$part_2_data"
				if [[ $LINE_LENGTH -lt $COLS_INNER ]];then
					drive_data=$( create_print_line "$Line_Starter" "$drive_data$part_2_data" )
					print_screen_output "$drive_data"
					Line_Starter=' '
					part_2_data=''
					drive_data=''
				else
					drive_data=$( create_print_line "$Line_Starter" "$drive_data" )
					print_screen_output "$drive_data"
					drive_data=''
					Line_Starter=' '
					drive_data=$( create_print_line "$Line_Starter" "$part_2_data" )
					print_screen_output "$drive_data"
					Line_Starter=' '
					part_2_data=''
				fi
			fi
			
			# 5 - speed
			# 6 - multisession support
			# 7 - MCN support
			# 8 - audio read
			# 9 - cdr
			# 10 - cdrw
			# 11 - dvd read
			# 12 - dvdr
			# 13 - dvdram
			# 14 - state
			if [[ $B_SHOW_FULL_OPTICAL == 'true' && $b_floppy == 'false' ]];then
				if [[ -z ${a_drives[5]} ]];then
					speed='N/A'
				else
					speed="${a_drives[5]}$speed_string"
				fi
				if [[ -z ${a_drives[8]} ]];then
					audio='N/A'
				elif [[ ${a_drives[8]} == 1 ]];then
					audio='yes'
				else
					audio='no'
				fi
				audio="${C1}audio$SEP3${C2} $audio "
				if [[ -z ${a_drives[6]} ]];then
					multisession='N/A'
				elif [[ ${a_drives[6]} == 1 ]];then
					multisession='yes'
				else
					multisession='no'
				fi
				multisession="${C1}multisession$SEP3${C2} $multisession "
				if [[ -z ${a_drives[11]} ]];then
					dvd='N/A'
				elif [[ ${a_drives[11]} == 1 ]];then
					dvd='yes'
				else
					dvd='no'
				fi
				if [[ $B_EXTRA_DATA == 'true' ]];then
					if [[ -z ${a_drives[14]} ]];then
						state='N/A'
					else
						state="${a_drives[14]}"
					fi
					state="${C1}state$SEP3${C2} $state "
				fi
				if [[ -n ${a_drives[9]} && ${a_drives[9]} == 1 ]];then
					rw_support='cd-r'
					separator=','
				fi
				if [[ -n ${a_drives[10]} && ${a_drives[10]} == 1 ]];then
					rw_support="$rw_support${separator}cd-rw"
					separator=','
				fi
				if [[ -n ${a_drives[12]} && ${a_drives[12]} == 1 ]];then
					rw_support="$rw_support${separator}dvd-r"
					separator=','
				fi
				if [[ -n ${a_drives[13]} && ${a_drives[13]} == 1 ]];then
					rw_support="$rw_support${separator}dvd-ram"
					separator=','
				fi
				if [[ -z $rw_support ]];then
					rw_support='none'
				fi
				drive_data="${C1}Features: speed$SEP3${C2} $speed $multisession"
				part_2_data="$audio${C1}dvd$SEP3${C2} $dvd ${C1}rw$SEP3${C2} $rw_support $state"
				calculate_line_length "$drive_data$part_2_data"
				if [[ $LINE_LENGTH -lt $COLS_INNER ]];then
					drive_data=$( create_print_line "$Line_Starter" "$drive_data$part_2_data" )
					print_screen_output "$drive_data"
					Line_Starter=' '
				else
					drive_data=$( create_print_line "$Line_Starter" "$drive_data" )
					print_screen_output "$drive_data"
					drive_data=$( create_print_line "$Line_Starter" "$part_2_data" )
					print_screen_output "$drive_data"
					Line_Starter=' '
				fi
			fi
		done
	else
		:
	fi
	eval $LOGFE
}

print_partition_data()
{
	eval $LOGFS
	local a_part_working='' part_used='' partition_data=''
	local counter=0 i=0 part_id=0 a_part_data='' line_starter='' 
	local part_id_clean='' part_dev='' full_dev='' part_label='' full_label=''
	local part_uuid='' full_uuid='' dev_remote='' full_fs='' 
	local b_non_dev='false' holder='' id_size_used='' label_uuid='' fs_dev=''

	# set A_PARTITION_DATA
	get_partition_data

	for (( i=0; i < ${#A_PARTITION_DATA[@]}; i++ ))
	do
		IFS=","
		a_part_working=(${A_PARTITION_DATA[i]})
		IFS="$ORIGINAL_IFS"
		full_label=''
		full_uuid=''

		if [[ $B_SHOW_PARTITIONS_FULL == 'true' ]] || [[ ${a_part_working[4]} == 'main' ]];then
			if [[ -n ${a_part_working[2]} ]];then
				part_used="${C1}used$SEP3${C2} ${a_part_working[2]} (${a_part_working[3]}) "
			else
				part_used='' # reset partition used to null
			fi
			if [[ -n ${a_part_working[5]} ]];then
				full_fs="${a_part_working[5]}"
			else
				full_fs='N/A' # reset partition fs type
			fi
			full_fs="${C1}fs$SEP3${C2} $full_fs "
			if [[ -n ${a_part_working[6]} ]];then
				if [[ -z $( grep -E '(^//|:/|non-dev)' <<< ${a_part_working[6]} ) ]];then
					part_dev="/dev/${a_part_working[6]}"
					dev_remote='dev'
				elif [[ -n $( grep '^non-dev' <<< ${a_part_working[6]} ) ]];then
					holder=$( sed 's/non-dev-//' <<< ${a_part_working[6]} )
					part_dev="$holder"
					dev_remote='raid'
				else
					part_dev="${a_part_working[6]}"
					dev_remote='remote'
				fi
			else
				dev_remote='dev'
				part_dev='N/A'
			fi
			full_dev="${C1}$dev_remote$SEP3${C2} $part_dev "
			if [[ $B_SHOW_LABELS == 'true' || $B_SHOW_UUIDS == 'true' ]];then
				if [[ $B_SHOW_LABELS == 'true' && $dev_remote != 'remote' ]];then
					if [[ -n ${a_part_working[7]} ]];then
						part_label="${a_part_working[7]}"
					else
						part_label='N/A'
					fi
					full_label="${C1}label$SEP3${C2} $part_label "
				fi
				if [[ $B_SHOW_UUIDS == 'true' && $dev_remote != 'remote' ]];then
					if [[ -n ${a_part_working[8]} ]];then
						part_uuid="${a_part_working[8]}"
					else
						part_uuid='N/A'
					fi
					full_uuid="${C1}uuid$SEP3${C2} $part_uuid"
				fi
			fi
			# don't show user names in output
			if [[ $B_OUTPUT_FILTER == 'true' ]];then
				part_id_clean=$( sed $SED_RX "s|/home/([^/]+)/(.*)|/home/$FILTER_STRING/\2|" <<< ${a_part_working[0]} )
			else
				part_id_clean=${a_part_working[0]}
			fi
			id_size_used="${C1}ID-$((part_id+1))$SEP3${C2} $part_id_clean ${C1}size$SEP3${C2} ${a_part_working[1]} $part_used"
			fs_dev="$full_fs$full_dev"
			label_uuid="$full_label$full_uuid"
			calculate_line_length "${a_part_data[$counter]}$id_size_used$fs_dev"
			if [[ $LINE_LENGTH -gt $COLS_INNER ]];then
				a_part_data[$counter]="$id_size_used"
				((counter++))
				calculate_line_length "$fs_dev$label_uuid"
				if [[ $LINE_LENGTH -le $COLS_INNER ]];then
					a_part_data[$counter]="$fs_dev$label_uuid"
					label_uuid=''
				else
					a_part_data[$counter]="$fs_dev"
				fi
				((counter++))
				id_size_used=''
				fs_dev=''
			fi
			# label/uuid always print one per line, so only wrap if it's very long
			calculate_line_length "${a_part_data[$counter]}$id_size_used$fs_dev$label_uuid"
			if [[ $B_SHOW_UUIDS == 'true' || $B_SHOW_LABELS == 'true' ]] && \
			   [[ $LINE_LENGTH -gt $COLS_INNER ]];then
				a_part_data[$counter]="$id_size_used$fs_dev"
				((counter++))
				a_part_data[$counter]="$label_uuid"
			else
				if [[ $LINE_LENGTH -gt $COLS_INNER ]];then
					a_part_data[$counter]="${a_part_data[$counter]}"
					((counter++))
					a_part_data[$counter]="$id_size_used$fs_dev$label_uuid"
				else
					a_part_data[$counter]="${a_part_data[$counter]}$id_size_used$fs_dev$label_uuid"
				fi
			fi
			((counter++))
			((part_id++))
		fi
	done
	# print out all lines, line starter on first line
	for (( i=0; i < ${#a_part_data[@]};i++ ))
	do
		if [[ $i -eq 0 ]];then
			line_starter='Partition:'
		else
			line_starter=' '
		fi
		if [[ -n ${a_part_data[$i]} ]];then
			partition_data=$( create_print_line "$line_starter" "${a_part_data[$i]}" )
			print_screen_output "$partition_data"
		fi
	done
	
	eval $LOGFE
}
# legacy not used
print_program_version()
{
	local program_version="${C1}$SELF_NAME$SEP3${C2} $SELF_VERSION$SELF_PATCH${CN}"
	# great trick from: http://ideatrash.net/2011/01/bash-string-padding-with-sed.html
	# left pad: sed -e :a -e 's/^.\{1,80\}$/& /;ta'
	# right pad: sed -e :a -e 's/^.\{1,80\}$/ &/;ta'
	# center pad: sed -e :a -e 's/^.\{1,80\}$/ & /;ta'
	#local line_max=$COLS_INNER
	#program_version="$( sed -e :a -e "s/^.\{1,$line_max\}$/ &/;ta" <<< $program_version )" # use to create padding if needed
	# program_version=$( create_print_line "Version:" "$program_version${CN}" )
	print_screen_output "$program_version"
}

print_ps_data()
{
	eval $LOGFS
	
	local b_print_first='true' 

	if [[ $B_SHOW_PS_CPU_DATA == 'true' ]];then
		get_ps_tcm_data 'cpu'
		print_ps_item 'cpu' "$b_print_first"
		b_print_first='false' 
	fi
	if [[ $B_SHOW_PS_MEM_DATA == 'true' ]];then
		get_ps_tcm_data 'mem'
		print_ps_item 'mem' "$b_print_first"
	fi
	
	eval $LOGFE
}

# args: $1 - cpu/mem; $2 true/false
print_ps_item()
{
	eval $LOGFS
	local a_ps_data='' ps_data='' line_starter='' line_start_data='' full_line=''
	local app_name='' app_pid='' app_cpu='' app_mem='' throttled='' app_daemon=''
	local b_print_first=$2 line_counter=0 i=0 count_nu='' extra_data='' memory_info='' extra_text=''
	
	if [[ -n $PS_THROTTLED ]];then
		throttled=" ${C1} - throttled from${C2} $PS_THROTTLED"
	fi
	# important: ${C2} $PS_COUNT must have space after ${C2} for irc output or the number vanishes
	case $1 in
		cpu)
			if [[  $B_EXTRA_DATA == 'true' ]];then
				extra_text=" ${C1}- Memory$SEP3 MB / % used"
				if [[ $B_SHOW_INFO == 'false' && $B_SHOW_PS_MEM_DATA == 'false' ]];then
					get_memory_data
					memory_info=" - ${C1}Used/Total$SEP3${C2} $MEMORY"
				fi
			fi
			line_start_data="${C1}CPU$SEP3 % used$extra_text$memory_info${C1} - top${C2} $PS_COUNT ${C1}active$throttled"
			;;
		mem)
			if [[  $B_EXTRA_DATA == 'true' ]];then
				extra_text=" ${C1}- CPU$SEP3 % used"
			fi
			if [[ $B_SHOW_INFO == 'false' ]];then
				get_memory_data
				memory_info=" - ${C1}Used/Total$SEP3${C2} $MEMORY"
			fi
			line_start_data="${C1}Memory$SEP3 MB / % used$memory_info$extra_text${C1} - top${C2} $PS_COUNT ${C1}active$throttled"
			;;
	esac
	
	if [[ $b_print_first == 'true' ]];then
		line_starter='Processes:'
	else
		line_starter=' '
	fi
	
	# appName, appPath, appStarterName, appStarterPath, cpu, mem, pid, vsz, user
	ps_data=$( create_print_line "$line_starter" "$line_start_data" )
	print_screen_output "$ps_data"

	for (( i=0; i < ${#A_PS_DATA[@]}; i++ ))
	do
		IFS=","
		a_ps_data=(${A_PS_DATA[i]})
		IFS="$ORIGINAL_IFS"
		
		# handle the converted app names, with ~..~ means it didn't have a path
		if [[ -n $( grep -E '^~.*~$' <<<  ${a_ps_data[0]} ) ]];then
			app_daemon='daemon'
		else
			app_daemon='command'
		fi

		app_name=" ${C1}$app_daemon$SEP3${C2} ${a_ps_data[0]}"
		if [[ ${a_ps_data[0]} != ${a_ps_data[2]} ]];then
			app_name="$app_name ${C1}(started by$SEP3${C2} ${a_ps_data[2]}${C1})${C2}"
		fi
		app_pid=" ${C1}pid$SEP3${C2} ${a_ps_data[6]}"
		#  ${C1}user$SEP3${C2} ${a_ps_data[8]}
		case $1 in
			cpu)
				app_cpu=" ${C1}cpu$SEP3${C2} ${a_ps_data[4]}%"
				if [[ $B_EXTRA_DATA == 'true' ]];then
					extra_data=" ${C1}mem$SEP3${C2} ${a_ps_data[7]}MB (${a_ps_data[5]}%)${C2}"
				fi
				;;
			mem)
				app_mem=" ${C1}mem$SEP3${C2} ${a_ps_data[7]}MB (${a_ps_data[5]}%)${C2}"
				if [[ $B_EXTRA_DATA == 'true' ]];then
					extra_data=" ${C1}cpu$SEP3${C2} ${a_ps_data[4]}%"
				fi
				;;
		esac
		(( line_counter++ ))
		count_nu="${C1}$line_counter$SEP3${C2}"
		full_line="$count_nu$app_cpu$app_mem$app_name$app_pid$extra_data"
		ps_data=$( create_print_line " " "$full_line" )
		print_screen_output "$ps_data"
	done
	
	eval $LOGFE
}

print_raid_data()
{
	eval $LOGFS
	local device='' device_string='' device_state='' raid_level='' device_components=''
	local device_report='' u_data='' blocks='' super_blocks='' algorithm='' chunk_size=''
	local bitmap_values='' recovery_progress_bar='' recovery_percent='' recovered_sectors=''
	local finish_time='' recovery_speed='' raid_counter=0 device_counter=1 basic_counter=1
	local a_raid_working='' raid_data='' kernel_support='' read_ahead='' unused_devices=''
	local basic_raid='' basic_raid_separator='' basic_raid_plural='' inactive=''
	local component_separator='' device_id='' print_string='' loop_limit=0 array_count_unused=''
	local array_count='' raid_event='' b_print_lines='true'
	local no_raid_detected='' dev_string='/dev/'
	local empty_raid_data='' report_size='report' blocks_avail='blocks' chunk_raid_usage='chunk size'
	
	if [[ -n $BSD_TYPE ]];then
		no_raid_detected='No zfs software RAID detected-other types not yet supported.'
		empty_raid_data='No zfs RAID data available-other types not yet supported.'
		report_size='size'
		blocks_avail='available'
		chunk_raid_usage='allocated'
	else
		no_raid_detected="No RAID data: $FILE_MDSTAT missing-is md_mod kernel module loaded?"
		empty_raid_data="No RAID devices: $FILE_MDSTAT, md_mod kernel module present"
	fi
	
	if [[ $BSD_TYPE == 'bsd' ]];then
		dev_string=''
	fi
	if [[ $B_RAID_SET != 'true' ]];then
		get_raid_data
	fi

	for (( i=0; i < ${#A_RAID_DATA[@]}; i++ ))
	do
		IFS=","
		a_raid_working=(${A_RAID_DATA[i]})
		IFS="$ORIGINAL_IFS"
		
		# reset on each iteration
		algorithm=''
		bitmap_values=''
		blocks=''
		component_separator=''
		device=''
		device_components=''
		device_id=''
		device_report=''
		device_state=''
		failed=''
		finish_time=''
		inactive=''
		raid_event=''
		raid_level=''
		recovery_percent=''
		recovery_progress_bar=''
		recovered_sectors=''
		recovery_speed=''
		spare=''
		super_blocks=''
		u_data=''
		
		if [[ -n $( grep '^md' <<< ${a_raid_working[0]} ) && -z $BSD_TYPE ]] || \
		[[ -n $BSD_TYPE && ${a_raid_working[0]} != '' ]];then
			if [[ $B_SHOW_BASIC_RAID == 'true' ]];then
				if [[ $basic_raid != '' ]];then
					basic_raid_plural='s'
				fi
				if [[ ${a_raid_working[1]} == 'inactive' ]];then
					inactive=" - ${a_raid_working[1]}"
				fi
				basic_raid="$basic_raid$basic_raid_separator${C1}$basic_counter$SEP3${C2} $dev_string${a_raid_working[0]}$inactive"
				basic_raid_separator=' '
				(( basic_counter++ ))
			else
				device_id="-$device_counter"
				device="$dev_string${a_raid_working[0]}"
				
				(( device_counter++ ))
				if [[ ${a_raid_working[1]} != '' ]];then
					device_state=" - ${a_raid_working[1]}"
				fi
				
				if [[ ${a_raid_working[2]} == '' ]];then
					raid_level='N/A'
				else
					raid_level=${a_raid_working[2]}
				fi
				# there's one case: md0 : inactive  that has to be protected against
				if [[ ${a_raid_working[2]} == '' && ${a_raid_working[1]} == 'inactive' ]];then
					raid_level=''
				else
					raid_level=" ${C1}raid$SEP3${C2} $raid_level"
				fi
				if [[ ${a_raid_working[4]} != '' ]];then
					device_report="${a_raid_working[4]}"
				else
					device_report="N/A"
				fi
				if [[ $B_EXTRA_DATA == 'true' ]];then
					if [[ ${a_raid_working[6]} != '' ]];then
						blocks=${a_raid_working[6]}
					else
						blocks='N/A'
					fi
					blocks=" ${C1}$blocks_avail$SEP3${C2} $blocks"
					
					if [[ ${a_raid_working[9]} != '' ]];then
						chunk_size=${a_raid_working[9]}
					else
						chunk_size='N/A'
					fi
					chunk_size=" ${C1}$chunk_raid_usage$SEP3${C2} $chunk_size"
					if [[ ${a_raid_working[10]} != '' ]];then
						bitmap_value='true'
						bitmap_value=" ${C1}bitmap$SEP3${C2} $bitmap_value"
					fi
				fi
				if [[ $B_EXTRA_EXTRA_DATA == 'true' ]];then
					if [[ ${a_raid_working[5]} != '' ]];then
						u_data=" ${a_raid_working[5]}"
					fi
					if [[ ${a_raid_working[7]} != '' ]];then
						super_blocks=" ${C1}super blocks$SEP3${C2} ${a_raid_working[7]}"
					fi
					if [[ ${a_raid_working[8]} != '' ]];then
						algorithm=" ${C1}algorithm$SEP3${C2} ${a_raid_working[8]}"
					fi
				fi
				if [[ ${a_raid_working[3]} == '' ]];then
					if [[ ${a_raid_working[1]} != 'inactive' ]];then
						device_components=" ${C1}components$SEP3${C2} N/A"
					fi
				else
					for component in ${a_raid_working[3]}
					do
						if [[ $B_EXTRA_DATA != 'true' ]];then
							component=$( sed 's/\[[0-9]\+\]//' <<< $component )
						fi
						# NOTE: for bsd zfs, states are: ONLINE,DEGRADED,OFFLINE (at least)
						if [[ -n $( grep -E '(F|DEGRADED)' <<< $component ) ]];then
							component=$( sed -e 's/(F)//' -e 's/F//' -e 's/DEGRADED//' <<<  $component )
							failed="$failed $component"
							component=''
						elif [[ -n $( grep -E '(S|OFFLINE)' <<< $component ) ]];then
							component=$( sed -e 's/(S)//' -e 's/S//' -e 's/OFFLINE//' <<<  $component )
							spare="$spare $component"
							component=''
						else
							device_components="$device_components$component_separator$component"
							component_separator=' '
						fi
					done
					if [[ $failed != '' ]];then
						failed=" ${C1}FAILED$SEP3${C2}$failed${C2}"
					fi
					if [[ $spare != '' ]];then
						spare=" ${C1}spare$SEP3${C2}$spare${C2}"
					fi
					if [[ -n $device_components || -n $spare || -n $failed ]];then
						if [[ $B_EXTRA_DATA != 'true' && -z $BSD_TYPE ]];then
							if [[ $device_report != 'N/A' && -n $device_components ]];then
								device_components="$device_report - $device_components"
							fi
						fi
						if [[ $device_components == '' ]];then
							device_components='none'
						fi
						device_components="${C1}online$SEP3${C2} $device_components"
						device_components=" ${C1}components$SEP3${C2} $device_components$failed$spare"
					fi
				fi
				a_raid_data[$raid_counter]="${C1}Device$device_id$SEP3${C2} $device$device_state$raid_level$device_components"
				
				if [[ $B_EXTRA_DATA == 'true' && ${a_raid_working[1]} != 'inactive' ]];then
					a_raid_data[$raid_counter]="${C1}Device$device_id$SEP3${C2} $device$device_state$device_components"
					(( raid_counter++ ))
					print_string="${C1}Info$SEP3${C2}$raid_level ${C1}$report_size$SEP3${C2} $device_report$u_data"
					print_string="$print_string$blocks$chunk_size$bitmap_value$super_blocks$algorithm"
					a_raid_data[$raid_counter]="$print_string"
				else
					a_raid_data[$raid_counter]="${C1}Device$device_id$SEP3${C2} $device$device_state$raid_level$device_components"
				fi
				(( raid_counter++ ))
				
				# now let's do the recover line if required
				if [[ ${a_raid_working[12]} != '' ]];then
					recovery_percent=$( cut -d '~' -f 2 <<< ${a_raid_working[12]} )
					if [[ ${a_raid_working[14]} != '' ]];then
						finish_time=${a_raid_working[14]}
					else
						finish_time='N/A'
					fi
					finish_time=" ${C1}time remaining$SEP3${C2} $finish_time"
					if [[ $B_EXTRA_DATA == 'true' ]];then
						if [[ ${a_raid_working[13]} != '' ]];then
							recovered_sectors=" ${C1}sectors$SEP3${C2} ${a_raid_working[13]}"
						fi
					fi
					if [[ $B_EXTRA_EXTRA_DATA == 'true' ]];then
						if [[ ${a_raid_working[11]} != '' ]];then
							recovery_progress_bar=" ${a_raid_working[11]}"
						fi
						if [[ ${a_raid_working[15]} != '' ]];then
							recovery_speed=" ${C1}speed$SEP3${C2} ${a_raid_working[15]}"
						fi
					fi
					a_raid_data[$raid_counter]="${C1}Recovering$SEP3${C2} $recovery_percent$recovery_progress_bar$recovered_sectors$finish_time$recovery_speed"
					(( raid_counter++ ))
				fi
			fi
		elif [[ ${a_raid_working[0]} == 'KernelRaidSupport' ]];then
			if [[ ${a_raid_working[1]} == '' ]];then
				kernel_support='N/A'
			else
				kernel_support=${a_raid_working[1]}
			fi
			kernel_support=" ${C1}supported$SEP3${C2} $kernel_support"
		elif [[ ${a_raid_working[0]} == 'ReadAhead' ]];then
			if [[ ${a_raid_working[1]} != '' ]];then
				read_ahead=${a_raid_working[1]}
				read_ahead=" ${C1}read ahead$SEP3${C2} $read_ahead"
			fi
		elif [[ ${a_raid_working[0]} == 'UnusedDevices' ]];then
			if [[ ${a_raid_working[1]} == '' ]];then
				unused_devices='N/A'
			else
				unused_devices=${a_raid_working[1]}
			fi
			unused_devices="${C1}Unused Devices$SEP3${C2} $unused_devices"
		elif [[ ${a_raid_working[0]} == 'raidEvent' ]];then
			if [[ ${a_raid_working[1]} != '' ]];then
				raid_event=${a_raid_working[1]}
				raid_event=" ${C1}Raid Event$SEP3${C2} ${a_raid_working[1]}"
			fi
		fi
	done
	
	if [[ $B_SHOW_BASIC_RAID == 'true' && $basic_raid != '' ]];then
		a_raid_data[0]="${C1}Device$basic_raid_plural$SEP3${C2} $basic_raid"
	fi
	# note bsd temp test hack to make it run
	if [[ $B_MDSTAT_FILE != 'true' && -z $BSD_TYPE ]] || \
	[[ -n $BSD_TYPE && $B_BSD_RAID == 'false' ]];then
		if [[ $B_SHOW_RAID_R == 'true' ]];then
			a_raid_data[0]="$no_raid_detected"
		else
			b_print_lines='false'
		fi
	else
		if [[ ${a_raid_data[0]} == '' ]];then
			if [[ $B_SHOW_BASIC_RAID != 'true' ]];then
				a_raid_data[0]="$empty_raid_data"
			else
				b_print_lines='false'
			fi
		fi
		# now let's add on the system line and the unused device line. Only print on -xx
		if [[ $kernel_support$read_ahead$raid_event != '' ]];then
			array_count=${#a_raid_data[@]}
			a_raid_data[array_count]="${C1}System$SEP3${C2}$kernel_support$read_ahead$raid_event"
			loop_limit=1
		fi
		if [[ $unused_devices != '' ]];then
			array_count_unused=${#a_raid_data[@]}
			a_raid_data[array_count_unused]="$unused_devices"
			loop_limit=2
		fi
	fi

	# we don't want to print anything if it's -b and no data is present, just a waste of a line
	if [[ $b_print_lines == 'true' ]];then
		# print out all lines, line starter on first line
		for (( i=0; i < ${#a_raid_data[@]} - $loop_limit;i++ ))
		do
			if [[ $i -eq 0 ]];then
				line_starter='RAID:'
			else
				line_starter=' '
			fi
			if [[ $B_EXTRA_EXTRA_DATA == 'true' && $array_count != '' ]];then
				if [[ $i == 0 ]];then
					raid_data=$( create_print_line "$line_starter" "${a_raid_data[array_count]}" )
					print_screen_output "$raid_data"
					line_starter=' '
				fi
			fi
			raid_data=$( create_print_line "$line_starter" "${a_raid_data[i]}" )
			print_screen_output "$raid_data"
			if [[ $B_EXTRA_EXTRA_DATA == 'true' && $array_count_unused != '' ]];then
				if [[ $i == $(( array_count_unused - 2 )) ]];then
					raid_data=$( create_print_line "$line_starter" "${a_raid_data[array_count_unused]}" )
					print_screen_output "$raid_data"
				fi
			fi
		done
	fi
	
	eval $LOGFE
}

print_ram_data()
{
	eval $LOGFS
	local memory_line='' line_2='' line_3='' b_module_present='true'
	local error_string='' a_memory_item='' line_starter='Memory:' array_counter=1 device_counter=1
	local dmidecodeNull='No dmidecode memory data: try newer kernel.'
	
	local manufacturer='' part_nu='' serial_nu='' device_speed='' configured_speed='' bus_width=
	local data_width='' total_width='' device_type='' device_type_detail='' bank='' slot='' form_factor=''
	local device_size='' array_use='' location='' error_correction='' max_capacity='' nu_of_devices=''
	local max_module_size='' module_voltage='' bank_connection='' memory_info=''
	
	get_ram_data
	#echo ${#A_MEMORY_DATA[@]}
	#echo ${A_MEMORY_DATA[0]}
	if [[ ${#A_MEMORY_DATA[@]} -gt 0 ]];then
		if [[ ${A_MEMORY_DATA[0]} == 'dmidecode-error-'* ]];then
			error_string=$( print_dmidecode_error 'default' "${A_MEMORY_DATA[0]}" )
			memory_line="${C2}$error_string"
		else
			if [[ $B_SHOW_INFO == 'false' && $B_SHOW_PS_MEM_DATA == 'false' ]];then
				get_memory_data
				memory_info="${C1}Used/Total$SEP3${C2} $MEMORY"
			fi
			for (( i=0;i<${#A_MEMORY_DATA[@]};i++ ))
			do
				IFS=','
				a_memory_item=(${A_MEMORY_DATA[i]})
				IFS="$ORIGINAL_IFS"
				memory_line=''
				line_2=''
				line_3=''
				bus_width=''
				data_width=
				total_width=
				part_nu=''
				serial_nu=''
				manufacturer=''
				max_module_size='' 
				module_voltage=''
				bank_connection=''
				if [[ -n $memory_info ]];then
					memory_line=$( create_print_line "$line_starter" "$memory_info" )
					print_screen_output "$memory_line"
					line_starter=''
					memory_info=''
				fi
				# memory-array,0x0012,System Board,8 GB,4,System Memory,None,max size,moudule voltage
				if [[ ${a_memory_item[0]} == 'memory-array' ]];then
					if [[ -n ${a_memory_item[4]} ]];then
						nu_of_devices=${a_memory_item[4]}
					else
						nu_of_devices='N/A'
					fi
					if [[ -n ${a_memory_item[3]} ]];then
						max_capacity=${a_memory_item[3]}
					else
						max_capacity='N/A'
					fi
					if [[ -n ${a_memory_item[6]} ]];then
						error_correction=${a_memory_item[6]}
					else
						error_correction='N/A'
					fi
					if [[ $B_EXTRA_DATA == 'true' ]];then
						if [[ -n ${a_memory_item[7]} ]];then
							max_module_size="${C1}max module size${SEP3}${C2} ${a_memory_item[7]} "
						fi
					fi
					if [[ $B_EXTRA_EXTRA_EXTRA_DATA == 'true' ]];then
						if [[ -n ${a_memory_item[8]} ]];then
							module_voltage="${C1}module voltage$SEP3${C2} ${a_memory_item[8]}"
						fi
					fi
					memory_line="${C1}Array-$array_counter capacity$SEP3${C2} $max_capacity ${C1}devices$SEP3${C2} $nu_of_devices ${C1}EC$SEP3${C2} $error_correction "
					line_2="$max_module_size$module_voltage"
					calculate_line_length "$memory_line$line_2"
					if [[ -n $line_2 && $LINE_LENGTH -gt $COLS_INNER ]];then
						memory_line=$( create_print_line "$line_starter" "$memory_line" )
						print_screen_output "$memory_line"
						memory_line="$line_2"
						line_starter=' '
						line_2=''
					else
						memory_line="$memory_line$line_2"
						line_2=''
					fi
					(( array_counter++ ))
					device_counter=1 # reset so device matches device count per array
				else
					# not used for now
# 					if [[ -n ${a_memory_item[3333]} ]];then
# 						if [[ -z ${a_memory_item[3]/BANK*/} ]];then
# 							#bank=${a_memory_item[3]#BANK}
# 							bank=${a_memory_item[3]}
# 							bank=${bank## }
# 						else
# 							bank=${a_memory_item[3]}
# 						fi
# 					else
# 						bank='N/A'
# 					fi
# 					# not used for now
# 					if [[ -n ${a_memory_item[44444]} ]];then
# 						if [[ -z ${a_memory_item[4]/SLOT*/} ]];then
# 							#slot=${a_memory_item[4]#SLOT}
# 							slot=${a_memory_item[4]}
# 							slot=${slot## }
# 						else
# 							slot=${a_memory_item[4]}
# 						fi
# 					else
# 						slot='N/A'
# 					fi
					if [[ -n ${a_memory_item[15]} ]];then
						locator=${a_memory_item[15]}
						locator=${locator## }
					else
						locator='N/A'
					fi
					if [[ -n ${a_memory_item[2]} ]];then
						device_size=${a_memory_item[2]}
						if [[ $device_size == 'No Module Installed' ]];then
							b_module_present='false'
						else
							b_module_present='true'
						fi
					else
						device_size='N/A'
					fi
					if [[ -n ${a_memory_item[6]} ]];then
						device_type=${a_memory_item[6]}
						if [[ $B_EXTRA_EXTRA_EXTRA_DATA == 'true' && -n ${a_memory_item[7]} \
						      && ${a_memory_item[7]} != 'Other' ]];then
							device_type="$device_type (${a_memory_item[7]})"
						fi
					else
						device_type='N/A'
					fi
					device_type="${C1}type$SEP3${C2} $device_type "
					if [[ -n ${a_memory_item[8]} ]];then
						if [[ -n ${a_memory_item[9]} ]];then
							device_speed=${a_memory_item[9]}
						else
							device_speed=${a_memory_item[8]}
						fi
					else
						device_speed='N/A'
					fi
					if [[ $b_module_present == 'true' ]];then
						device_speed="${C1}speed$SEP3${C2} $device_speed "
					else
						device_speed=''
					fi
					# memory-device,0x002C,8192 MB,ChannelD,ChannelD_Dimm2,DIMM,DDR3,Synchronous,2400 MHz,2400 MHz,64 bits,64 bits,Undefined,F3-19200C10-8GBZH,00000000
					if [[ $b_module_present == 'true' ]];then
						if [[ $B_EXTRA_DATA == 'true' ]];then
							if [[ -n ${a_memory_item[13]} ]];then
								part_nu=${a_memory_item[13]}
							else
								part_nu='N/A'
							fi
							part_nu="${C1}part$SEP3${C2} $part_nu "
						fi
						if [[ $B_EXTRA_EXTRA_DATA == 'true' ]];then
							if [[ -n ${a_memory_item[12]} ]];then
								manufacturer=${a_memory_item[12]}
							else
								manufacturer='N/A' 
							fi
							manufacturer="${C1}manufacturer$SEP3${C2} $manufacturer "
							if [[ -n ${a_memory_item[14]} ]];then
								if [[ $B_OUTPUT_FILTER == 'true' ]];then
									serial_nu=$FILTER_STRING
								else
									serial_nu=${a_memory_item[14]}
								fi
							else
								serial_nu='N/A'
							fi
							serial_nu="${C1}serial$SEP3${C2} $serial_nu "
							if [[ $device_size != 'N/A' && -n ${a_memory_item[16]} ]];then
								bank_connection=" ${a_memory_item[16]}"
							fi
						fi
					fi
					if [[ $B_EXTRA_EXTRA_EXTRA_DATA == 'true' ]];then
						if [[ $b_module_present == 'true' ]] || \
						     [[ -n ${a_memory_item[11]} || -n ${a_memory_item[10]} ]];then
							# only create this if the total exists and is > data width
							if [[ -n ${a_memory_item[10]/ bits/} && -n ${a_memory_item[11]/ bits} && \
							      ${a_memory_item[11]/ bits/} -gt ${a_memory_item[10]/ bits/} ]];then
								total_width=" (total$SEP3 ${a_memory_item[11]})"
							fi
							if [[ -n ${a_memory_item[10]} ]];then
								data_width=${a_memory_item[10]}
							else
								data_width='N/A'
							fi
							bus_width="${C1}bus width$SEP3${C2} $data_width$total_width "
						fi
					fi
					memory_line="${C1}Device-$device_counter$SEP3${C2} $locator ${C1}size$SEP3${C2} $device_size$bank_connection $device_speed"
					calculate_line_length "$memory_line$device_type"
					if [[ $LINE_LENGTH -le $COLS_INNER ]];then
						memory_line="$memory_line$device_type"
						device_type=''
					fi
					line_3="$manufacturer$part_nu$serial_nu"
					line_2="$device_type$bus_width"
					# echo $( calculate_line_length "$memory_line" )
					# echo $( calculate_line_length "$memory_line$line_2" )
					calculate_line_length "$memory_line$line_2$line_3"
					if [[ $LINE_LENGTH -gt $COLS_INNER ]];then
						memory_line=$( create_print_line "$line_starter" "$memory_line" )
						print_screen_output "$memory_line"
						memory_line="$line_2"
						line_starter=' '
						calculate_line_length "$memory_line$line_3"
						if [[ -n $memory_line && -n $line_3 && $LINE_LENGTH -gt $COLS_INNER ]];then
							memory_line=$( create_print_line "$line_starter" "$memory_line" )
							print_screen_output "$memory_line"
							memory_line="$line_3"
						else
							memory_line="$memory_line$line_3"
						fi
					else
						memory_line="$memory_line$line_2$line_3"
					fi
					(( device_counter++ ))
				fi
				memory_line=$( create_print_line "$line_starter" "$memory_line" )
				print_screen_output "$memory_line"
				line_starter=' '
			done
			memory_line=' '
		fi
	else
		memory_line="${C2}$dmidecodeNull"
	fi
	IFS="$ORIGINAL_IFS"
	memory_line=${memory_line## }
	if [[ -n $memory_line ]];then
		memory_line=$( create_print_line "$line_starter" "$memory_line" )
		print_screen_output "$memory_line"
	fi

	eval $LOGFE
}


# currently only apt using distros support this feature, but over time we can add others
print_repo_data()
{
	eval $LOGFS
	local repo_count=0 repo_line='' file_name='' file_content='' file_name_holder=''
	local repo_full='' b_print_next_line='false' repo_type=''
	
	get_repo_data
	
	if [[ -n $REPO_DATA ]];then
		# loop through the variable's lines one by one, update counter each iteration
		while read repo_line
		do
			(( repo_count++ ))
			repo_type=$( cut -d '^' -f 1 <<< $repo_line )
			file_name=$( cut -d '^' -f 2 <<< $repo_line )
			file_content=$( cut -d '^' -f 3-7 <<< $repo_line )
			# this will dump unwanted white space line starters. Some irc channels
			# use bots that show page title for urls, so need to break the url by adding 
			# a white space.
			if [[ $B_IRC == 'true' ]];then
				file_content=$( echo ${file_content/:\/\//: \/\/} )
			else
				file_content=$( echo $file_content )
			fi
			# echo $file_name : $file_name_holder : $repo_type : $file_content
			# check file name, if different, update the holder for print out
			if [[ $file_name != $file_name_holder ]];then
				if [[ $repo_type == 'pisi repo' || $repo_type == 'urpmq repo' ]];then
					repo_full="${C1}$repo_type$SEP3${C2} $file_name"
				else
					repo_full="${C1}Active $repo_type in file$SEP3${C2} $file_name"
				fi
				file_name_holder=$file_name
				b_print_next_line='true'
			else
				repo_full="${C2}$file_content"
			fi
			# first line print Repos: 
			if [[ $repo_count -eq 1 ]];then
				repo_full=$( create_print_line "Repos:" "$repo_full" )
			else
				repo_full=$( create_print_line " " "$repo_full" )
			fi
			print_screen_output "$repo_full"
			# this prints the content of the file as well as the file name
			if [[ $b_print_next_line == 'true' ]];then
				repo_full=$( create_print_line " " "$file_content" )
				print_screen_output "$repo_full"
				b_print_next_line='false'
			fi
		done <<< "$REPO_DATA"
	else
		if [[ $BSD_TYPE == 'bsd' ]];then
			repo_type='OS type'
		else
			repo_type="package manager"
		fi
		repo_full=$( create_print_line "Repos:" "${C1}Error$SEP3${C2} No repo data detected. Does $SELF_NAME support your $repo_type?" )
		print_screen_output "$repo_full"
	fi
	eval $LOGFE
}

print_sensors_data()
{
	eval $LOGFS
	local mobo_temp='' cpu_temp='' psu_temp='' cpu_fan='' mobo_fan='' ps_fan='' sys_fans='' sys_fans2='' 
	local temp_data='' fan_data='' fan_data2='' b_is_error='false' fan_count=0 gpu_temp=''
	local a_sensors_working=''
	local no_sensors_message='None detected - is lm-sensors installed and configured?'
	local Sensors_Data="$( get_sensors_output )"
	get_sensors_data
	
	if [[ $BSD_TYPE == 'bsd' ]];then
		no_sensors_message='This feature is not yet supported for BSD systems.'
	fi
	
	IFS=","
	a_sensors_working=( ${A_SENSORS_DATA[0]} )
	IFS="$ORIGINAL_IFS"
	# initial error cases, for missing app or unconfigured sensors. Note that array 0
	# always has at least 3 items, cpu/mobo/psu temp in it. If the count is 0, then
	# no sensors are installed/configured
	if [[ ${#a_sensors_working[@]} -eq 0 ]];then
		cpu_temp=$no_sensors_message
		b_is_error='true'
	else
		for (( i=0; i < ${#A_SENSORS_DATA[@]}; i++ ))
		do
			IFS=","
			a_sensors_working=( ${A_SENSORS_DATA[i]} )
			IFS="$ORIGINAL_IFS"
			case $i in
				# first the temp data
				0)
					if [[ -n ${a_sensors_working[0]} ]];then
						cpu_temp=${a_sensors_working[0]}
					else
						cpu_temp='N/A'
					fi
					cpu_temp="${C1}System Temperatures: cpu$SEP3${C2} $cpu_temp "

					if [[ -n ${a_sensors_working[1]} ]];then
						mobo_temp=${a_sensors_working[1]}
					else
						mobo_temp='N/A'
					fi
					mobo_temp="${C1}mobo$SEP3${C2} $mobo_temp "

					if [[ -n ${a_sensors_working[2]} ]];then
						psu_temp="${C1}psu$SEP3${C2} ${a_sensors_working[2]} "
					fi
					gpu_temp=$( get_gpu_temp_data )
					# dump the unneeded screen data for single gpu systems 
					if [[ $( wc -w <<< $gpu_temp ) -eq 1 && $B_EXTRA_DATA != 'true' ]];then
						gpu_temp=${gpu_temp#*:}
					fi
					if [[ -n $gpu_temp ]];then
						gpu_temp="${C1}gpu$SEP3${C2} $gpu_temp "
					fi
					;;
				# then the fan data from main fan array
				1)
					for (( j=0; j < ${#a_sensors_working[@]}; j++ ))
					do
						case $j in
							0)
								# we need to make sure it's either cpu fan OR cpu fan and sys fan 1
								if [[ -n ${a_sensors_working[0]} ]];then
									cpu_fan="${a_sensors_working[0]}"
								elif [[ -z ${a_sensors_working[0]} && -n ${a_sensors_working[1]} ]];then
									cpu_fan="${a_sensors_working[1]}"
								else
									cpu_fan='N/A'
								fi
								cpu_fan="${C1}Fan Speeds (in rpm): cpu$SEP3${C2} $cpu_fan "
								(( fan_count++ ))
								;;
							1)
								if [[ -n ${a_sensors_working[1]} ]];then
									mobo_fan="${C1}mobo$SEP3${C2} ${a_sensors_working[1]} "
									(( fan_count++ ))
								fi
								;;
							2)
								if [[ -n ${a_sensors_working[2]} ]];then
									ps_fan="${C1}psu$SEP3${C2} ${a_sensors_working[2]} "
									(( fan_count++ ))
								fi
								;;
							[3-9]|[1-9][0-9])
								if [[ -n ${a_sensors_working[$j]} ]];then
									fan_number=$(( $j - 2 )) # sys fans start on array key 5
									# wrap after fan 6 total
									if [[ $fan_count -lt 7 ]];then
										sys_fans="$sys_fans${C1}sys-$fan_number$SEP3${C2} ${a_sensors_working[$j]} "
									else
										sys_fans2="$sys_fans2${C1}sys-$fan_number$SEP3${C2} ${a_sensors_working[$j]} "
									fi
									(( fan_count++ ))
								fi
								;;
						esac
					done
					;;
				2)
					for (( j=0; j < ${#a_sensors_working[@]}; j++ ))
					do
						case $j in
							[0-9]|[1-9][0-9])
								if [[ -n ${a_sensors_working[$j]} ]];then
									fan_number=$(( $j + 1 )) # sys fans start on array key 5
									# wrap after fan 6 total
									if [[ $fan_count -lt 7 ]];then
										sys_fans="$sys_fans${C1}fan-$fan_number$SEP3${C2} ${a_sensors_working[$j]} "
									else
										sys_fans2="$sys_fans2${C1}fan-$fan_number$SEP3${C2} ${a_sensors_working[$j]} "
									fi
									(( fan_count++ ))
								fi
								;;
						esac
					done
					;;
			esac
		done
	fi
	# turning off all output for case where no sensors detected or no sensors output 
	# unless -s used explicitly. So for -F type output won't show unless valid or -! 1 used
	if [[ $b_is_error != 'true' || $B_SHOW_SENSORS == 'true' || $B_TESTING_1 == 'true' ]];then
		temp_data="$cpu_temp$mobo_temp$psu_temp$gpu_temp"
		temp_data=$( create_print_line "Sensors:" "$temp_data" )
		print_screen_output "$temp_data"
		# don't print second or subsequent lines if error data
		fan_data="$cpu_fan$mobo_fan$ps_fan$sys_fans"
		if [[ $b_is_error != 'true' && -n $fan_data ]];then
			fan_data=$( create_print_line " " "$fan_data" )
			print_screen_output "$fan_data"
			# and then second wrapped fan line if needed
			if [[ -n $sys_fans2 ]];then
				fan_data2=$( create_print_line " " "$sys_fans2" )
				print_screen_output "$fan_data2"
			fi
		fi
	fi
	eval $LOGFE
}

print_system_data()
{
	eval $LOGFS
	local system_data='' bits='' desktop_environment='' dm_data='' de_extra_data=''
	local de_string='' distro_string='' line_starter='System:'
	local host_kernel_string='' host_string='' desktop_type='Desktop'
	local host_name=$HOSTNAME bit_comp=''
	local distro="$( get_distro_data )"
	local tty_session='' compiler_string='' distro_os='Distro'
	
	if [[ -n $BSD_TYPE ]];then
		distro_os='OS'
	fi
	get_kernel_version
	# I think these will work, maybe, if logged in as root and in X
	if [[ $B_RUNNING_IN_DISPLAY == 'true' ]];then
		desktop_environment=$( get_desktop_environment )
		if [[ -z $desktop_environment ]];then
			desktop_environment='N/A'
		fi
		
		if [[  $B_EXTRA_EXTRA_EXTRA_DATA == 'true' ]];then
			de_extra_data=$( get_desktop_extra_data )
			if [[ -n $de_extra_data ]];then
				de_extra_data=" ${C1}info$SEP3${C2} $de_extra_data"
			fi
		fi
	fi
	# handle separately since some systems will have no root desktop data
	if [[ $B_RUNNING_IN_DISPLAY == 'false' ]] || [[ $desktop_environment == 'N/A' && $B_ROOT == 'true' ]];then
		tty_session=$( get_tty_number )
		if [[ $desktop_environment == 'N/A' ]];then
			de_extra_data=''
		fi
		if [[ -z $tty_session && $B_CONSOLE_IRC == 'true' ]];then
			tty_session=$( get_tty_console_irc )
		fi
		if [[ -n $tty_session ]];then
			tty_session=" $tty_session"
		fi
		desktop_environment="tty$tty_session"
		desktop_type='Console'
	fi
	# having dm type can be useful if you are accessing remote system
	# or are out of X and don't remember which dm is running the system
	if [[  $B_EXTRA_EXTRA_DATA == 'true' ]];then
		dm_data=$( get_display_manager )
		# here we only want the dm info to show N/A if in X
		if [[ -z $dm_data && $B_RUNNING_IN_DISPLAY == 'true' ]];then
			dm_data='N/A'
		fi
		# only print out of X if dm_data has info, then it's actually useful, but
		# for headless servers, no need to print dm stuff.
		if [[ -n $dm_data ]];then
			dm_data=" ${C1}dm$SEP3${C2} $dm_data"
		fi
	fi
	if [[ $B_EXTRA_DATA == 'true' ]];then
		compiler_string=$( get_kernel_compiler_version )
		if [[ -n $compiler_string ]];then
			compiler_string="${C1}${compiler_string%^*}$SEP3${C2} ${compiler_string#*^} "
		fi
	fi
	# check for 64 bit first
	if [[ -n $( uname -m | grep -E '(x86_64|amd64)' ) ]];then
		bits="64"
	else
		bits="32"
	fi
	bits="${C1}bits$SEP3${C2} $bits "
	
	if [[ $B_SHOW_HOST == 'true' ]];then
		if [[ -z $HOSTNAME ]];then
			if [[ -n $( type p hostname ) ]];then
				host_name=$( hostname )
			fi
			if [[ -z $host_name ]];then
				host_name='N/A'
			fi
		fi
		host_string="${C1}Host$SEP3${C2} $host_name "
	fi
	host_kernel_string="$host_string${C1}Kernel$SEP3${C2} $CURRENT_KERNEL "
	bits_comp="$bits$compiler_string"
	de_string="${C1}$desktop_type$SEP3${C2} $desktop_environment$de_extra_data$dm_data "
	distro_string="${C1}$distro_os$SEP3${C2} $distro "
	calculate_line_length "$host_kernel_string$bits_comp$de_string"
	if [[ $LINE_LENGTH -gt $COLS_INNER ]];then
		calculate_line_length "$host_kernel_string$bits_comp"
		if [[ $LINE_LENGTH -gt $COLS_INNER ]];then
			#echo one
			system_data=$( create_print_line "$line_starter" "$host_kernel_string" )
			print_screen_output "$system_data"
			system_data=$( create_print_line "  " "$bits_comp" )
			print_screen_output "$system_data"
		else
			#echo two
			system_data=$( create_print_line "$line_starter" "$host_kernel_string$bits_comp" )
			print_screen_output "$system_data"
			
		fi
		host_kernel_string=''
		bits_comp=''
		line_starter=' '
	fi
	calculate_line_length "$host_kernel_string$bits_comp$de_string$distro_string"
	if [[ $LINE_LENGTH -gt $COLS_INNER ]];then
		#echo three
		system_data=$( create_print_line "$line_starter" "$host_kernel_string$bits_comp$de_string" )
		print_screen_output "$system_data"
		host_kernel_string=''
		de_string=''
		bits_comp=''
		line_starter=' '
	fi
	system_data="$host_kernel_string$bits_comp$de_string$distro_string"
	if [[ -n $system_data ]];then
		#echo four
		system_data="$host_kernel_string$bits_comp$de_string$distro_string"
		system_data=$( create_print_line "$line_starter" "$system_data" )
		print_screen_output "$system_data"
	fi
	
	eval $LOGFE
}

print_unmounted_partition_data()
{
	eval $LOGFS
	local a_unmounted_data='' line_starter='' unmounted_data='' full_fs=''
	local full_dev='' full_size='' full_label='' full_uuid='' full_string=''
	local bsd_unsupported='This feature is not yet supported for BSD systems.'
	local line_starter='Unmounted:' part_2_data=''
	
	if [[ -z ${A_PARTITION_DATA} ]];then
		get_partition_data
	fi
	get_unmounted_partition_data
	if [[ ${#A_UNMOUNTED_PARTITION_DATA[@]} -ge 1 ]];then
		for (( i=0; i < ${#A_UNMOUNTED_PARTITION_DATA[@]}; i++ ))
		do
			full_string=''
			part_2_data=''
			IFS=","
			a_unmounted_data=(${A_UNMOUNTED_PARTITION_DATA[i]})
			IFS="$ORIGINAL_IFS"
			if [[ -z ${a_unmounted_data[0]} ]];then
				full_dev='N/A'
			else
				full_dev="/dev/${a_unmounted_data[0]}"
			fi
			full_dev="${C1}ID-$((i+1))$SEP3${C2} $full_dev "
			if [[ -z ${a_unmounted_data[1]} ]];then
				full_size='N/A'
			else
				full_size=${a_unmounted_data[1]}
			fi
			full_size="${C1}size$SEP3${C2} $full_size "
			if [[ -z ${a_unmounted_data[2]} ]];then
				full_label='N/A'
			else
				full_label=${a_unmounted_data[2]}
			fi
			full_label="${C1}label$SEP3${C2} $full_label "
			if [[ -z ${a_unmounted_data[3]} ]];then
				full_uuid='N/A'
			else
				full_uuid=${a_unmounted_data[3]}
			fi
			full_uuid="${C1}uuid$SEP3${C2} $full_uuid "
			if [[ -z ${a_unmounted_data[4]} ]];then
				full_fs=''
			else
				full_fs="${C1}fs$SEP3${C2} ${a_unmounted_data[4]} "
			fi
			# temporary message to indicate not yet supported
			if [[ $BSD_TYPE == 'bsd' ]];then
				full_string=$bsd_unsupported
			else
				full_string="$full_dev$full_size$full_fs"
				part_2_data="$full_label$full_uuid"
			fi
			calculate_line_length "$full_string$part_2_data"
			if [[ $LINE_LENGTH -gt $COLS_INNER ]];then
				unmounted_data=$( create_print_line "$line_starter" "$full_string" )
				print_screen_output "$unmounted_data"
				line_starter=' '
				unmounted_data=$( create_print_line "$line_starter" "$part_2_data" )
				print_screen_output "$unmounted_data"
			else
				unmounted_data=$( create_print_line "$line_starter" "$full_string$part_2_data" )
				print_screen_output "$unmounted_data"
				line_starter=' '
			fi
		done
	else
		unmounted_data=$( create_print_line "$line_starter" "No unmounted partitions detected" )
		print_screen_output "$unmounted_data"
	fi
	
	eval $LOGFE
}

print_weather_data()
{
	eval $LOGFS
	
	local weather_data='' location_string='' local_time='' time_string='' pressure=''
	local a_location='' a_weather='' weather_string='' weather='' temp='' winds='' humidity=''
	local time_zone='' observation_time='' city='' state='' country='' altitude=''
	local heat_index='' wind_chill='' dewpoint='' xxx_humidity=''
	local openP='(' closeP=')'
	
	if [[ $B_IRC == 'true' ]];then
		openP=''
		closeP=''
	fi
	
	get_weather_data
	
	# city ";" regionCode ";" regionName ";" countryName ";" countryCode ";" countryCode3 
	#  ";" latitude "," longitude ";" postalCode ";" timeZone
	
	# observationTime ";" localTime ";" weather ";" tempString ";" humidity 
	# ";" windString ";" pressureString ";" dewpointString ";" heatIndexString
	# ";" windChillString ";" siteElevation

	if [[ ${#A_WEATHER_DATA[@]} -eq 2 ]];then
		IFS=";"
		a_location=(${A_WEATHER_DATA[0]})
		a_weather=(${A_WEATHER_DATA[1]})
		IFS="$ORIGINAL_IFS"
		
		if [[ -n ${a_weather[3]} ]];then
			temp=${a_weather[3]}
		else
			temp='N/A'
		fi
		if [[ -n ${a_weather[2]} ]];then
			weather=" - ${a_weather[2]}"
		else
			weather=''
		fi
		if [[ $B_EXTRA_DATA == 'true' ]];then
			if [[ -n ${a_weather[5]} ]];then
				winds=" ${C1}Wind$SEP3${C2} ${a_weather[5]}"
			fi
		fi
		if [[ $B_EXTRA_EXTRA_DATA == 'true' ]];then
			if [[ -n ${a_weather[4]} ]];then
				humidity=" ${C1}Humidity$SEP3${C2} ${a_weather[4]}"
			fi
			if [[ -n ${a_weather[6]} ]];then
				pressure="${C1}Pressure$SEP3${C2} ${a_weather[6]} "
			fi
		fi
		weather_string="${C1}Conditions$SEP3${C2} $temp$weather$winds$humidity"
		
		if [[ -n ${a_weather[1]} ]];then
			local_time=" ${a_weather[1]}"
		else
			local_time=" $(date)"
		fi
		if [[ $B_EXTRA_DATA == 'true' && -n ${a_location[8]} ]];then
			time_zone=" (${a_location[8]})"
		fi
		time_string="${C1}Time$SEP3${C2}$local_time$time_zone"

		if [[ $B_EXTRA_DATA != 'true' ]];then
			weather_data="$weather_string $time_string"
			weather_data=$( create_print_line "Weather:" "$weather_data" )
			print_screen_output "$weather_data"
		else
			weather_data="$weather_string"
			weather_data=$( create_print_line "Weather:" "$weather_data" )
			print_screen_output "$weather_data"
			if [[ $B_EXTRA_EXTRA_EXTRA_DATA == 'true' ]];then
				if [[ -n ${a_weather[8]} ]];then
					heat_index="${C1}Heat Index$SEP3${C2} ${a_weather[8]} "
				fi
				if [[ -n ${a_weather[9]} ]];then
					wind_chill="${C1}Wind Chill$SEP3${C2} ${a_weather[9]} "
				fi
				if [[ -n ${a_weather[7]} ]];then
					dew_point="${C1}Dew Point$SEP3${C2} ${a_weather[7]} "
				fi
				if [[ -n ${a_weather[0]} ]];then
					observation_time=" ${C1}Observation Time$SEP3${C2} ${a_weather[0]} "
				fi
				if [[ $B_OUTPUT_FILTER != 'true' ]];then
					if [[ -n ${a_location[0]} ]];then
						city=" ${a_location[0]}"
					fi
					if [[ -n ${a_location[1]} ]];then
						state=" ${a_location[1]}"
					fi
					if [[ -n ${a_location[5]} ]];then
						country=" $openP${a_location[5]}$closeP"
					fi
					if [[ -n ${a_weather[10]} ]];then
						# note: bug in source data uses ft for meters, not 100% of time, but usually
						altitude=" ${C1}Altitude$SEP3${C2} ${a_weather[10]/ft/m}"
					fi
					location_string="${C1}Location$SEP3${C2}$city$state$country$altitude "
				else
					location_string=$time_string$observation_time
					time_string=''
					observation_time=''
				fi
				# the last three are often blank
				if [[ -z "$heat_index$wind_chill$dew_point" ]];then
					weather_data=$( create_print_line " " "$pressure$location_string" )
					print_screen_output "$weather_data"
				else
					weather_data=$( create_print_line " " "$pressure$heat_index$wind_chill$dew_point" )
					print_screen_output "$weather_data"
					if [[ $B_OUTPUT_FILTER != 'true' ]];then
						weather_data=$( create_print_line " " "$location_string" )
						print_screen_output "$weather_data"
					fi
				fi
				if [[ -n $time_string$observation_time ]];then
					weather_data=$( create_print_line " " "$time_string$observation_time" )
					print_screen_output "$weather_data"
				fi
			else
				if [[ -n $pressure$time_string ]];then
					weather_data="$pressure$time_string"
					weather_data=$( create_print_line " " "$weather_data" )
					print_screen_output "$weather_data"
				fi
			fi
		fi
	else
		weather_data=$( create_print_line "Weather:" "${C2}Weather data failure: $(date)" )
		print_screen_output "$weather_data"
		weather_data=$( create_print_line " " "${C2}${A_WEATHER_DATA}" )
		print_screen_output "$weather_data"
	fi
	eval $LOGFE
}

########################################################################
#### SCRIPT EXECUTION
########################################################################

main $@ ## From the End comes the Beginning

## note: this EOF is needed for smxi handling, this is what triggers the full download ok
###**EOF**###
