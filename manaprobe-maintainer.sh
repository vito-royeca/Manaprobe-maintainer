#! /bin/bash

# exec
/usr/local/bin/manaprobe-maintainer

# delete temp files
find /tmp -name "manaprobe-*" -exec rm -fv {} \;
find /tmp -name "_*" -exec rm -fv {} \;
