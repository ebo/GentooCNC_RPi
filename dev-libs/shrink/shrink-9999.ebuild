# Copyright 2020 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=7

inherit git-r3

DESCRIPTION="Linux bash script to resize Raspberry SD card images"
HOMEPAGE="https://github.com/qrti/shrink"

SRC_URI=""
EGIT_REPO_URI="https://github.com/qrti/shrink.git"
if [[ ${PV} =~ [9]{4,} ]]; then
	EGIT_COMMIT=""
else
	die
fi

LICENSE="ISC"
SLOT="0"
KEYWORDS="~amd64 ~arm ~arm64 ~x86"
IUSE=""

RDEPEND="${DEPEND}
	sys-block/gparted
	sys-apps/pv
	app-shells/bash
	app-arch/gzip
	sys-fs/e2fsprogs
	sys-apps/coreutils
	sys-apps/util-linux
	"

src_install() {
	dodoc README.md

	# change the name name from a .sh extension and install
	mv script/shrink.sh script/shrink
	dobin script/shrink
}
