@echo off
set xsd_scheme=%1
if not defined xsd_scheme (
  echo "Usage:<%0> <xsd> <file1.xml> <file2.xml> <...>"
  exit/b 1
)
shift
::xml validate --err --xsd %xsd_scheme% %1 %2 %3 %4 %5 %6 %7 %8 %9
xmllint --noout --schema %xsd_scheme% %1 %2 %3 %4 %5 %6 %7 %8 %9
