# Usage
To build the project, type `make CAKE_DIR=x` where `x` is the directory which includes the cake executable and basis_ffi.c. To test the sockets, run `serverTest` first, then `clientTest`.

# Status
Sockets should be working (both directions!) with the newest version of the compiler (`cake --version` = Wed Mar 27 10:58:50 2019 UTC).

# Licensing
The socket structure adapts file operations from the basis library to work with arbitrary file descriptors. Because code is adapted from the basis, the CakeML copyright notice is embedded as a comment into `SocketFFI.sml` where relevant.

# Misc
- If you need to terminate your program early, use Ctl+c. Using Ctl+z will result in the sockets not closing properly, and the program will likely fail to reacquire the socket port on the next execution (restarting fixes the issue).
