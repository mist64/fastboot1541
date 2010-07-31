~/tmp/cc65-2.13.2/src/ca65/ca65 start.s &&
~/tmp/cc65-2.13.2/src/ld65/ld65 -C start.cfg start.o -o start.prg &&
dd if=/dev/zero of=autostart.d64 bs=256 count=683 &&
c1541 autostart.d64 < c1541script.txt
