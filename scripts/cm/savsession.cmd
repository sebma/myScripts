@pushd p:\putty
@tar -cvf- Sessions | gzip -9v > PuTTYSessions.tar.gz
@popd
