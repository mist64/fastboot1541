# fastboot1541

*fastboot1541* is an autostart fastloader for the Commodore 64 and 1541 that fits into a single sector.

# Use

This is the fastest way to chain-load a second-stage high-speed fastloader, since it only transfers about half a sector worth of data using the slow serial protocol, yet loads the next stage at ~10x speed - and it's an autostart!

# Some Details

* The file overwrites stack addresses to gain execution, which should make it compatible with most ROM modifications and cartridges.
* The C64 part sits just above the stack.
* The 1541 part executes in-place in the buffer that was written when loading the program for the C64.
* The C64 and the 1541 part contain a simple bus protocol speeder that allows the screen to be on.
* You should hand-edit the second byte of the resulting sector on disk so that only the C64-specific bytes are actually transfered.
* Put this sector on track 18 to save some more time.
* Choose the optimal interleave for the chainloaded data. Maybe you can fit it on track 18 as well.

# More Details

The blog post at [pagetable.com/?p=568](http://www.pagetable.com/?p=568) explains everything in detail.

# License

Do anything you want with it, but giving credit and emailing me about its use is very much appreciated.

Improvements and corrections welcome!

# Author

Michael Steil <mist64@mac.com>
