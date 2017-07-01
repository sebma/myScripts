@sc query lanmanworkstation | findstr "SERVICE_NAME RUNNING"
@sc query lanmanserver | findstr "SERVICE_NAME RUNNING"
@net share | findstr -i admin
