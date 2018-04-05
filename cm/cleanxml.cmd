@set file=%1
@set filePrefix=%~n1
tidy -xml -indent %file% > %filePrefix%_clean.xml
