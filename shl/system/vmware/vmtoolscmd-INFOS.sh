#!/usr/bin/env bash

set -u

vmtoolsd --cmd "info-get guestinfo.vmtools.description"
vmtoolsd --cmd "info-get guestinfo.vmtools.versionString"
vmtoolsd --cmd "info-get guestinfo.vmtools.versionNumber"
vmtoolsd --cmd "info-get guestinfo.vmtools.buildNumber"
vmtoolsd --cmd "info-get guestinfo.toolsInstallErrCode"
vmtoolsd --cmd "info-get guestinfo.ip"
#vmtoolsd --cmd "info-get guestinfo.appInfo" | jq 
#vmtoolsd --cmd "info-get guestinfo.driver.$driverNAME.version"
