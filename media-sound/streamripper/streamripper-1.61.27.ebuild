# Copyright 1999-2006 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/www/viewcvs.gentoo.org/raw_cvs/gentoo-x86/media-sound/streamripper/streamripper-1.61.27.ebuild,v 1.5 2006/12/24 00:51:07 dertobi123 Exp $

EAPI="prefix"

inherit eutils

DESCRIPTION="Extracts and records individual MP3 file tracks from shoutcast streams"
HOMEPAGE="http://streamripper.sourceforge.net/"
SRC_URI="mirror://sourceforge/${PN}/${P}.tar.gz"

LICENSE="GPL-2"
SLOT="0"
KEYWORDS="~amd64 ~ppc-macos ~x86 ~x86-macos"
IUSE="vorbis"

DEPEND="media-libs/libmad
	vorbis? ( media-libs/libogg
	media-libs/libvorbis )"

src_unpack() {
	unpack ${A}
	cd ${S}

	# Force package to use system libmad
	rm -rf libmad*
	sed -i -e 's/libmad//' Makefile.in || die "sed failed"

	# for some reason the install-sh file is not executable on OSX...
	chmod a+x install-sh
}

src_compile() {
	econf $(use_with vorbis ogg) || die "econf failed"
	emake || die "emake failed"
}

src_install() {
	emake DESTDIR="${D}" install || die "emake install failed"
	dodoc CHANGES README THANKS readme_xfade.txt
}
