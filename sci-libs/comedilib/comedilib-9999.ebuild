# Copyright 1999-2014 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: $

EAPI="5"
PYTHON_COMPAT=( python{2_6,2_7} )

inherit autotools eutils python-single-r1

DESCRIPTION="The Comedi project develops open-source drivers, tools, and libraries for data acquisition"
HOMEPAGE="http://www.comedi.org/"
SRC_URI="http://www.comedi.org/download/${P}.tar.gz"

EGIT_REPO_URI="https://github.com/Linux-Comedi/comedilib.git"

LICENSE="LGPL-2.1"
SLOT="0"
KEYWORDS="~amd64 ~x86"
IUSE=""

DEPEND="${PYTHON_DEPS}"
RDEPEND="${DEPEND}"


