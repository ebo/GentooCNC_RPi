# Copyright 1999-2015 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: $

EAPI="5"

inherit autotools eutils linux-info linux-mod multilib user

DESCRIPTION="RealTime Application Interface for Linux"
HOMEPAGE="https://www.rtai.org/"
SRC_URI="https://www.rtai.org/userfiles/downloads/RTAI/${P}.tar.bz2"

LICENSE="LGPL"
SLOT="0"
KEYWORDS="~amd64 ~x86"
IUSE="16550a align-priority bits comedi-lxrt comedi-lock debug-rtdm diag-tsc-sync dbx dbx-network fifos +fpu hard-soft-toggler +ktasks-sched-lxrt leds long-timed-lists lxrt-use-linux-syscall +malloc malloc-tlsf +malloc-vmalloc math math-c99 +mbx module-debug +msg +mq netrpc netrpc-rtnet rt-poll rt-poll-on-stack rtdm rtdm-shirq rtailab rtdm-select +sched-lock-isr +sem serial +shm sim task-switch-signal tasklets tbx testsuite trace tune-tsc-sync user-debug usi verbose-latex watchdog "

DEPEND="sys-kernel/rtai-sources"
RDEPEND="${DEPEND}"

pkg_setup() {
	linux-info_pkg_setup
	linux-mod_pkg_setup
	
	if ! linux_chkconfig_builtin IPIPE ; then
		ewarn
		ewarn "This package depends on IPIPE-enabled kernel sources"
		ewarn "IPIPE patch not enabled in selected kernel"; 
		ewarn "Make sure to install latest rtai-sources";
		ewarn "Build it with Processor type and features -> Interrupt pipeline"
		ewarn
	fi
	
	if linux_chkconfig_present MODVERSIONS ; then
		ewarn
		ewarn "Please *uncheck* MODVERSIONS in your kernel"
		ewarn "(Enable loadable module support->Module versioning support)"
		ewarn
	fi
	
}

src_prepare() {
	epatch "${FILESDIR}/unlink_access-${PV}.patch"
	eautoreconf
}

src_configure() {
	myconf="--prefix=/usr/realtime
			--with-linux-dir=${KERNEL_DIR}
			--with-module-dir=/lib/modules/${KV_FULL}/rtai/
			--enable-malloc-heap-size=2048
			--enable-kstack-heap-size=512
			--enable-rtc-freq=0
			--enable-sched-8254-latency=4700
			--enable-sched-apic-latency=3944
			--enable-sched-lxrt-numslots=150
			--enable-cal-freq-fact=0"
	
	myconf="${myconf} \
		$(use_enable trace) \
 		$(use_enable malloc) \
 		$(use_enable usi) \
 		$(use_enable watchdog) \
 		$(use_enable leds) \
 		$(use_enable lxrt-use-linux-syscall) \
 		$(use_enable ktasks-sched-lxrt) \
 		$(use_enable sched-lock-isr) \
 		$(use_enable long-timed-lists) \
 		$(use_enable rtdm) \
 		$(use_enable rtdm-shirq) \
 		$(use_enable rtdm-select) \
 		$(use_enable debug-rtdm) \
 		$(use_enable task-switch-signal) \
 		$(use_enable hard-soft-toggler) \
 		$(use_enable align-priority) \
 		$(use_enable comedi-lxrt) \
 		$(use_enable comedi-lock) \
 		$(use_enable serial) \
 		$(use_enable 16550a) \
 		$(use_enable testsuite) \
 		$(use_enable rtailab) \
 		$(use_enable fpu) \
 		$(use_enable math-c99) \
 		$(use_enable malloc-tlsf) \
 		$(use_enable malloc-vmalloc) \
 		$(use_enable diag-tsc-sync) \
 		$(use_enable tune-tsc-sync) \
		$(use_enable dbx) \
		$(use_enable dbx-network) \
 		$(use_enable verbose-latex) \
 		$(use_enable module-debug) \
 		$(use_enable user-debug) \
 		$(use_enable sim)"
	
	use math && myconf="${myconf} --enable-math=m"
	use bits && myconf="${myconf} --enable-bits=m"
	use fifos && myconf="${myconf} --enable-fifos=m"
	use netrpc && myconf="${myconf} --enable-netrpc=m"
	use netrpc-rtnet && myconf="${myconf} --enable-netrpc-rtnet=m"
	use sem && myconf="${myconf} --enable-sem=m"
	use rt-poll && myconf="${myconf} --enable-rt-poll=m"
	use rt-poll-on-stack && myconf="${myconf} --enable-rt-poll-on-stack=m"
	use msg && myconf="${myconf} --enable-msg=m"
	use mbx && myconf="${myconf} --enable-mbx=m"
	use tbx && myconf="${myconf} --enable-tbx=m"
	use mq && myconf="${myconf} --enable-mq=m"
	use shm && myconf="${myconf} --enable-shm=m"
	use tasklets && myconf="${myconf} --enable-tasklets=m"
	use comedi-lxrt && myconf="${myconf} --with-comedi"

	econf ${myconf}	
}

src_install() {
	emake -j1 DESTDIR="${D}" install
	
	local envd="${T}/50rtai"
	cat > "${envd}" <<-EOF
		PATH="${EPREFIX}/usr/realtime/bin/"
		ROOTPATH="${EPREFIX}/usr/realtime/bin/"
		LDPATH="${EPREFIX}/usr/realtime/$(get_libdir)"
	EOF
	doenvd "${envd}"
	
	if [[ ! -d "${EPREFIX}/usr/realtime/lib" ]] ; then
		dosym "${EPREFIX}/usr/realtime/$(get_libdir)" "${EPREFIX}/usr/realtime/lib"
	fi
}
