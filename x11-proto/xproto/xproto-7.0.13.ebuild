# Copyright 1999-2009 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/x11-proto/xproto/xproto-7.0.13.ebuild,v 1.2 2009/05/05 15:40:58 fauli Exp $

# Must be before x-modular eclass is inherited
#SNAPSHOT="yes"

inherit x-modular

DESCRIPTION="X.Org xproto protocol headers"

KEYWORDS="~ppc-aix ~x86-interix ~amd64-linux ~x86-linux ~ppc-macos ~x86-macos ~sparc-solaris ~sparc64-solaris ~x64-solaris ~x86-solaris ~x86-winnt"
IUSE=""
RDEPEND=""
DEPEND="${RDEPEND}"

src_unpack() {
	x-modular_unpack_source

	epatch "${FILESDIR}"/${P}-winnt.patch

	x-modular_reconf_source
}
