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

