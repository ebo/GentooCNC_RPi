# Copyright 1999-2014 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: $

EAPI="5"

inherit autotools eutils linux-info linux-mod

DESCRIPTION="Comedi is a collection of drivers for a variety of common data acquisition plug-in board"
HOMEPAGE="http://www.comedi.org/"
SRC_URI="http://emiter.com/~slis/${P}.tar.gz"

LICENSE="LGPL-2.1"
SLOT="0"
KEYWORDS="~amd64 ~x86"
IUSE="pci pcmcia rtai usb"

DEPEND=""
RDEPEND="${DEPEND}"

BUILD_TARGETS="all"

src_prepare() {
	epatch "${FILESDIR}/rtai-config.patch"
	eautoreconf
}

src_configure() {
	MODULE_NAMES="
	comedi(comedi::comedi)
	kcomedilib(comedi::comedi/kcomedilib)
	"

	use rtai && MODULE_NAME="${MODULE_NAMES}
	comedi_rt_timer(comedi::comedi/drivers)
	"

	use pci && MODULE_NAMES="${MODULE_NAMES}
	comedi_parport(comedi::comedi/drivers)
	das800(comedi::comedi/drivers)
	comedi_test(comedi::comedi/drivers)
	dmm32at(comedi::comedi/drivers)
	daqboard2000(comedi::comedi/drivers)
	das16m1(comedi::comedi/drivers)
	comedi_bond(comedi::comedi/drivers)
	das08(comedi::comedi/drivers)
	dt2814(comedi::comedi/drivers)
	dt2801(comedi::comedi/drivers)
	8255(comedi::comedi/drivers)
	contec_pci_dio(comedi::comedi/drivers)
	addi_apci_035(comedi::comedi/drivers)
	acl7225b(comedi::comedi/drivers)
	addi_apci_1032(comedi::comedi/drivers)
	addi_apci_1500(comedi::comedi/drivers)
	addi_apci_1516(comedi::comedi/drivers)
	das6402(comedi::comedi/drivers)
	addi_apci_16xx(comedi::comedi/drivers)
	addi_apci_1564(comedi::comedi/drivers)
	addi_apci_2032(comedi::comedi/drivers)
	addi_apci_2016(comedi::comedi/drivers)
	addi_apci_2200(comedi::comedi/drivers)
	addi_apci_3001(comedi::comedi/drivers)
	addi_apci_3501(comedi::comedi/drivers)
	addi_apci_3xxx(comedi::comedi/drivers)
	addi_apci_3120(comedi::comedi/drivers)
	adl_pci6208(comedi::comedi/drivers)
	adl_pci7230(comedi::comedi/drivers)
	adl_pci7432(comedi::comedi/drivers)
	adl_pci9111(comedi::comedi/drivers)
	adl_pci7296(comedi::comedi/drivers)
	adl_pci9112(comedi::comedi/drivers)
	adl_pci8164(comedi::comedi/drivers)
	adl_pci9118(comedi::comedi/drivers)
	adv_pci1710(comedi::comedi/drivers)
	adq12b(comedi::comedi/drivers)
	adv_pci1723(comedi::comedi/drivers)
	adv_pci_dio(comedi::comedi/drivers)
	aio_aio12_8(comedi::comedi/drivers)
	amplc_dio200(comedi::comedi/drivers)
	aio_iiro_16(comedi::comedi/drivers)
	amplc_pc236(comedi::comedi/drivers)
	amplc_pc263(comedi::comedi/drivers)
	c6xdigio(comedi::comedi/drivers)
	amplc_pci224(comedi::comedi/drivers)
	amplc_pci230(comedi::comedi/drivers)
	cb_pcidac(comedi::comedi/drivers)
	cb_pcidas(comedi::comedi/drivers)
	cb_pcidda(comedi::comedi/drivers)
	cb_pcidio(comedi::comedi/drivers)
	cb_pcidas64(comedi::comedi/drivers)
	cb_pcimdas(comedi::comedi/drivers)
	cb_pcimdda(comedi::comedi/drivers)
	comedi_fc(comedi::comedi/drivers)
	das16(comedi::comedi/drivers)
	das1800(comedi::comedi/drivers)
	dt2811(comedi::comedi/drivers)
	dt2817(comedi::comedi/drivers)
	dt2815(comedi::comedi/drivers)
	dt282x(comedi::comedi/drivers)
	dt3000(comedi::comedi/drivers)
	fl512(comedi::comedi/drivers)
	icp_multi(comedi::comedi/drivers)
	gsc_hpdi(comedi::comedi/drivers)
	jr3_pci(comedi::comedi/drivers)
	ii_pci20kc(comedi::comedi/drivers)
	me_daq(comedi::comedi/drivers)
	ke_counter(comedi::comedi/drivers)
	me4000(comedi::comedi/drivers)
	mite(comedi::comedi/drivers)
	mpc624(comedi::comedi/drivers)
	ni_6527(comedi::comedi/drivers)
	ni_670x(comedi::comedi/drivers)
	multiq3(comedi::comedi/drivers)
	ni_660x(comedi::comedi/drivers)
	ni_at_a2150(comedi::comedi/drivers)
	ni_65xx(comedi::comedi/drivers)
	ni_atmio(comedi::comedi/drivers)
	ni_atmio16d(comedi::comedi/drivers)
	ni_at_ao(comedi::comedi/drivers)
	ni_labpc(comedi::comedi/drivers)
	ni_pcidio(comedi::comedi/drivers)
	ni_pcimio(comedi::comedi/drivers)
	ni_tio(comedi::comedi/drivers)
	ni_tiocmd(comedi::comedi/drivers)
	pcl711(comedi::comedi/drivers)
	pcl724(comedi::comedi/drivers)
	pcl726(comedi::comedi/drivers)
	pcl725(comedi::comedi/drivers)
	pcl730(comedi::comedi/drivers)
	pcl812(comedi::comedi/drivers)
	pcl816(comedi::comedi/drivers)
	pcl818(comedi::comedi/drivers)
	pcm3724(comedi::comedi/drivers)
	pcm3730(comedi::comedi/drivers)
	pcmad(comedi::comedi/drivers)
	pcmda12(comedi::comedi/drivers)
	pcmmio(comedi::comedi/drivers)
	pcmuio(comedi::comedi/drivers)
	rtd520(comedi::comedi/drivers)
	poc(comedi::comedi/drivers)
	rti800(comedi::comedi/drivers)
	rti802(comedi::comedi/drivers)
	s526(comedi::comedi/drivers)
	skel(comedi::comedi/drivers)
	s626(comedi::comedi/drivers)
	serial2002(comedi::comedi/drivers)
	unioxx5(comedi::comedi/drivers)
	ssv_dnp(comedi::comedi/drivers)
"
	econf $(use_enable pci) $(use_enable pcmcia) $(use_enable rtai) $(use_enable usb) --with-modulesdir=/lib/modules/${KV_FULL}
}
