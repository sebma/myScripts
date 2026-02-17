using namespace System.Management.Automation.Language

function osFamily {
	if( !(Test-Path variable:IsWindows) ) {
		# $IsWindows is not defined, let's define it
		$platform = [System.Environment]::OSVersion.Platform
		$IsWindows = $IsLinux = $IsMacOS = $false
		$osFamily = "not defined yet"
		$IsWindows = $platform -eq "Win32NT"
		if( $isWindows ) {
			$osFamily = "Windows"
		} elseif( $platform -eq "Unix" ) {
			$osFamily = (uname -s)
			if( $osFamily -eq "Linux") {
				$IsLinux = $true
			} elseif( $osFamily -eq "Darwin" ) {
				$IsMacOS = $true
			} else {
				$osFamily = "NOT_SUPPORTED"
			}
		} else {
			$osFamily = "NOT_SUPPORTED"
		}
		return $IsWindows, $IsLinux, $IsMacOS, $osFamily
	} else {
		#Using PSv>5.1 where these variables are already defined
		if( $IsWindows )   { $osFamily = "Windows" }
		elseif( $IsLinux ) { $osFamily = "Linux" }
		elseif( $IsMacOS ) { $osFamily = "Darwin" }
		else { $osFamily = "NOT_SUPPORTED" }
		return $osFamily
	}
}

function source {
	param([Parameter(Mandatory)] $script)

	$errors = $null
	$script = Convert-Path $script
	$ast = [Parser]::ParseFile($script, [ref] $null, [ref] $errors)

	if ($errors) {
		Write-Error "Errors parsing script: $($errors -join ', ')"
		return
	}

	$functions = $ast.FindAll({ $args[0] -is [FunctionDefinitionAst] }, $true)
	foreach ($func in $functions) {
		$funcName = $func.Name
		$globalFuncBody = $func.Body.GetScriptBlock()
		Set-Item -Path "Function:\global:$funcName" -Value $globalFuncBody
	}

	$assignments = $ast.FindAll({ $args[0] -is [AssignmentStatementAst] }, $false)
	foreach ($assignment in $assignments) {
		# bring the assignment to this scope
		. ([scriptblock]::Create($assignment.ToString()))
		foreach ($target in $assignment.GetAssignmentTargets()) {
			# then get the value
			$varName = $target.VariablePath.ToString()
			$varValue = & ([scriptblock]::Create($target.ToString()))
			# and assign it to the caller's scope
			Set-Variable -Name $varName -Value $varValue -Scope Script
		}
	}
}

function sdiff {
	$argc=$args.Count
	if ( $argc -eq 2 ) {
		diff $(cat $args[0]) $(cat $args[1])
	}
}

if( ! ( Test-Path variable:IsWindows ) ) { $IsWindows, $IsLinux, $IsMacOS, $osFamily = osFamily } else { $osFamily = osFamily }

if( $isWindows ) {
	$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")
	function cd($dir) {
		if( $(alias cd *>$null;echo $?) ) { del alias:cd }
		if($dir -eq "-"){popd}
		elseif( ! $dir.Length ) {pushd ~}
		else {pushd $dir}
	}
} elseif( $IsLinux ) {
	$isAdmin = "TO BE DEFINED"
} elseif( $IsMacOS ) {
	$isAdmin = "TO BE DEFINED"
}

function isInstalled($cmd) { return gcm "$cmd" 2>$null | % Name }

if ( $(alias history *>$null;$?) ) { del alias:history }
function history() {
	cat  $(Get-PSReadlineOption).HistorySavePath
}

function histgrep($regExp) {
	if( $regExp.Length -eq 0 ) { $regExp="." }
	sls "$regExp" $(Get-PSReadlineOption).HistorySavePath | % Line
}

function pow2($a,$n) {
	return [math]::pow($a,$n)
}

#function nocomment($file) { egrep -v "^(#|;|$)" "$file" }
function nocomment {
	sls -n "^\s*(#|$|;|//)" @args | % Line
}

function times {
	# See https://github.com/lukesampson/psutils/blob/master/time.ps1
	Set-StrictMode -Off;

	# see http://stackoverflow.com/a/3513669/87453
	$cmd, $args = $args
	$args = @($args)
	$sw = [diagnostics.stopwatch]::startnew()
	& $cmd @args
	$sw.stop()

#	Write-Warning "$($sw.elapsed)"
	[Console]::Error.WriteLine( "$($sw.elapsed)" )
}

function findfiles {
	$argc=$args.Count
	if ( $argc -eq 1 ) {
		$dirName = "."
		$regexp = $args[0]
	} elseif ( $argc -eq 2 ) {
		$dirName = $args[0]
		$regexp = $args[1]
	} else {
		write-warning "Usage : [dirName] regexp"
		exit 1
	}

	dir -r -fo $dirName 2>$null | ? FullName -Match "$regexp" | % FullName
}
