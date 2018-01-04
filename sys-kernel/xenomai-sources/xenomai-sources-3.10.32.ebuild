# Copyright 1999-2014 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: $

EAPI="5"
ETYPE="sources"
K_WANT_GENPATCHES="base extras experimental"
K_GENPATCHES_VER="39"
K_DEBLOB_AVAILABLE="1"
inherit kernel-2
detect_version
detect_arch

KEYWORDS="~amd64 ~arm ~x86"
HOMEPAGE="http://dev.gentoo.org/~mpagano/genpatches http://www.xenomai.org/"
IUSE="deblob experimental"

if [[ ${ARCH} == "amd64" ]] ; then
	XENO_ARCH="x86"
else
	XENO_ARCH=$ARCH
fi

IPIPE_PATCH_PN="ipipe-core"
IPIPE_PATCH_PV="3.10.32"
IPIPE_PATCH_P="${IPIPE_PATCH_PN}-${IPIPE_PATCH_PV}-${XENO_ARCH}-2"
XENO_PN="xenomai"
XENO_PV="2.6.3"
XENO_P="${XENO_PN}-${XENO_PV}"

DESCRIPTION="Full sources including the Gentoo and Xenomai patchset for the ${KV_MAJOR}.${KV_MINOR} kernel tree"
SRC_URI="${KERNEL_URI} ${GENPATCHES_URI} ${ARCH_URI} 
	http://download.gna.org/adeos/patches/v3.x/${XENO_ARCH}/${IPIPE_PATCH_P}.patch
	http://download.gna.org/xenomai/stable/${XENO_P}.tar.bz2"


src_unpack() {
	kernel-2_src_unpack
	cd "${WORKDIR}"
	unpack "${XENO_P}.tar.bz2"
}

src_prepare() {
	cd "${S}"
	epatch "${DISTDIR}/${IPIPE_PATCH_P}.patch"
	sed -e "s,@LINUX_ARCH@,$XENO_ARCH,g" "${WORKDIR}/${XENO_P}/scripts/Kconfig.frag" >> "init/Kconfig"
	echo "drivers-\$(CONFIG_XENOMAI)		+= arch/$XENO_ARCH/xenomai/" >> "arch/$XENO_ARCH/Makefile"
	echo "obj-\$(CONFIG_XENOMAI)		+= xenomai/" >> "drivers/Makefile"
	echo "obj-\$(CONFIG_XENOMAI)		+= xenomai/" >> "kernel/Makefile"
	mkdir "${S}/kernel/xenomai"
	mkdir "${S}/include/xenomai"
	
	cp -r "${WORKDIR}/${XENO_P}/ksrc/"{Config.in,Makefile,arch,nucleus,skins} "${S}/kernel/xenomai/"
	cp -r "${WORKDIR}/${XENO_P}/ksrc/arch/${XENO_ARCH}/" "${S}/arch/${XENO_ARCH}/xenomai/"
	cp -r "${WORKDIR}/${XENO_P}/ksrc/drivers/" "${S}/drivers/xenomai/"
	cp -r "${WORKDIR}/${XENO_P}/include/asm-${XENO_ARCH}/" "${S}/arch/${XENO_ARCH}/include/asm/xenomai/"
	cp -r "${WORKDIR}/${XENO_P}/include/asm-generic/" "${S}/include/asm-generic/xenomai/"
	cp -r "${WORKDIR}/${XENO_P}/include/"{analogy,compat,native,nucleus,posix,psos+,rtdk.h,rtdm,testing,uitron,vrtx,vxworks} "${S}/include/xenomai/"
}

pkg_postinst() {
	kernel-2_pkg_postinst
	einfo "For more info on this patchset, and how to report problems, see:"
	einfo "${HOMEPAGE}"
}

pkg_postrm() {
	kernel-2_pkg_postrm
}