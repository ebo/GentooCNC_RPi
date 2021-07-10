# Copyright 1999-2021 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=7

PYTHON_COMPAT=( python3_{6,7,8,9} )
#PYTHON_COMPAT=( python2_{7} )

#inherit autotools eutils multilib python-single-r1 flag-o-matic git-r3
inherit autotools git-r3 toolchain-funcs python-single-r1

DESCRIPTION="MachineKit "
HOMEPAGE="http://www.machinekit.io/"
SRC_URI=""
#EGIT_REPO_URI="https://github.com/zultron/machinekit-hal.git"
#EGIT_COMMIT="9fca994e08e3f8384498e78ea8e8baa1c899e4db"
#SRC_URI="machinekit-hal-20200430.tgz"
#RESTRICT="fetch"
#EGIT_REPO_URI="https://github.com/ebo/machinekit-hal.git"
if false ; then
	EGIT_REPO_URI="https://github.com/machinekit/machinekit-hal.git"
	PATCHES=(
		"${FILESDIR}"/config.patch
	)
elif true ; then
	EGIT_REPO_URI="https://github.com/ebo/machinekit-hal.git"
	EGIT_BRANCH="2020-05-09-mk-hal-lcnc-ci"
	PATCHES=(
		"${FILESDIR}"/config.patch
	)
elif true ; then
	EGIT_REPO_URI="https://github.com/ebo/machinekit-hal.git"
	#EGIT_BRANCH="2020-04-24-python3"
fi

LICENSE="LGPL-2"
SLOT="0"
KEYWORDS="~amd64 ~arm ~x86"
IUSE="gtk python usb X doc +modbus rt rtai simulator xenomai"

# TODO: add shmdrv use flag
REQUIRED_USE="${PYTHON_REQUIRED_USE}"

#REQUIRED_USE="python? ( ${PYTHON_REQUIRED_USE} )
#	xenomai? ( !simulator !rt !rtai )
#	rt? ( !simulator !xenomai !rtai )
#	rtai? ( !simulator !xenomai !rt )
#	"

RDEPEND="
	${PYTHON_DEPS}
	!sci-misc/linuxcnc
	dev-libs/libcgroup
	X? ( dev-tcltk/tkimg )"
#	gtk? ( python? ( dev-python/pygtk ) )
# 	X? ( python? ( dev-python/libgnome-python ) )

# TODO: dependencies for 'rt' use flag
	#rt? ( sys-kernel/rt-sources )
	#modbus? ( >=dev-libs/libmodbus-3.1.0 )
DEPEND="
	${RDEPEND}
	>=sys-devel/automake-1.16.1-r2
	dev-libs/concurrencykit
	dev-lang/tcl
	dev-lang/tk
	dev-libs/boost[python]
	dev-libs/jansson
	modbus? ( dev-libs/libmodbus )
	dev-libs/npth
	dev-libs/uriparser
	dev-python/cython
	dev-python/pyftpdlib
	dev-tcltk/bwidget
	net-dns/avahi
	>=net-libs/czmq-4.0.0
	net-libs/libwebsockets
	xenomai? ( sys-libs/xenomai )
	rtai? ( sys-libs/rtai )
	gtk? ( x11-libs/gtk+:3 )
	x11-libs/libXinerama
	usb? ( virtual/libusb:1 )
	dev-python/protobuf-python
	dev-libs/protobuf
	x11-libs/libXmu
	virtual/opengl
	virtual/glu
	dev-python/google-auth-oauthlib
	dev-libs/jansson
	dev-libs/uriparser
	net-libs/libwebsockets
	dev-libs/libcgroup
	dev-python/pyftpdlib
	dev-libs/libmodbus
	python? ( dev-python/yapps )
	"
#	python? ( dev-lang/python:2.7[tk] )

S="${S}/src"

src_prepare() {
	default
	eapply_user

	#sed -i "s%AX_PYTHON_DEVEL(>= 2.6)%AX_PYTHON_DEVEL(>= '2.6')%" configure.ac || die

	#sed -i "s%Exception, e%Exception as e%" ./machinetalk/nanopb/generator/nanopb_generator.py || die

	AT_M4DIR=m4 eautoreconf
	eautomake
}

src_configure() {
	# --enable-usermode-pci --with-platform-pc
	myconf="--enable-drivers"

	use !gtk && myconf="${myconf} --disable-gtk"
	#use rt && myconf="${myconf} --with-rt-preempt"
	use simulator && myconf="${myconf} --with-posix" # --with-threads=posix
	use !usb && myconf="${myconf} --without-libusb-1.0"
	use rtai && myconf="${myconf} --with-rtai-config=/usr/realtime/bin/rtai-config --with-rtai-kernel --enable-shmdrv"
	use xenomai && myconf="${myconf} --with-xenomai"
	use X && myconf="${myconf} --with-x"

	use python && myconf="${myconf} --with-python=${PYTHON}"
	use !python && myconf="${myconf} --disable-python"

	myconf="${myconf} "$(use_with modbus "libmodbus")

	use doc && myconf="${myconf} --enable-build-documentation"

	tc-export PKG_CONFIG
	export CFLAGS="$(${PKG_CONFIG} --cflags libtirpc)"
	export CXXFLAGS="$(${PKG_CONFIG} --cflags libtirpc)"
	export LDLIBS="$(${PKG_CONFIG} --libs libtirpc)"

	export FAKED_MODE=1

	econf ${myconf}
}

src_install() {
	"${PYTHON}" -OO -m compileall -q -f -d "${sitedir}" "${D}${sitedir}"

	emake DESTDIR="${D}" install

	python_optimize

	local envd="51machinekit"
	local threads=""
	if use rt ; then
		threads="rt";
	elif use xenomai ; then
		threads="xenomai"
	elif use simulator ; then
		threads="posix";
	elif use rtai ; then
		threads="rtai";
	fi
	cat > "${T}/${envd}" <<-EOF
		LDPATH="${EPREFIX}/usr/$(get_libdir)/linuxcnc:${EPREFIX}/usr/$(get_libdir)/linuxcnc/${threads}"
	EOF

	#mkdir -p
	insinto "/lib/udev/rules.d/"
	doins "${T}/${envd}"
	#newins ${T}/${envd} /lib/udev/rules.d/${envd}

	insinto "/usr/share/machinekit/"
	doins Makefile.inc
	#newins Makefile.inc /usr/share/machinekit/Makefile.inc

	# FIXME: will documentation be automatically installed? sudo apt-get
	#        install machinekit-manual-pages
}
