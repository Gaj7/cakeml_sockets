This project builds with the following version of the CakeML compiler: https://cakeml.org/regression/artefacts/690/cake-x64-64.tar.gz. Newer versions of the compiler introduced the `instream` and `outstream` types, which prevent the use of the TextIO functions with our file descriptors.

To build the project, enter the sockets directory, and type `make CAKE_DIR=x` where `x` is the path/directory which includes the cake executable and `basis_ffi.c`. To test the sockets, run `serverTest` first, then `clientTest`.
