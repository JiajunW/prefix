# Copyright 1999-2007 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/dev-perl/XML-Simple/XML-Simple-2.18.ebuild,v 1.3 2007/11/19 02:57:44 kumba Exp $

EAPI="prefix"

inherit perl-module

DESCRIPTION="XML::Simple - Easy API to read/write XML (esp config files)"
HOMEPAGE="http://search.cpan.org/~grantm/"
SRC_URI="mirror://cpan/authors/id/G/GR/GRANTM/${P}.tar.gz"

LICENSE="|| ( Artistic GPL-2 )"
SLOT="0"
KEYWORDS="~amd64 ~ia64 ~ppc-macos ~sparc-solaris ~x86 ~x86-macos"
IUSE=""

DEPEND="virtual/perl-Storable
	dev-perl/XML-SAX
	dev-perl/XML-LibXML
	>=dev-perl/XML-NamespaceSupport-1.04
	>=dev-perl/XML-Parser-2.30
	dev-lang/perl
	>=virtual/perl-Test-Simple-0.41"

SRC_TEST="do"
