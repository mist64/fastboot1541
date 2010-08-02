ca65 start.s &&
ld65 -C start.cfg start.o -o start.prg &&
dd if=/dev/zero of=autostart.d64 bs=256 count=683 &&
c1541 autostart.d64 < c1541script.txt
