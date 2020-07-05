Fidelix Cross Tools
===================

Fidelix Cross Tools is a system for building a cross toolchain. While it was
originally developed for use with Fidelix, it is capable of building cross
tools for many different target systems.

Cross Tools is capable of building only a toolchain suitable for a pre-existing operating system or a toolchain targeting bare metal (no operating system).

## Usage

Cross Tools uses a menu based configuration based on Kconfig. Before building,
make a suitable .config file:

    make menuconfig

If you are targeting an existing system, make sure the target system's root
filesystem is available at the location you set SYSROOT to.

Once the build has been configured to your liking and the target system is
present (if applicable), run Make to build the cross tools:

    make

Or if you have multiple cores, you may wish to enable parallel builds (these
substantially decrease the build time):

    make -j4

Assuming Make runs to completion successfully, you will be left with your cross tools in the directory you set DESTDIR to.

## Known Working GCC/Binutils Combinations

The following combinations of GCC/Binutils are known to work. There are
certainly more combinations that do work, these are just what have been tested.
If you do find another combination that works, it would be much appreciated if
you submit a pull request adding it to this table.

| GCC Version | Binutils Version |
| ----------- | ---------------- |
| 9.3.0       | 2.34             |

## Dependencies

For the cross tools to build successfully, the following packages must be
installed:
* gcc
* binutils
* gmp
* mpfr
* mpc
* zlib

For certain features to work, the following packages are required:
* isl
* bsdtar

Some distributions (such as Debian and RedHat) place the runtime versions of
these programs in different packages than the development versions. If you
experience issues building related to missing programs or libraries, make sure
you have both the runtime and development versions of the packages installed.

