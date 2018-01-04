# Copyright 1999-2016 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: $

EAPI="5"

PYTHON_COMPAT=( python{2_6,2_7} )

inherit autotools eutils flag-o-matic multilib python-single-r1

DESCRIPTION="LinuxCNC "
HOMEPAGE="http://linuxcnc.org/"
SRC_URI="https://github.com/jepler/${PN}-mirror/archive/v${PV}.tar.gz -> ${P}.tar.gz"

LICENSE="LGPL-3"
SLOT="linuxcnc-2.7"
KEYWORDS="~amd64 ~x86"
IUSE="gtk modbus python rtai simulator usb X"
# TODO: add shmdrv use flag
REQUIRED_USE="python? ( ${PYTHON_REQUIRED_USE} )
	rtai? ( !simulator )
	"

DEPEND="dev-lang/tcl
	dev-lang/tk
	dev-tcltk/tkimg
	dev-tcltk/tclx
	dev-libs/boost[python]
	modbus? ( dev-libs/libmodbus )
	dev-libs/pth
	dev-tcltk/bwidget
	gtk? ( x11-libs/gtk+:2 )
	x11-libs/libXinerama
	usb? ( virtual/libusb )
	python? ( dev-lang/python:2.7[tk] )
	rtai? ( >=sys-libs/rtai-4.0 )
	python? ( virtual/opengl virtual/glu )
	${PYTHON_DEPS}
	"
RDEPEND="${DEPEND}
	X? ( python? ( dev-python/libgnome-python ) )
	python? ( dev-python/yapps )"

S="${WORKDIR}/${P}/src"

src_prepare() {
# 	epatch "${FILESDIR}/rtai-config-fix-${PV}.patch"
	eautoreconf
	epatch "${FILESDIR}/remove_ldconfig-${PV}.patch"
	epatch "${FILESDIR}/hm2_pci.patch"
	epatch "${FILESDIR}/Makefile-${PV}.patch"
# 	epatch "${FILESDIR}/tcl8.6.patch"
# 	epatch "${FILESDIR}/fix_modinc_include.patch"
	use simulator && epatch "${FILESDIR}/remove_lxrt.patch"
}

src_configure() {
	myconf="--prefix=${EPREFIX}/usr --with-kernel-headers=/usr/src/linux/ $(use_with modbus libmodbus)"

	use !gtk && myconf="${myconf} --disable-gtk"
	#use rt && myconf="${myconf} --with-rt-preempt"
	use simulator && myconf="${myconf} --with-realtime=uspace"
	use !usb && myconf="${myconf} --without-libusb-1.0"
	use rtai && myconf="${myconf} --with-realtime=${EPREFIX}/usr/realtime --with-module-dir=${EPREFIX}/usr/lib/linuxcnc/rtai/"
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

	insinto "/usr/share/linuxcnc/"
	doins Makefile.inc
	
	insinto "/etc/linuxcnc/"
	doins "../scripts/rtapi.conf"

	doicon "../linuxcncicon.png"
	make_desktop_entry linuxcnc LinuxCNC linuxcnc 'Science;Robotics'
}

pkg_postinst() {
	elog "Remember to add:"
	elog "* - memlock 20480"
	elog "into /etc/security/limits.conf"
}
