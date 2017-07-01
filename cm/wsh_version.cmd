@echo off
echo wscript.echo vbCrLf ^& "Microsoft Windows Script Host Version: " ^& ScriptEngineMajorVersion ^& "." ^& ScriptEngineMinorVersion ^& "." ^& ScriptEngineBuildVersion> wsh_version_tmp.vbs
cscript -nologo wsh_version_tmp.vbs
del wsh_version_tmp.vbs
