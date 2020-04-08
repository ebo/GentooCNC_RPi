# Copyright 2020 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=7

inherit git-r3

DESCRIPTION="PiShrink "
HOMEPAGE="https://github.com/Drewsif/PiShrink"

SRC_URI=""
EGIT_REPO_URI="https://github.com/Drewsif/PiShrink.git"
if [[ ${PV} =~ [9]{4,} ]]; then
	EGIT_COMMIT=""
else
	EGIT_COMMIT="4f61a3244aeed97c97efba1658c872513603423f"
fi

LICENSE="MIT"
SLOT="0"
KEYWORDS="~amd64 ~arm ~arm64 ~x86"
IUSE=""

RDEPEND="${DEPEND}
	app-shells/bash
	app-arch/gzip
	sys-fs/e2fsprogs
	sys-apps/coreutils
	sys-block/parted
	sys-apps/util-linux
	"

src_install() {
	dodoc README.md

	# change the name name from a .sh extension and install
	mv pishrink.sh pishrink
	dobin pishrink
}
