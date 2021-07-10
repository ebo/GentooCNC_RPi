# Copyright 1999-2020 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=7

PYTHON_COMPAT=( python3_{6,7} )

#inherit autotools eutils git-r3 multilib flag-o-matic python-r1 toolchain-funcs
inherit autotools git-r3 toolchain-funcs python-single-r1

DESCRIPTION="MachineKit "
HOMEPAGE="http://www.machinekit.io/"
SRC_URI=""
EGIT_REPO_URI="https://github.com/zultron/machinekit.git"
#EGIT_BRANCH="zultron/2019-07-03-2.8-mk-hal-build"
EGIT_BRANCH="2020-05-09-mk-hal-lcnc-ci"

LICENSE="LGPL-3"
SLOT="0"
KEYWORDS="~amd64 ~arm ~x86"
IUSE="gtk usb X doc modbus +rt +rtai +simulator +xenomai"

# TODO: add shmdrv use flag
REQUIRED_USE="${PYTHON_REQUIRED_USE}"

RDEPEND="
	${PYTHON_DEPS}
	>=dev-libs/boost-1.70:=[python]
	!sci-misc/linuxcnc
	dev-libs/libcgroup
	X? ( dev-tcltk/tkimg )
	gtk? ( dev-python/pygtk )"
# 	X? ( dev-python/libgnome-python )
#	xenomai? ( !simulator !rt !rtai )
#	rt? ( !simulator !xenomai !rtai )
#	rtai? ( !simulator !xenomai !rt )

# TODO: dependencies for 'rt' use flag
	#rt? ( sys-kernel/rt-sources )
	#modbus? ( >=dev-libs/libmodbus-3.1.0 )
#	dev-libs/boost[python]
DEPEND="
	${RDEPEND}
	>=sys-devel/automake-1.16.1-r2
	dev-lang/tcl
	dev-lang/tk
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
	dev-lang/python[tk]
	dev-python/protobuf-python
	dev-libs/protobuf
	x11-libs/libXmu
	virtual/opengl
	virtual/glu
	"
	#python? ( dev-python/yapps )
BDEPEND="virtual/pkgconfig"

#PATCHES=(
#	"${FILESDIR}"/LDLIBS_tirpc.patch
#)
#	"${FILESDIR}"/udev_rules.patch

S="${S}/src"

src_prepare() {
	# FIXME: a hack patch for tirpc
	sed -i "s%AC_CHECK_HEADER(\[rpc\/rpc.h\]%PKG_CHECK_MODULES(\[TIRPC\],\[libtirpc\],\n       [CPPFLAGS=\"\$CPPFLAGS \$TIRPC_CFLAGS -DHAVE_RPC_RPC_H\"; LIBS=\"\$LIBS \$TIRPC_LIBS\";\],\n       [AC_MSG_ERROR(\[libtirpc requested but library not found\])]\n)\nAC_CHECK_HEADER(\[rpc\/rpc.h\]%" configure.ac || die

	default
	eapply_user

	AT_M4DIR=m4 eautoreconf

	eautomake
}

src_configure() {
	myconf="--enable-drivers --enable-usermode-pci --with-platform-pc"

	myconf="${myconf} --with-realtime=uspace --with-hal=machinekit-hal"


	# the modern versions of readline are not compatible with GPL-2, so
	# work around it by not distributing the binaries.
	myconf="${myconf} --enable-non-distributable=yes"

	use !gtk && myconf="${myconf} --disable-gtk"
	use rt && myconf="${myconf} --with-rt-preempt"
	use simulator && myconf="${myconf} --with-posix" # --with-threads=posix
	use !usb && myconf="${myconf} --without-libusb-1.0"
	use rtai && myconf="${myconf} --with-rtai-config=/usr/realtime/bin/rtai-config --with-rtai-kernel --enable-shmdrv"
	use xenomai && myconf="${myconf} --with-xenomai"
	use X && myconf="${myconf} --with-x"

	myconf="${myconf} "$(use_with modbus "libmodbus")

	use doc && myconf="${myconf} --enable-build-documentation"

	tc-export PKG_CONFIG
	export CFLAGS="$(${PKG_CONFIG} --cflags libtirpc)"
	export CXXFLAGS="$(${PKG_CONFIG} --cflags libtirpc)"
	export LDLIBS="$(${PKG_CONFIG} --libs libtirpc)"

	export FAKED_MODE=1

	einfo "****************** boost_"${EPYTHON/./}
	econf --with-boost-python="boost_${EPYTHON/./}" ${myconf}
}

src_install() {
	"${PYTHON}" -OO -m compileall -q -f -d "${sitedir}" "${D}${sitedir}"
	einfo "====================================="

	emake DESTDIR="${D}" install

	python_optimize

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

	#mkdir -p
	#insinto "/lib/udev/rules.d/"
	#doins "${envd}"
	newins ${envd} /lib/udev/rules.d/${envd}

	#insinto "/usr/share/machinekit/"
	# FIXME: will documentation be automatically installed? sudo apt-get install machinekit-manual-pages
	#doins Makefile.inc
	newins Makefile.inc /usr/share/machinekit/Makefile.inc
}
