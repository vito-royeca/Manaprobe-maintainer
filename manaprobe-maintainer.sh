#! /bin/bash

# exec
/usr/local/bin/manaprobe-maintainer

# delete temp files
find /tmp -name "managuide-*" -exec rm -fv {} \;
