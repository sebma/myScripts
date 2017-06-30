#!/bin/bash

# Copyright (C) 2007 Lorenzo J. Lucchini <ljlbox@tiscali.it>
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 675 Mass Ave, Cambridge, MA 02139, USA.
#
#
# First thing, we state that the directory where the sources reside is
# the same as the argument the user passed to us. We will change this
# later if needed, but since there is an "rm -r -f" that depends on
# the contents of this variable, we better set it immediately.



## Human language strings are stored in variables to ease a possible future localization.

LOC_SELECT_FILE="Select a file or directory"
LOC_TYPE_FILE="Type the name of the archive or directory containing the source code"
LOC_PRESS_ENTER_DEFAULT="Press Enter to use"
LOC_PRESS_CTRL_D_TO_STOP="Press Ctrl-D when finished"
LOC_TYPE_PASSWORD="This program is EXPERIMENTAL and DANGEROUS. Type your administrator password"
LOC_INVALID_FILE="A file or directory name must be given"
LOC_EXTRACTING="Extracting archive"
LOC_EXTRACT_FAILED="Archive extraction failed"
LOC_NO_BUILD_ENV="No known build environment found in source tree"
LOC_UPDATING_AUTOAPT="Updating packages database"
LOC_TRYING_CONFIGURE="Trying to configure"
LOC_TRYING_MAKE="Trying to build"
LOC_TRYING_INSTALL="Trying to install"
LOC_CREATING_PACKAGE="Creating package"
LOC_INSTALLING_DEPENDS="Installing runtime dependencies"
LOC_APT_INSTALLING="APT is installing packages (do NOT interrupt)"
LOC_APT_REMOVING="APT is removing packages (do NOT interrupt)"
LOC_REMOVING_BUILD_DEPS="Removing build dependencies"
LOC_SEARCHING_FILE="Searching for file"
LOC_INSTALLING_PACKAGES="Installing package(s)"
LOC_REMOVING_PACKAGES="Removing package(s)"
LOC_FINISHED="Finished"
LOC_RUNNING="Running"
LOC_BUILD_COMPLETED="Finished building"
LOC_BUILD_ABORTED="Build aborted. Incomplete build tree is in"
LOC_UNEXPECTED_ABORT="Unexpected build system abort"
LOC_FILE_NOT_FOUND="No such file or directory"
LOC_CANNOT_READ="Cannot read"
LOC_CONFIGURE_FAILED="Could not configure build system"
LOC_BUILD_FAILED="Could not build program"
LOC_INSTALL_FAILED="Could not install package"
LOC_NOT_KNOWN_GUI="is not a known user interface"
LOC_BAD_PASSWORD="Wrong password"
LOC_REPORT_BUGS="Report bugs to <ljlbox@tiscali.it>"
LOC_DESCRIPTION="Build the source tree contained in FILE (which can also be a directory)."
LOC_USAGE="Usage"
LOC_NOT_ROOT="You must be root to use this program"
LOC_APT_FAILURE="APT reported a problem. Try 'apt-get -f install'"



## Terminate with an error message (given as parameter), and remove any dangling
## build dependencies.

function Abort {
    if [[ -n "$BUILD_DEPENDS" ]]; then
        ## Avoid going into an infinite loop with RemovePackages
        Packages=$BUILD_DEPENDS
        BUILD_DEPENDS=""
        RemovePackages $Packages
    fi
    if [[ -n "$1" ]]; then
        ShowError "$1"
    else
        ShowError "$LOC_BUILD_ABORTED '$SOURCE_DIR'"
    fi
    exit 1
}


## Execute a command (passed in the parameters) as user $USERNAME rather than root.

function UserMode {
    su -c "$*" $USERNAME
}


## Request a file or directory name to the user, and return it in the $File variable,
## or return the empty string if the user does not provide a valid filename.

function FileRequester {
    if [[ $INTERFACE == "zenity" ]]; then
        ## Unfortunately, Zenity doesn't allow chosing a file *or* a directory using
        ## the same dialog. Here we just create a file selector dialog.
        File=$(zenity 2>/dev/null --title "$LOC_SELECT_FILE" --file-selection)
    elif [[ $INTERFACE == "kdialog" ]]; then
        ## With KDialog, selecting a directory is not completely intuitive, but can
        ## be done with the same dialog that allows selecting a file: select the
        ## directory, and click 'Open' twice.
        File=$(kdialog 2>/dev/null --getopenfilename $(pwd))
    else
        read -e -p "$LOC_TYPE_FILE : " File
    fi
}



## Request a line of text from the user, and return it in the $String variable. The first
## argument is the prompt to the user, and the second argument, if given, is the
## default text.

function StringRequester {
    if [[ $INTERFACE == "zenity" ]]; then
        String=$(zenity 2>/dev/null --title "Input" --text "$1" --entry-text "$2" --entry)
    elif [[ $INTERFACE == "kdialog" ]]; then
        String=$(kdialog 2>/dev/null --title "Input" --inputbox "$1" "$2")
    else
        read -p "$1 - $LOC_PRESS_ENTER_DEFAULT '$2' : " String
        if [[ -z "$String" ]]; then String="$2"; fi
    fi
}


## Request multi-line text to the user, and return it in the $Text variable. The first
## argument is the prompt to the user, and the second argument, if given, is the
## default text.

function TextRequester {
    if [[ $INTERFACE == "zenity" ]]; then
        ## Zenity currently doesn't support '--text' for multiline input boxes, it just ignores
        ## it. We put it there anyway, in the hope that it will supported in the future.
        Text=$(echo "$2" | zenity 2>/dev/null --title "Input" --text "$1" --text-info --editable)
    elif [[ $INTERFACE == "kdialog" ]]; then
        Text=$(kdialog 2>/dev/null --title "Input" --textinputbox "$1" "$2")
    else
        read -d $'\x4' -p "$1 - $LOC_PRESS_CTRL_D_TO_STOP :"$'\n' Text
        echo ""
        if [[ -z "$Text" ]]; then Text="$2"; fi
    fi
}


## Show an error message (passed via the first parameter) to the user, and terminate.

function ShowError {
    echo ERROR: "${1}."
    HideStatus
    HideNotification
    if [[ $INTERFACE == "zenity" ]]; then
        zenity 2>/dev/null --error --text "${1}."
    elif [[ $INTERFACE == "kdialog" ]]; then
        kdialog 2>/dev/null --error "${1}."
    fi
}


## Show an empty status window with a progressbar starting at 0%.

function ShowStatus {
    if [[ $INTERFACE == "zenity" ]]; then
        exec 8> >(zenity 2>/dev/null --width 550 --height 250 --progress --auto-kill --text '\n\n\n\n\n\n\n ')
    elif [[ $INTERFACE == "kdialog" ]]; then
        DCOP_REFERENCE=$(kdialog 2>/dev/null --geometry 550x250 --title "AutoDeb" --progressbar "")
        dcop $DCOP_REFERENCE showCancelButton true
        dcop $DCOP_REFERENCE setAutoClose true
    fi
}


## Close a previously opened status window.

function HideStatus {
    if [[ $INTERFACE == "zenity" ]]; then
        exec >&8-
    elif [[ $INTERFACE == "kdialog" ]]; then
        if [[ -n "$DCOP_REFERENCE" ]]; then dcop $DCOP_REFERENCE close; fi
    fi
}


## With a status window open, update it as follows:
## - 1st parameter: description of the current state
## - 2nd parameter: a percentage, or none to leave percentage unchanged
## - 3rd parameter: a file descriptor to read sub-states from
## If the 3rd parameter is given, lines of text can be piped into the file
## descriptor to make the sub-state description change accordingly in real time.

function UpdateStatus {
    echo >>"${LOG_FILE}" -e "\n$(date): $1\n"
    if [[ -n "$2" ]]; then echo "${1}... (${2}%)"; else echo "${1}..."; fi
    if [[ $INTERFACE == "zenity" ]]; then
        echo >&8 '# '"${1}..."'\n\n\n\n\n\n\n '
        echo >&8 "$2"
        if [[ -n "$3" ]]; then
            ## Using sed to prepend text is far from foolproof. I don't know of a better way; meanwhile, we just
            ## hope that our program won't output pipe characters.
            tee <"$3" --append "${LOG_FILE}" | sed >&8 --unbuffered --regexp-extended \
                's|^[[:space:]]*(.{0,70})(.{0,70})(.{0,70})(.{0,70}).*|# '"${1}..."'\\n\\n\1\\n\2\\n\3\\n\4\\n\\n |g'
        fi
    elif [[ $INTERFACE == "kdialog" ]]; then
        dcop "$DCOP_REFERENCE" setLabel "$(echo -e "\n${1}...\n\n\n\n\n\n ")"
        if [[ -n "$2" ]]; then dcop "$DCOP_REFERENCE" setProgress "$2"; fi
        if [[ -n "$3" ]]; then
            (echo -e -n "\n" ; tee <"$3" --append "${LOG_FILE}" | sed --unbuffered --regexp-extended \
                's|^[[:space:]]*(.{0,70})(.{0,70})(.{0,70})(.{0,70}).*|'"${1}..."'\n\n\1\n\2\n\3\n\4\n \x0|g' ) | \
                xargs -n 1 -0 --replace dcop "$DCOP_REFERENCE" setLabel "{}"
        fi
    else
        if [[ -n "$3" ]]; then tee <"${3}" --append "${LOG_FILE}" | cat; fi
    fi
}


## Show a notification (try icon, balloon... depends on the interface), taking the
## text from the first parameter.

function ShowNotification {
    echo "Warning: $1"
    if [[ $INTERFACE == "zenity" ]]; then
        exec 9> >(zenity 2>/dev/null --listen --text "$1" --notification)
    elif [[ $INTERFACE == "kdialog" ]]; then
        kdialog 2>/dev/null --passivepopup "$1" 5 &
    fi
}


## Remove a previously shown notification.

function HideNotification {
    if [[ $INTERFACE == "zenity" ]]; then
        exec 9>&-
    fi
}


## Install the Debian packages given as parameters.

function InstallPackages {
    ShowNotification "$LOC_APT_INSTALLING"
    apt-get -qq install $* | UpdateStatus "$LOC_INSTALLING_PACKAGES $*..." "" /dev/stdin
    if [[ $PIPESTATUS -ne 0 ]]; then Abort "$LOC_APT_FAILURE"; fi
    HideNotification
}


## Remove the Debian packages given as parameters.

function RemovePackages {
    ShowNotification "$LOC_APT_REMOVING"
    apt-get -qq remove $* | UpdateStatus "$LOC_REMOVING_PACKAGES $*" 90 /dev/stdin
    if [[ $PIPESTATUS -ne 0 ]]; then Abort "$LOC_APT_FAILURE"; fi
    HideNotification
}


## Ask the user to fill in metadata for the package, based on a string (passed
## as parameter) in the form programname-version.number.

function SetPackageInfo {
    PKG_NAME=$(echo "$1" | rev | cut -d "-" -f 2- | rev | sed 's/ /_/g')
    PKG_VERS=$(echo "$1" | rev | cut -d "-" -f 1  | rev | sed 's/ /_/g')
    StringRequester "Choose a name for the package to create" $PKG_NAME; PKG_NAME="$String"
    StringRequester "Type a a version number for the package" $PKG_VERS; PKG_VERS="$String"
    TextRequester "Type in a description of the package" "$PKG_NAME $PKG_VERS, generated by AutoDeb"; PKG_DESC="$Text"
}


## Run the command that was passed as parameter which keeping track of any files
## it tries to access. If the command fails (non-zero exit status), install packages
## that may fix the problem, and try again. Keep doing this until out of ideas about
## what more to install.

function MonitoredExecute {
    true; while [[ $? -eq 0 ]]; do
        TRACE_FILE=$(tempfile)

        UserMode strace -f -F -q -e trace=file,exit_group -e signal=none "$1" \
            2> >(grep 'ENOENT\|exit\|pkg\-config' >${TRACE_FILE}) | \
            UpdateStatus "$LOC_RUNNING '${1}'" "" /dev/stdin

        ## Since strace discards the traced program's exit value, we need another way
        ## to know if the configure was successful; so we explicitely asked strace to
        ## store any exit_group call that was made, and now we read the argument that
        ## was passed to last one made.
        if ! tail -1 $TRACE_FILE | grep -q 'exit'; then
            Abort "$LOC_UNEXPECTED_ABORT"
        elif tail -1 $TRACE_FILE | grep -q '0'; then
            ## Configure was successful, leave the loop
            break
        fi

        ## If we reach this point, it means the build was unsuccessful, so we look at
        ## the strace output and install a package we "guess" as the culprit.

        ProcessTraceFile $TRACE_FILE
    done
    return $Status
}


## Given a filename, passed as parameter, find a package containing it (if multiple packages
## contain the same file, heuristics are used and only one is chosen) and return it in the
## variable $Package. If no package is found, an empty string is returned.

function FindPackageForFile {
    UpdateStatus "$LOC_SEARCHING_FILE '${1}'"
    ## auto-apt can take full pathames using the 'check' command, or regexps with 'search'
    if [[ "${1:0:1}" == "/" ]]; then
        Packages=$(auto-apt check "$1" | tr "," " ")
    else
        Packages=$(auto-apt search "${1}[^[:print:]]" | cut -f 2 | tr "\n" "," | tr "," " ")
    fi
    ## auto-apt check outputs '*' when it cannot find anything.
    if [[ "$Packages" == '*' ]]; then Package=""; return 1; fi
    ## If multiple packages provide the same file, choose the one with the shortest name.
    ## This helps making the right choice between 'package' and 'package-dbg', and the like.
    Package=""
    for Candidate in $Packages; do
        if [[ -z "$Package" || ${#Candidate} -lt ${#Package} ]]; then Package=$Candidate; fi
    done
    Package="$(basename "$Package")"
    if [[ -n "$Package" ]]; then return 0; else return 1; fi
}


## Parse a file given as argument containing strace output for files not found during a build attempt,
## and install the Debian package judged most relevant to solve the problem. Return 0 if something was
## installed, 1 otherwise.

function ProcessTraceFile {

    ## Read the strace output and find out which files could not be accessed. Sort them heuristically
    ## so as to have the most likely candidates for missing packages listed first.

    MainStatCalls=$(tac $1 | grep -v '\[' | grep    stat | head -40 | grep --only-matching '"/[^" ]\+"')
    ForkStatCalls=$(tac $1 | grep    '\[' | grep    stat | head -40 | grep --only-matching '"/[^" ]\+"')
    MainMiscCalls=$(tac $1 | grep -v '\[' | grep -v stat | head -40 | grep --only-matching '"/[^" ]\+"')
    ForkMiscCalls=$(tac $1 | grep    '\[' | grep -v stat | head -40 | grep --only-matching '"/[^" ]\+"')
    PkgConfigCalls=$(tac $1 | grep 'exec' | grep 'pkg-config' | grep --only-matching '"[^-/",][^/", ]\+[" ]' | sed 's/[" ]$/.pc"/g')

    FileList=$(echo "$PkgConfigCalls $MainStatCalls $ForkStatCalls $MainMiscCalls $ForkMiscCalls" | sed 's:"::g')

    for File in $FileList; do
        ## If the file is in the blacklist, skip it
        for ToSkip in $BLACKLIST; do if [[ "$File" == "$ToSkip" ]]; then continue; fi; done
        if echo "$File" | grep -q '^/tmp\|^/home\|^/usr/local'; then continue; fi
        FindPackageForFile $File
        if [[ -z $Package ]]; then
            ## No package owns that file, so we put the file into the blacklist in order to
            ## avoid wasting time searching for it again.
            BLACKLIST="$BLACKLIST $File"
        else
            ## Install the found package, add it to the list of install development packages
            ## and terminate successfully.
            InstallPackages $Package
            BUILD_DEPENDS="$BUILD_DEPENDS $Package"
            return 0
        fi
    done

    return 1
}



## Give some help if requested.

if [[ "$1" == "--help" ]]; then
    echo "$LOC_USAGE: $0 [--kde|--gnome] [FILE]"
    echo "$LOC_DESCRIPTION"
    echo ""
    echo "$LOC_REPORT_BUGS"
    exit 0
fi


## The preferred user interface can be specified in the command line, prefixed with '--'.

if [[ "${1:0:2}" == "--" ]]; then
    INTERFACE="${1:2}"
    shift
fi


## The following doesn't really do very much at the moment, except fall back to the console
## interface if whatever the user specified is not available. In the future, it might provide
## a more sophisticated fallback mechanism, in case more interface choices are added.

while ! which "$INTERFACE" >/dev/null; do
    if [[ "$INTERFACE" == "" ]]; then break
    elif [[ "$INTERFACE" == "kde" ]];     then INTERFACE="kdialog"
    elif [[ "$INTERFACE" == "gnome" ]];   then INTERFACE="zenity"
    elif [[ "$INTERFACE" == "kdialog" ]]; then INTERFACE=""
    elif [[ "$INTERFACE" == "zenity" ]];  then INTERFACE=""
    else Abort "'$INTERFACE' $LOC_NOT_KNOWN_GUI"
    fi
done


## Check that we are root.

if [[ $UID -ne 0 ]]; then
    Abort "$LOC_NOT_ROOT"
fi


## If no argument was passed, then ask the user where the source tarball, or directory, is located.

if [[ -e "$1" ]]; then
    SOURCE_PTR="$1"
else
    FileRequester; SOURCE_PTR="$File"
fi

if [[ ! -e "$SOURCE_PTR" ]]; then Abort "$LOC_FILE_NOT_FOUND '${SOURCE_PTR}'"; fi
if [[ ! -r "$SOURCE_PTR" ]]; then Abort "$LOC_CANNOT_READ '${SOURCE_PTR}'"; fi


## We'll need to know which directory we started from later, and we also need
## a $LOG_FILE variable for UpdateStatus to work.

WORK_DIR=$(pwd)
LOG_FILE="$WORK_DIR/autodeb.log"


## If the user gave a directory, use it; if a file was given, attempt to
## extract it using tar into a temporary directory, and use that.

USERNAME=$(stat -c "%U" "$SOURCE_PTR")

if [[ -z "$SOURCE_PTR" ]]; then
    Abort "$LOC_INVALID_FILE"
elif [[ -d "$SOURCE_PTR" ]]; then
    SOURCE_DIR="$SOURCE_PTR"
    SetPackageInfo $(cd "$SOURCE_DIR"; basename $(pwd))
    ShowStatus
else
    SOURCE_DIR=$(UserMode mktemp -d)
    SetPackageInfo $(basename $SOURCE_PTR | sed 's/\.tar$\|\.tar\.gz$\|\.tar\.bz2$\|\.tgz$\|\.zip$//')
    ShowStatus
    UpdateStatus "$LOC_EXTRACTING" 0
    UserMode tar --extract --directory "$SOURCE_DIR" --file "$SOURCE_PTR"
    if [[ $? -ne 0 ]]; then
        Abort "$LOC_EXTRACT_FAILED"
    fi
    ## If the tar archive created one single sub-directory, use that.
    ## Otherwise, just hope the parent directory is the right one.
    if [[ $(ls ${SOURCE_DIR} | wc -l) -eq 1 ]]; then
        SOURCE_DIR=$(echo "${SOURCE_DIR}"/*)
    fi
fi


cd "$SOURCE_DIR"

trap Abort 1 2 3 4 5 6 7 8 9


## The "batch job" starts here, and we try to avoid having to stop to ask the user
## things from now on.

## 1) Install essential packages

InstallPackages build-essential auto-apt checkinstall

## Create the auto-apt database if it doesn't yet exist
if ! ( auto-apt list | head -1 >/dev/null ); then
    auto-apt update | UpdateStatus "$LOC_UPDATING_AUTOAPT" 5 /dev/stdin
fi


## 1) Find out what build system the program uses

if [[ -x "configure" ]]; then
    CONF_CMD="./configure"
    MAKE_CMD="make"
    INST_CMD="make install"
else
    Abort "$LOC_NO_BUILD_ENV"
fi


## 2) Configure build environment

UpdateStatus "$LOC_TRYING_CONFIGURE" 10
MonitoredExecute $CONF_CMD
if [[ $? -ne 0 ]]; then Abort "$LOC_CONFIGURE_FAILED"; fi


## 3) Build program

UpdateStatus "$LOC_TRYING_MAKE" 20
MonitoredExecute $MAKE_CMD
if [[ $? -ne 0 ]]; then Abort "$LOC_BUILD_FAILED"; fi


## 4) Install program

PKG_DIR=$(UserMode mktemp -d)
UserMode checkinstall --default --install=no --pakdir "$PKG_DIR" \
    --pkgname "$PKG_NAME" --pkgversion "$PKG_VERS" $INST_CMD | \
    UpdateStatus "$LOC_TRYING_INSTALL" 50 /dev/stdin
if [[ $PIPESTATUS -ne 0 ]]; then Abort "$LOC_INSTALL_FAILED"; fi


## 5) Find runtime dependencies

for File in $(UserMode dpkg --vextract "$PKG_DIR/"*.deb "$PKG_DIR"); do
    ## Right now, we only care about executable files.
    ## One could think about later implementing heuristics to extract
    ## meaningful dependencies from other filetypes, too... who knows.
    File="${PKG_DIR}/${File}"
    if ! ( file --mime "$File" | grep -q "x-executable" ); then continue; fi
    echo "$File" | UpdateStatus "Finding runtime dependencies..." 60 /dev/stdin
    RequiredLibraries="$RequiredLibraries $(ldd -u $File | awk '{ print $1 }' | tail -n +3)"
done
RequiredLibraries=$(echo "${RequiredLibraries}" | sort | uniq)
for File in $RequiredLibraries; do
    FindPackageForFile "$(basename "$File")"
    if [[ $? -eq 0 ]]; then RUN_DEPENDS="$RUN_DEPENDS, $Package"; fi
done
## Remove duplicates. More elegant ways to achieve that are welcome.
RUN_DEPENDS="$(echo "${RUN_DEPENDS#, }" | tr " " "\n" | sort | uniq | tr "\n" " ")"


## 6) Create package

echo "$PKG_DESCRIPTION" | \
    checkinstall --default --install=no --pakdir "$PKG_DIR" --pkgname "$PKG_NAME" \
    --pkgversion "$PKG_VERS" --requires "$RUN_DEPENDS" $INST_CMD | \
    UpdateStatus "$LOC_CREATING_PACKAGE" 70 /dev/stdin


## 7) Install package and dependencies

dpkg -i "$PKG_DIR/"*.deb 2>/dev/null | UpdateStatus "$LOC_INSTALLING_DEPENDS" 80 /dev/stdin
apt-get -qq -f install | UpdateStatus "$LOC_INSTALLING_DEPENDS" 85 /dev/stdin
if [[ $PIPESTATUS -ne 0 ]]; then Abort "$LOC_APT_FAILURE"; fi


## 8) Remove build dependencies

if [[ -n "$BUILD_DEPENDS" ]]; then
    UpdateStatus "$LOC_REMOVING_BUILD_DEPS" 90
    RemovePackages $BUILD_DEPENDS
fi


## 9) Clean up

UserMode cp "$PKG_DIR/"*.deb "$WORK_DIR"/
UpdateStatus $LOC_FINISHED 100
HideStatus
ShowNotification "$LOC_BUILD_COMPLETED '${PKG_NAME}'"
