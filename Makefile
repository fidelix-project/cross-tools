WGET=wget
GPG=gpg
WORKDIR=$(abspath ./work)
DOWNLOADDIR=$(WORKDIR)/download
BUILDDIR=$(WORKDIR)/build
CONFIG=.config

null:=
space:= $(null) $(null)
comma:= ,

ifneq ($(wildcard .config), )

include .config

PATH:=$(DESTDIR)/bin:$(PATH)
export PATH

### Enabled Languages
ifeq ($(GCC_LANG_C), y)
ENABLED_LANGUAGES+= c
endif
ifeq ($(GCC_LANG_CXX), y)
ENABLED_LANGUAGES+= c++
endif
ifeq ($(GCC_LANG_OBJC), y)
ENABLED_LANGUAGES+= objc
endif
ifeq ($(GCC_LANG_FORTRAN), y)
ENABLED_LANGUAGES+= fortran
endif
ifeq ($(GCC_LANG_ADA), y)
ENABLED_LANGUAGES+= ada
endif
ifeq ($(GCC_LANG_D), y)
ENABLED_LANGUAGES+= d
endif
ifeq ($(GCC_LANG_GO), y)
ENABLED_LANGUAGES+= go
endif
ENABLED_LANGUAGES:=$(subst $(space),$(comma),$(strip $(ENABLED_LANGUAGES)))

### Target specific options

# linux-musl
ifdef TARGET_LINUX_MUSL
TARGET_OS=linux-musl
BINUTILS_CONFIGURE_ARGS+= \
	--with-sysroot="$(SYSROOT)"
# Libsanitizer doesn't work with musl. See
# https://gitlab.alpinelinux.org/alpine/aports/issues/9643 for details.
GCC_CONFIGURE_ARGS+= \
	--with-sysroot="$(SYSROOT)" \
	--disable-libsanitizer

# linux-gnu
else ifdef TARGET_LINUX_GNU
TARGET_OS=linux-gnu
BINUTILS_CONFIGURE_ARGS+= \
	--with-sysroot="$(SYSROOT)"
GCC_CONFIGURE_ARGS+= \
	--with-sysroot="$(SYSROOT)"

# elf
else ifdef TARGET_ELF
TARGET_OS=elf
SYSROOT=/var/empty
# Most libraries for more advanced features fail to compile when building a
# bare elf target.
GCC_CONFIGURE_ARGS+= \
	--without-headers \
	--disable-libssp \
	--disable-libquadmath \
	--disable-libatomic \
	--disable-libgomp \
	--disable-libvtv \
	--disable-libstdcxx
endif

# Set the TARGET triplet
ifeq ($(TARGET_VENDOR), "")
TARGET=$(TARGET_MACHINE)-$(TARGET_OS)
else
TARGET=$(TARGET_MACHINE)-$(TARGET_VENDOR)-$(TARGET_OS)
endif

SYSROOT:=$(abspath $(patsubst "%",%,$(SYSROOT)))
DESTDIR:=$(abspath $(patsubst "%",%,$(DESTDIR)))
BINUTILS_VERSION:=$(patsubst "%",%,$(BINUTILS_VERSION))
GCC_VERSION:=$(patsubst "%",%,$(GCC_VERSION))

BINUTILS_TARBALL=$(DOWNLOADDIR)/binutils-$(BINUTILS_VERSION).tar.xz
GCC_TARBALL=$(DOWNLOADDIR)/gcc-$(GCC_VERSION).tar.xz
BINUTILS_SRCDIR=$(BUILDDIR)/binutils-$(BINUTILS_VERSION)
GCC_SRCDIR=$(BUILDDIR)/gcc-$(GCC_VERSION)
BINUTILS_BUILDDIR=$(BUILDDIR)/binutils-build
GCC_BUILDDIR=$(BUILDDIR)/gcc-build

BINUTILS_CONFIGURE_ARGS+= \
	--prefix="$(DESTDIR)" \
	--target=$(TARGET) \
	--disable-multilib \
	--disable-werror \
	--with-system-zlib

GCC_CONFIGURE_ARGS+= \
	--prefix="$(DESTDIR)" \
	--target=$(TARGET) \
	--disable-multilib \
	--disable-werror \
	--with-system-zlib \
	--enable-languages=$(ENABLED_LANGUAGES)

.PHONY: build
build: $(DESTDIR)/config-$(TARGET)
	$(MAKE) $(WORKDIR)
	$(MAKE) $(DESTDIR)
	$(MAKE) download
	$(MAKE) gcc

$(DESTDIR)/config-$(TARGET): $(CONFIG)
	cp $^ $@

.SECONDARY: download
download: $(BINUTILS_TARBALL) $(GCC_TARBALL)

.DELETE_ON_ERROR: $(BINUTILS_TARBALL) $(GCC_TARBALL)
$(BINUTILS_TARBALL):
	$(MAKE) $(DOWNLOADDIR)
	cd $(DOWNLOADDIR) && $(WGET) https://ftp.gnu.org/gnu/binutils/binutils-$(BINUTILS_VERSION).tar.xz
	cd $(DOWNLOADDIR) && $(WGET) https://ftp.gnu.org/gnu/binutils/binutils-$(BINUTILS_VERSION).tar.xz.sig
	$(GPG) --keyring misc/gnu-keyring.gpg --verify $@.sig

$(GCC_TARBALL):
	$(MAKE) $(DOWNLOADDIR)
	cd $(DOWNLOADDIR) && $(WGET) https://ftp.gnu.org/gnu/gcc/gcc-$(GCC_VERSION)/gcc-$(GCC_VERSION).tar.xz
	cd $(DOWNLOADDIR) && $(WGET) https://ftp.gnu.org/gnu/gcc/gcc-$(GCC_VERSION)/gcc-$(GCC_VERSION).tar.xz.sig
	$(GPG) --keyring misc/gnu-keyring.gpg --verify $@.sig

.PHONY: binutils
binutils: $(BINUTILS_BUILDDIR)/Makefile
	$(MAKE) -C $(BINUTILS_BUILDDIR)
	$(MAKE) -C $(BINUTILS_BUILDDIR) install

$(BINUTILS_SRCDIR): | $(BINUTILS_TARBALL) $(SRCDIR)
	cd $(BUILDDIR) && tar xJvf $(BINUTILS_TARBALL)

$(BINUTILS_BUILDDIR)/Makefile: | $(BINUTILS_BUILDDIR) $(BINUTILS_SRCDIR)
	cd $(BINUTILS_BUILDDIR) && \
		$(BINUTILS_SRCDIR)/configure $(BINUTILS_CONFIGURE_ARGS)

.SECONDARY: gcc
gcc: $(GCC_BUILDDIR)/Makefile binutils
	$(MAKE) -C $(GCC_BUILDDIR)
	$(MAKE) -C $(GCC_BUILDDIR) install

$(GCC_SRCDIR): | $(GCC_TARBALL) $(SRCDIR)
	cd $(BUILDDIR) && tar xJvf $(GCC_TARBALL)

$(GCC_BUILDDIR)/Makefile: | $(GCC_BUILDDIR) $(GCC_SRCDIR)
	cd $(GCC_BUILDDIR) && \
		$(GCC_SRCDIR)/configure $(GCC_CONFIGURE_ARGS)

$(WORKDIR) $(DOWNLOADDIR) $(BUILDDIR) $(DESTDIR) $(SYSROOT) \
$(BINUTILS_BUILDDIR) $(GCC_BUILDDIR):
	mkdir -p $@

endif

.PHONY: oldconfig xconfig gconfig menuconfig config silentoldconfig \
	update-po-config localmodconfig localyesconfig defconfig

oldconfig xconfig gconfig menuconfig config silentoldconfig update-po-config \
	localmodconfig localyesconfig defconfig:
	$(MAKE) -C kconfig $@

.PHONY: clean clean-build show-var
clean: clean-build
	rm -f $(CONFIG)
	$(MAKE) -C kconfig clean

clean-build:
	rm -rf $(WORKDIR)
	rm -f .stamp*

show-var:
ifndef VARNAME
	$(error VARNAME must be set to the name of the variable to print)
else
	@echo $($(VARNAME))
endif

