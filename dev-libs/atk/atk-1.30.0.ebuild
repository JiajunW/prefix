# Copyright 1999-2010 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/dev-libs/atk/atk-1.30.0.ebuild,v 1.12 2010/10/17 14:51:43 armin76 Exp $

EAPI="2"
GCONF_DEBUG="no"

inherit gnome2 autotools

DESCRIPTION="GTK+ & GNOME Accessibility Toolkit"
HOMEPAGE="http://live.gnome.org/GAP/"

LICENSE="LGPL-2"
SLOT="0"
KEYWORDS="~x86-freebsd ~x86-interix ~amd64-linux ~x86-linux ~ppc-macos ~x64-macos ~x86-macos ~sparc-solaris ~sparc64-solaris ~x64-solaris ~x86-solaris ~x86-winnt"
IUSE="doc +introspection"

RDEPEND="dev-libs/glib:2
	introspection? ( >=dev-libs/gobject-introspection-0.6.7 )"
DEPEND="${RDEPEND}
	>=dev-lang/perl-5
	sys-devel/gettext
	dev-util/pkgconfig
	doc? ( >=dev-util/gtk-doc-1 )"

pkg_setup() {
	G2CONF="${G2CONF} $(use_enable introspection)"
	DOCS="AUTHORS ChangeLog NEWS README"
}
