# Copyright 1999-2020 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI="5"

PYTHON_COMPAT=( python{2_6,2_7} )

inherit autotools eutils git-r3 multilib python-single-r1

DESCRIPTION="MachineKit "
HOMEPAGE="http://www.machinekit.io/"
SRC_URI=""
EGIT_REPO_URI="https://github.com/ebo/machinekit.git"
EGIT_COMMIT="9239acbee0f84edd94615b5e33e40e724c913ff9"

LICENSE="LGPL-3"
SLOT="0"
KEYWORDS="~amd64 ~arm ~x86"
IUSE="gtk python usb X doc modbus rt rtai simulator xenomai"

# TODO: add shmdrv use flag
REQUIRED_USE="python? ( ${PYTHON_REQUIRED_USE} )
	xenomai? ( !simulator !rt !rtai )
	rt? ( !simulator !xenomai !rtai )
	rtai? ( !simulator !xenomai !rt )
	"

# TODO: dependencies for 'rt' use flag
	#rt? ( sys-kernel/rt-sources )
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
	gtk? ( x11-libs/gtk+:3 )
	x11-libs/libXinerama
	usb? ( virtual/libusb:1 )
	python? ( dev-lang/python:2.7[tk] )
	dev-python/protobuf-python
	dev-libs/protobuf
	x11-libs/libXmu
	virtual/opengl
	virtual/glu
	${PYTHON_DEPS}
	"
	#python? ( dev-python/yapps )
RDEPEND="${DEPEND}
	!sci-misc/linuxcnc
	dev-libs/libcgroup
	X? ( dev-tcltk/tkimg )
	gtk? ( python? ( dev-python/pygtk ) )"
# 	X? ( python? ( dev-python/libgnome-python ) )

S="${S}/src"

src_prepare() {
	AT_M4DIR=m4 eautoreconf
	epatch "${FILESDIR}/LDLIBS_tirpc.patch"
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

	use doc && myconf="${myconf} --enable-build-documentation"

	tc-export PKG_CONFIG
	export CFLAGS="$(${PKG_CONFIG} --cflags libtirpc)"
	export CXXFLAGS="$(${PKG_CONFIG} --cflags libtirpc)"
	export LDLIBS="$(${PKG_CONFIG} --libs libtirpc)"

	export FAKED_MODE=1

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

	insinto "/usr/share/machinekit/"

	# FIXME: will documentation be automatically installed? sudo apt-get install machinekit-manual-pages

	doins Makefile.inc
}
