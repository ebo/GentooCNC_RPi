# Copyright 1999-2016 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Id$

EAPI="5"

PYTHON_COMPAT=( python{2_6,2_7} )

inherit autotools eutils git-r3 multilib python-single-r1

DESCRIPTION="MachineKit "
HOMEPAGE="http://www.machinekit.io/"
SRC_URI=""
EGIT_REPO_URI="git://github.com/machinekit/machinekit.git"


LICENSE="LGPL-3"
SLOT="0"
KEYWORDS="~amd64 ~arm ~x86"
IUSE="gtk modbus python rt rtai +simulator usb X xenomai"
# TODO: add shmdrv use flag
REQUIRED_USE="python? ( ${PYTHON_REQUIRED_USE} )
	xenomai? ( !simulator !rt !rtai )
	rt? ( !simulator !xenomai !rtai )
	rtai? ( !simulator !xenomai !rt )
	"

# TODO: dependencies for 'rt' use flag

DEPEND="${PYTHON_DEPS}
	dev-lang/tcl
	dev-lang/tk
	dev-libs/boost[python]
	dev-libs/jansson
	modbus? ( <dev-libs/libmodbus-3.1.0 )
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
	rt? ( sys-kernel/rt-sources )
	gtk? ( x11-libs/gtk+ )
	x11-libs/libXinerama
	usb? ( virtual/libusb )
	python? ( dev-lang/python:2.7[tk] )
	dev-python/protobuf-python
	dev-libs/protobuf
	x11-libs/libXmu
	virtual/opengl
	virtual/glu
	${PYTHON_DEPS}
	"
RDEPEND="${DEPEND}
	python? ( dev-python/yapps )
	!sci-misc/linuxcnc
	X? ( dev-tcltk/tkimg )
	gtk? ( python? ( dev-python/pygtk ) )"
# 	X? ( python? ( dev-python/libgnome-python ) )

S="${S}/src"

src_prepare() {
 	AT_M4DIR=m4 eautoreconf
# 	epatch "${FILESDIR}/libwebsockets.patch"
	epatch "${FILESDIR}/remove_ldconfig.patch"
# 	epatch "${FILESDIR}/halcomp.patch"
# 	epatch "${FILESDIR}/tcl8.6.patch"
# 	epatch "${FILESDIR}/fix_modinc_include.patch"
}

src_configure() {
	myconf="--enable-drivers --enable-usermode-pci --with-platform-pc"

	use !gtk && myconf="${myconf} --disable-gtk"
	use rt && myconf="${myconf} --with-rt-preempt"
	use simulator && myconf="${myconf} --with-posix" # --with-threads=posix
	use !usb && myconf="${myconf} --without-libusb-1.0"
	use rtai && myconf="${myconf} --with-rtai-config=/usr/realtime/bin/rtai-config --with-rtai-kernel --enable-shmdrv"
	use xenomai && myconf="${myconf} --with-xenomai"
	use X && myconf="${myconf} --with-x"

	use python && myconf="${myconf} --with-python=${PYTHON} --with-boost-python=boost_python-${EPYTHON:6}"
	use !python && myconf="${myconf} --disable-python"
	
	myconf="${myconf} "$(use_with modbus "libmodbus")

	econf ${myconf}
}

src_install() {
	emake DESTDIR="${D}" install

	local envd="${T}/51machinekit"
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
	cat > "${envd}" <<-EOF
		LDPATH="${EPREFIX}/usr/$(get_libdir)/linuxcnc:${EPREFIX}/usr/$(get_libdir)/linuxcnc/${threads}"
	EOF
	doenvd "${envd}"
	
	insinto "${EPREFIX}/usr/share/machinekit/"
	doins Makefile.inc
}
