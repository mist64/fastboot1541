~/tmp/cc65-2.13.2/src/ca65/ca65 start.s &&
~/tmp/cc65-2.13.2/src/ld65/ld65 -C start.cfg start.o -o start.prg -Ln start.lbl &&
~/tmp/cc65-2.13.2/src/ca65/ca65 1541.s &&
~/tmp/cc65-2.13.2/src/ld65/ld65 -C 1541.cfg 1541.o -o 1541.bin -Ln 1541.lbl &&
#dd if=/dev/zero of=autostart.d64 bs=256 count=683 &&
dd if=/dev/zero bs=256 count=375 > autostart.d64 &&
dd if=1541.bin bs=256 count=1 >> autostart.d64 &&
dd if=/dev/zero bs=256 count=307 >> autostart.d64 &&
c1541 autostart.d64 < c1541script.txt
