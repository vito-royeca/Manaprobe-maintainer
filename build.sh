#! /bin/sh

rm -fvr .build/aarch64-unknown-linux-gnu/release/Manaprobe_maintainer.build/*.o
swift build -c release
#swift run manaprobe-maintainer
sudo cp .build/release/manaprobe-maintainer /usr/local/bin
