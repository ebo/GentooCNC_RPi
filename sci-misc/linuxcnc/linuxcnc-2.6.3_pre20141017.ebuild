# Copyright 1999-2014 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: $

EAPI="5"

PYTHON_COMPAT=( python{2_6,2_7} )

inherit autotools eutils multilib python-single-r1

DESCRIPTION="LinuxCNC "
HOMEPAGE="http://linuxcnc.org/"
SRC_URI="mirror://sourceforge/gentoocnc/distfiles/${P}.tar.gz"

LICENSE="LGPL-3"
SLOT="0"
KEYWORDS="~amd64 ~arm ~x86"
IUSE="gtk modbus python rt rtai simulator usb X +xenomai"
# TODO: add shmdrv use flag
REQUIRED_USE="python? ( ${PYTHON_REQUIRED_USE} )
	xenomai? ( !simulator !rt !rtai )
	rt? ( !simulator !xenomai !rtai )
	rtai? ( !simulator !xenomai !rt )
	"

# TODO: dependencies for 'rt' use flag

DEPEND="dev-lang/tcl
	dev-lang/tk
	dev-libs/boost[python]
	modbus? ( dev-libs/libmodbus )
	dev-libs/pth
	dev-tcltk/bwidget
	xenomai? ( sys-libs/xenomai )
	gtk? ( x11-libs/gtk+ )
	x11-libs/libXinerama
	usb? ( virtual/libusb )
	python? ( dev-lang/python:2.7[tk] )
	virtual/opengl
	virtual/glu
	${PYTHON_DEPS}
	"
RDEPEND="${DEPEND}
	X? ( python? ( dev-python/libgnome-python ) )
	python? ( dev-python/yapps )"

S="${S}/src"

src_prepare() {
	eautoreconf
	epatch "${FILESDIR}/remove_ldconfig.patch"
	epatch "${FILESDIR}/tcl8.6.patch"
	epatch "${FILESDIR}/fix_modinc_include.patch"
}

src_configure() {
	myconf="--enable-drivers --enable-usermode-pci"

	use !gtk && myconf="${myconf} --disable-gtk"
	use rt && myconf="${myconf} --with-rt-preempt"
	use simulator && myconf="${myconf} --with-posix" # --with-threads=posix
	use !usb && myconf="${myconf} --without-libusb-1.0"
	use rtai && myconf="${myconf} --with-rtai-config=/usr/realtime/bin/rtai-config --with-rt-preempt --enable-shmdrv"
	use xenomai && myconf="${myconf} --with-xenomai"
	use X && myconf="${myconf} --with-x"

	# TODO: fix that - get python version
	use python && myconf="${myconf} --with-python=/usr/bin/python2.7 --with-boost-python=boost_python-2.7"
	use !python && myconf="${myconf} --disable-python"

	econf ${myconf}
}

src_install() {
	emake DESTDIR="${D}" install

	local envd="${T}/51linuxcnc"
	cat > "${envd}" <<-EOF
		LDPATH="${EPREFIX}/usr/$(get_libdir)/linuxcnc:${EPREFIX}/usr/$(get_libdir)/linuxcnc/xenomai"
	EOF
	doenvd "${envd}"
	
	insinto "${EPREFIX}/usr/share/linuxcnc/"
	doins Makefile.inc
}
