# Copyright 1999-2014 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: $

EAPI="5"

PYTHON_COMPAT=( python{2_6,2_7,3_1,3_2,3_3} )

inherit multilib user

DESCRIPTION="Xenomai is a real-time development framework cooperating with the Linux kernel"
HOMEPAGE="http://www.xenomai.org/"
SRC_URI="http://download.gna.org/xenomai/stable/${P}.tar.bz2"

LICENSE="LGPL-3"
SLOT="0"
KEYWORDS="~amd64 ~arm ~x86"
IUSE="debug doc smp sep tsc quirks"


DEPEND="sys-kernel/xenomai-sources"
RDEPEND="${DEPEND}"

pkg_setup() {
	enewgroup xenomai
}

src_configure() {
	my_conf="--prefix=${ROOT}usr/xenomai"
		
	use smp && "--enable-smp"
	use debug && "--enable-debug"

	if [[ ${ARCH} == "x86" || ${ARCH} == "amd64" ]] ; then
		use tsc && my_conf="${my_conf} --enable-x86-tsc"
		use sep && my_conf="${my_conf} --enable-x86-sep"
	fi
	if [[ ${ARCH} == "arm" ]] ; then
		use tsc && my_conf="${my_conf} --enable-x86-tsc"
		use quirks && my_conf="${my_conf} --enable-arm-quirks"
	fi
	
	use !doc && my_conf="${my_conf} --disable-doc-install"
	use doc && my_conf="${my_conf} --enable-dbx --enable-asciidoc"

	econf ${my_conf}
}

src_install() {
	emake DESTDIR="${D}" install
	fowners -R :xenomai "${EPREFIX}/usr/xenomai"
	
	local envd="${T}/50xenomai"
	cat > "${envd}" <<-EOF
		PATH="${EPREFIX}/usr/xenomai/bin/"
		ROOTPATH="${EPREFIX}/usr/xenomai/bin/"
		LDPATH="${EPREFIX}/usr/xenomai/$(get_libdir)"
	EOF
	doenvd "${envd}"
	
	insinto "${EPREFIX}/etc/udev/rules.d/"
	newins "${FILESDIR}/udev.rule" 51-xenomai.rules
}