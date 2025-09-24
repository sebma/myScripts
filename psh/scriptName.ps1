#!/usr/bin/env pwsh
# https://stackoverflow.com/a/43643346/5649639
function toto() {
echo "=> From a function code block :"
"PSCommandPath = " + $PSCommandPath
"MyInvocation.ScriptName = " + $MyInvocation.ScriptName
"MyInvocation.MyCommand.Name = " + $MyInvocation.MyCommand.Name
"MyInvocation.PSCommandPath = " + $MyInvocation.PSCommandPath
}

toto
echo "=> From main code block :"
"PSCommandPath = " + $PSCommandPath
"MyInvocation.ScriptName = " + $MyInvocation.ScriptName
"MyInvocation.MyCommand.Name = " + $MyInvocation.MyCommand.Name
"MyInvocation.PSCommandPath = " + $MyInvocation.PSCommandPath
echo ""
"Conclusion : Use PSCommandPath = " + $PSCommandPath
