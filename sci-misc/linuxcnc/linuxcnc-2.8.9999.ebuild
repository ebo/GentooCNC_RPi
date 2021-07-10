# Copyright 1999-2020 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI="7"

PYTHON_COMPAT=( python3_{6,7,8} )

#inherit autotools eutils flag-o-matic multilib python-single-r1
inherit autotools git-r3 toolchain-funcs python-single-r1

DESCRIPTION="LinuxCNC "
HOMEPAGE="http://linuxcnc.org/"
#SRC_URI="https://github.com/LinuxCNC/${PN}/archive/v${PV}.tar.gz -> ${P}.tar.gz"
EGIT_REPO_URI="https://github.com/ebo/linuxcnc.git"
EGIT_BRANCH="2.8"
EGIT_BRANCH="pncconf-gtk3"
# clean: 4fe346f7f250a9fbda9f5f87bf27c287a239b3d5
#

LICENSE="LGPL-3"
SLOT="0"
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
#	python? ( dev-python/yapps )
RDEPEND="${DEPEND}
	X? ( python? ( dev-python/libgnome-python ) )
	!sci-misc/machinekit"

S="${S}/src"

#PATCHES=(
#	"${FILESDIR}"/config.patch
#)
#	"${FILESDIR}"/udev_rules.patch

src_prepare() {
	default
	eapply_user

	AT_M4DIR=m4 eautoreconf
	eautomake
}

src_configure() {
	myconf="--prefix=${EPREFIX}/usr --enable-non-distributable=yes --with-kernel-headers=/usr/src/linux/ $(use_with modbus libmodbus)"

	 myconf="${myconf} --with-realtime=uspace"

	#use !gtk && myconf="${myconf} --disable-gtk"
	#use rt && myconf="${myconf} --with-rt-preempt"
	#use simulator && myconf="${myconf} --with-realtime=uspace"
	#use !usb && myconf="${myconf} --without-libusb-1.0"
	#use rtai && myconf="${myconf} --with-realtime=${EPREFIX}/usr/realtime --with-module-dir=${EPREFIX}/usr/lib/linuxcnc/rtai/"
	#use X && myconf="${myconf} --with-x"

	# TODO: fix that - get python version
	use python && myconf="${myconf} --with-python=${PYTHON} --with-boost-python=boost_python$(echo ${EPYTHON#python} | sed 's/\.//')"
	use !python && myconf="${myconf} --disable-python"

	econf ${myconf}
}

src_install() {
	emake DESTDIR="${D}" install

	python_optimize

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
