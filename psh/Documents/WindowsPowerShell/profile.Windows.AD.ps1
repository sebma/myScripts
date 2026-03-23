"=> Current DC from Get-ADDomainController is : "
$DC = (Get-ADDomainController -Discover).Name
echo $DC
"=> Current Site from (Get-ADDomainController -Discover).Site is :"
(Get-ADDomainController -Discover).Site

function findGroup ($myPattern) {
	$myPattern = '*'+$args[0]+'*'
	$DC = $env:LOGONSERVER.Substring(2)
	Get-ADGroup -Server $DC -Properties CN , CanonicalName , Created, Modified , Description -Filter { name -like $myPattern }
}
function findUser ($myPattern) {
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

