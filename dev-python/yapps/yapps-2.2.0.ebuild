# Copyright 1999-2021 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI="7"
PYTHON_COMPAT=( python3_9 )

inherit distutils-r1 git-r3 toolchain-funcs

MY_PN="Yapps"
MY_P="${MY_PN}-${PV}"

DESCRIPTION="An easy to use parser generator"
HOMEPAGE="https://github.com/smurfix/yapps"
#SRC_URI="mirror://pypi/${MY_P:0:1}/${MY_PN}/${MY_P}.tar.gz"
#SRC_URI="https://github.com/smurfix/yapps/archive/refs/tags/v2.2.0.tar.gz"

EGIT_REPO_URI="https://github.com/smurfix/yapps.git"
PATCHES=(
	"${FILESDIR}/${PN}-Don-t-capture-sys.stderr-at-import-time.patch"
	"${FILESDIR}/${PN}-Convert-print-statements-to-python3-style-print-func.patch"
)

LICENSE="MIT"
SLOT="0"
KEYWORDS="~amd64 ~x86"

DEPEND="dev-python/setuptools[${PYTHON_USEDEP}]"
RDEPEND=""

S="${WORKDIR}/${PN}-${PV}"
