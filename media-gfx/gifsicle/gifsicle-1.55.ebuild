# Copyright 1999-2009 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/media-gfx/gifsicle/gifsicle-1.55.ebuild,v 1.2 2009/09/29 09:36:20 maekke Exp $

DESCRIPTION="A command-line tool for creating, editing, and getting information about GIF images and animations"
HOMEPAGE="http://www.lcdf.org/~eddietwo/gifsicle/"
SRC_URI="http://www.lcdf.org/~eddietwo/gifsicle/${P}.tar.gz"

LICENSE="GPL-2"
SLOT="0"
KEYWORDS="~amd64-linux ~x86-linux ~ppc-macos ~x86-macos"
IUSE="X"

RDEPEND="X? ( x11-libs/libX11
		x11-libs/libXt )"
DEPEND="${RDEPEND}
		X? ( x11-proto/xproto )"

src_compile() {
	local myconf

	use X || myconf="${myconf} --disable-gifview"
	econf ${myconf} || die "econf failed"
	emake || die "emake failed"
}

src_install() {
	emake DESTDIR="${D}" install || die "make install failed"
	dodoc NEWS README || die
}
