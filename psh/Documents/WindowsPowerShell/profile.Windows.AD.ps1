"=> Sourcing $scriptPrefix.$osFamily.AD.ps1 functions ..."
function findGroup {
	$myPattern = '*'+$args[0]+'*'
	$DC = $env:LOGONSERVER.Substring(2)
	Get-ADGroup -Server $DC -Properties CN , CanonicalName , Created, Modified , Description -Filter { name -like $myPattern }
}
function findUser {
	$myPattern = '*'+$args[0]+'*'
	$DC = $env:LOGONSERVER.Substring(2)
	# ` is used for Newline escape
	Get-ADUser -Server $DC -Properties CN , CanonicalName , Created , Description , EmailAddress , Enabled , LastLogonDate, LockedOut, msDS-UserPasswordExpiryTimeComputed , PasswordExpired , PasswordLastSet , PasswordNeverExpires , proxyAddresses , SamAccountName , UserPrincipalName -Filter { Name -like $myPattern -or (SamAccountName -like $myPattern) } `
| select CN , CanonicalName , Created , Description , DistinguishedName , EmailAddress , Enabled , LastLogonDate, LockedOut, @{name="PasswordExpiryDate";expression={ [datetime]::fromfiletime($_."msDS-UserPasswordExpiryTimeComputed") } } , PasswordExpired , PasswordLastSet , PasswordNeverExpires , proxyAddresses , SamAccountName , UserPrincipalName
}
function groups {
	$argc=$args.Count
	if ( $argc -eq 0) {
		( (Get-ADUser -Identity $env:username -Properties MemberOf).memberof | Get-ADGroup ).name | sort
	} else {
		for($i=0;$i -lt $argc;$i++) {
			echo "=> Memberships of $($args[$i]) :"
			( ( Get-ADUser -Identity $($args[$i]) -Properties MemberOf ).memberof | Get-ADGroup ).name | sort
		}
	}
}
function lsgroup {
	$argc=$args.Count
	if ( $argc -gt 0) {
		for($i=0;$i -lt $argc;$i++) {
			echo "=> Members of group $($args[$i]) :"
			(Get-ADGroupMember $args[$i]).SamAccountName | sort
		}
	}
}
function showSID { (whoisUSER @args).sid.value }
function whoisSID { (whoisUSER @args).SamAccountName }
function whoisUSER {
	$argc=$args.Count
	if ( $argc -eq 0) {
		Get-ADUser -Identity $env:username -Properties AccountLockoutTime , BadLogonCount , Created , LastBadPasswordAttempt , PasswordLastSet
	} else {
		for($i=0;$i -lt $argc;$i++) {
			echo "=> $($args[$i]) :"
			Get-ADUser -Identity $($args[$i]) -Properties AccountLockoutTime , BadLogonCount , Created , LastBadPasswordAttempt, PasswordLastSet
		}
	}
}
function showOUOfComputer {
	$argc=$args.Count
	if ( $argc -eq 0) {
		Get-ADComputer -Identity $env:COMPUTERNAME -Properties DistinguishedName,LastKnownParent,MemberOf | Out-String -Stream | sls DistinguishedName,LastKnownParent,MemberOf
	} else {
		for($i=0;$i -lt $argc;$i++) {
			echo "=> $($args[$i]) :"
			Get-ADComputer -Identity $($args[$i]) -Properties DistinguishedName,LastKnownParent,MemberOf | Out-String -Stream | sls DistinguishedName,LastKnownParent,MemberOf
		}
	}
}

function setLogonDC {
	$FUNCNAME = $MyInvocation.MyCommand.Name
	"=> Running $FUNCNAME ..."

	echo "==> Current DC from `"(Get-ADDomainController).Name`" is :"
	$(Get-ADDomainController).Name
	echo "==> Current DC from Get-ADDomainController is : "
	$global:DC = (Get-ADDomainController -Discover)
	echo $DC.Name
	echo "==> Current LogonDC from `"`$ENV:LOGONSERVER.Substring(2)`" is :"
	$global:LogonDC = $ENV:LOGONSERVER.Substring(2)
	echo $LogonDC
	echo "==> Current Site from (Get-ADDomainController -Discover).Site is :"
	echo $DC.Site

#	return
	if( ! $DC.Name.Contains( $LogonDC -replace "\d" ) ) {
#		"=> Current DC from nltest /dsgetdc:" + $ENV:USERDNSDOMAIN
#		nltest /dsgetdc:$ENV:USERDNSDOMAIN | sls DC: | % { ( $_ -split('\s+|\.') )[2].substring(2) }
#		"=> Current Site Name from `"nltest /dsgetsite:`""
#		nltest /dsgetsite

		"=> Switching the default DC to " + $LogonDC + " ..."
		$global:PSDefaultParameterValues = @{ "*-AD*:Server" = $LogonDC } # cf. https://serverfault.com/a/528834/312306
		"=> The default DC is now " + $(Get-ADDomainController).Name
	}

#	"=> List of DCs via `"nltest /dclist:`""
#	nltest /dclist:
}

function main {
	$FUNCNAME = $MyInvocation.MyCommand.Name
	"=> Running $FUNCNAME ..."
	setLogonDC
}

main
