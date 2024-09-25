#!/bin/bash

set -u

ACTIVATIONURL='dsm://agents.deepsecurity.trendmicro.com:443/'
MANAGERURL='https://app.deepsecurity.trendmicro.com:443'
CURLOPTIONS='--silent --tlsv1.2'
linuxPlatform='';
isRPM='';

test $(id -u) == 0 && sudo="" || sudo=sudo

scriptBaseName=${0/*\//}
if [ $# = 1 ];then
	if [ $1 = -h ];then
		echo "=> Usage $scriptBaseName variablesDefinitionFile" >&2
		exit -1
	else
		variablesDefinitionFile=$1
	fi
fi

variablesDefinitionFile="$1"
source "$variablesDefinitionFile" || exit

if ! type curl >/dev/null 2>&1; then
    echo "Please install CURL before running this script."
    logger -t Please install CURL before running this script
    exit 1
fi

curl -L $MANAGERURL/software/deploymentscript/platform/linuxdetectscriptv1/ -o /tmp/PlatformDetection $CURLOPTIONS --insecure

if [ -s /tmp/PlatformDetection ]; then
    . /tmp/PlatformDetection
else
    echo "Failed to download the agent installation support script."
    logger -t Failed to download the Deep Security Agent installation support script
    exit 2
fi

platform_detect
if [[ -z "${linuxPlatform}" ]] || [[ -z "${isRPM}" ]]; then
    echo Unsupported platform is detected
    logger -t Unsupported platform is detected
    exit 3
fi

echo Downloading agent package...
if [[ $isRPM == 1 ]]; then package='agent.rpm'
    else package='agent.deb'
fi

[ $ubuntuVersion != current ] && majorVersion=$ubuntuVersion
curl -H "Agent-Version-Control: on" -L $MANAGERURL/software/agent/${runningPlatform}${majorVersion}/${archType}/$package -o /tmp/$package $CURLOPTIONS --insecure

echo Installing agent package...
rc=1
if [[ $isRPM == 1 && -s /tmp/$package ]]; then
    $sudo rpm -ihv /tmp/$package
    rc=$?
elif [[ -s /tmp/$package ]]; then
    $sudo apt install -V /tmp/$package
    rc=$?
else
    echo Failed to download the agent package. Please make sure the package is imported in the Workload Security Manager
    logger -t Failed to download the agent package. Please make sure the package is imported in the Workload Security Manager
    exit 4
fi
if [[ ${rc} != 0 ]]; then
    echo Failed to install the agent package
    logger -t Failed to install the agent package
    exit 5
fi

echo Install the agent package successfully

rm -f /tmp/$package /tmp/PlatformDetection

sleep 15
dsa_control=/opt/ds_agent/dsa_control
$sudo $dsa_control -r
$sudo $dsa_control -a $ACTIVATIONURL "tenantID:$tenantID" "token:$token" "policyid:$policyid"
