# Il faut "sourcer" ce script avec ". resetPrompt.ps1"
function prompt {
	"PS $($executionContext.SessionState.Path.CurrentLocation)$('>' * ($nestedPromptLevel + 1)) "
	# .Link
	# https://go.microsoft.com/fwlink/?LinkID=225750
	# .ExternalHelp System.Management.Automation.dll-help.xml
}
