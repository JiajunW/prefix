# Copyright 1999-2009 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/sys-libs/libcap/libcap-2.17.ebuild,v 1.1 2009/08/31 00:20:00 vapier Exp $

inherit eutils multilib toolchain-funcs pam

DESCRIPTION="POSIX 1003.1e capabilities"
HOMEPAGE="http://www.friedhoff.org/posixfilecaps.html"
SRC_URI="mirror://kernel/linux/libs/security/linux-privs/libcap${PV:0:1}/${P}.tar.bz2"

LICENSE="GPL-2 BSD"
SLOT="0"
KEYWORDS="~amd64-linux ~ia64-linux ~x86-linux"
IUSE="pam"

RDEPEND="sys-apps/attr
	pam? ( virtual/pam )"
DEPEND="${RDEPEND}
	sys-kernel/linux-headers"

src_unpack() {
	unpack ${P}.tar.bz2
	cd "${S}"
	epatch "${FILESDIR}"/2.16/*.patch
	sed -i -e '/cap_setfcap.*morgan/s:^:#:' pam_cap/capability.conf
	sed -i \
		-e "/^PAM_CAP/s:=.*:=$(use pam && echo yes || echo no):" \
		-e '/^DYNAMIC/s:=.*:=yes:' \
		-e "/^lib=/s:=.*:=$(get_libdir):" \
		Make.Rules
}

src_compile() {
	tc-export BUILD_CC CC AR RANLIB
	emake || die
}

src_install() {
	emake install DESTDIR="${ED}" || die

	gen_usr_ldscript libcap.so
	mv "${ED}"/$(get_libdir)/libcap.a "${ED}"/usr/$(get_libdir)/ || die

	dopammod pam_cap/pam_cap.so
	dopamsecurity '' pam_cap/capability.conf

	dodoc CHANGELOG README doc/capability.notes
}
