# Copyright 1999-2009 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/dev-lang/ghc/ghc-6.10.4.ebuild,v 1.4 2009/09/16 06:50:28 kolmodin Exp $

# Brief explanation of the bootstrap logic:
#
# Previous ghc ebuilds have been split into two: ghc and ghc-bin,
# where ghc-bin was primarily used for bootstrapping purposes.
# From now on, these two ebuilds have been combined, with the
# binary USE flag used to determine whether or not the pre-built
# binary package should be emerged or whether ghc should be compiled
# from source.  If the latter, then the relevant ghc-bin for the
# arch in question will be used in the working directory to compile
# ghc from source.
#
# This solution has the advantage of allowing us to retain the one
# ebuild for both packages, and thus phase out virtual/ghc.

# Note to users of hardened gcc-3.x:
#
# If you emerge ghc with hardened gcc it should work fine (because we
# turn off the hardened features that would otherwise break ghc).
# However, emerging ghc while using a vanilla gcc and then switching to
# hardened gcc (using gcc-config) will leave you with a broken ghc. To
# fix it you would need to either switch back to vanilla gcc or re-emerge
# ghc (or ghc-bin). Note that also if you are using hardened gcc-3.x and
# you switch to gcc-4.x that this will also break ghc and you'll need to
# re-emerge ghc (or ghc-bin). People using vanilla gcc can switch between
# gcc-3.x and 4.x with no problems.

inherit base autotools bash-completion eutils flag-o-matic toolchain-funcs ghc-package versionator

DESCRIPTION="The Glasgow Haskell Compiler"
HOMEPAGE="http://www.haskell.org/ghc/"

# discover if this is a snapshot release
IS_SNAPSHOT="$(get_version_component_range 4)" # non-empty if snapshot
EXTRA_SRC_URI="${PV}"
[[ "${IS_SNAPSHOT}" ]] && EXTRA_SRC_URI="stable/dist"

arch_binaries=""

arch_binaries="$arch_binaries x86?   ( http://code.haskell.org/~ivanm/ghc-bin-${PV}-x86.tbz2 )"
arch_binaries="$arch_binaries amd64? ( http://haskell.org/~kolmodin/ghc-bin-${PV}-amd64.tbz2 )"
arch_binaries="$arch_binaries sparc? ( http://haskell.org/~duncan/ghc/ghc-bin-${PV}-sparc.tbz2 )"
arch_binaries="$arch_binaries ppc64? ( http://code.haskell.org/~slyfox/ghc-ppc64/ghc-bin-${PV}-ppc64.tbz2 )"

#arch_binaries="$arch_binaries alpha?   ( mirror://gentoo/ghc-bin-${PV}-alpha.tbz2 )"
#arch_binaries="$arch_binaries amd64?   ( mirror://gentoo/ghc-bin-${PV}-amd64.tbz2 )"
#arch_binaries="$arch_binaries hppa?    ( mirror://gentoo/ghc-bin-${PV}-hppa.tbz2 )"
#arch_binaries="$arch_binaries ia64?    ( mirror://gentoo/ghc-bin-${PV}-ia64.tbz2 )"
#arch_binaries="$arch_binaries sparc?   ( mirror://gentoo/ghc-bin-${PV}-sparc.tbz2 )"
#arch_binaries="$arch_binaries x86? ( mirror://gentoo/ghc-bin-${PV}-x86.tbz2 )"

arch_binaries="$arch_binaries x86-macos? ( http://www.haskell.org/ghc/dist/${PV}/maeder/ghc-${PV}-i386-apple-darwin.tar.bz2 )"
arch_binaries="$arch_binaries ppc-macos? ( http://www.haskell.org/ghc/dist/${PV}/maeder/ghc-${PV}-powerpc-apple-darwin.tar.bz2 )"
arch_binaries="$arch_binaries x86-solaris? ( http://www.haskell.org/ghc/dist/${PV}/maeder/ghc-${PV}-i386-unknown-solaris2.tar.bz2 )"
arch_binaries="$arch_binaries sparc-solaris? ( http://www.haskell.org/ghc/dist/${PV}/maeder/ghc-${PV}-sparc-sun-solaris2.tar.bz2 )"

SRC_URI="!binary? ( http://haskell.org/ghc/dist/${EXTRA_SRC_URI}/${P}-src.tar.bz2 )
	!ghcbootstrap? ( $arch_binaries )"

LICENSE="BSD"
SLOT="0"
KEYWORDS="~amd64-linux ~x86-linux ~ppc-macos ~x86-macos ~sparc-solaris ~x86-solaris"
IUSE="binary doc ghcbootstrap"

RDEPEND="
	!dev-lang/ghc-bin
	!kernel_Darwin? ( >=sys-devel/gcc-2.95.3 )
	kernel_linux? ( >=sys-devel/binutils-2.17 )
	kernel_SunOS? ( >=sys-devel/binutils-2.17 )
	>=dev-lang/perl-5.6.1
	>=dev-libs/gmp-4.1
	!<dev-haskell/haddock-2.4.2"
# earlier versions than 2.4.2 of haddock only works with older ghc releases

DEPEND="${RDEPEND}
	ghcbootstrap? (	doc? (	~app-text/docbook-xml-dtd-4.2
							app-text/docbook-xsl-stylesheets
							>=dev-libs/libxslt-1.1.2 ) )"
# In the ghcbootstrap case we rely on the developer having
# >=ghc-5.04.3 on their $PATH already

PDEPEND="!ghcbootstrap? ( =app-admin/haskell-updater-0.9* )"

append-ghc-cflags() {
	local flag compile assemble link
	for flag in $*; do
		case ${flag} in
			compile)	compile="yes";;
			assemble)	assemble="yes";;
			link)		link="yes";;
			*)
				[[ ${compile}  ]] && GHC_CFLAGS="${GHC_CFLAGS} -optc${flag}"
				[[ ${assemble} ]] && GHC_CFLAGS="${GHC_CFLAGS} -opta${flag}"
				[[ ${link}     ]] && GHC_CFLAGS="${GHC_CFLAGS} -optl${flag}";;
		esac
	done
}

ghc_setup_cflags() {
	# We need to be very careful with the CFLAGS we ask ghc to pass through to
	# gcc. There are plenty of flags which will make gcc produce output that
	# breaks ghc in various ways. The main ones we want to pass through are
	# -mcpu / -march flags. These are important for arches like alpha & sparc.
	# We also use these CFLAGS for building the C parts of ghc, ie the rts.
	strip-flags
	strip-unsupported-flags
	filter-flags -fPIC

	GHC_CFLAGS=""
	for flag in ${CFLAGS}; do
		case ${flag} in

			# Ignore extra optimisation (ghc passes -O to gcc anyway)
			# -O2 and above break on too many systems
			-O*) ;;

			# Arch and ABI flags are what we're really after
			-m*) append-ghc-cflags compile assemble ${flag};;

			# Debugging flags don't help either. You can't debug Haskell code
			# at the C source level and the mangler discards the debug info.
			-g*) ;;

			# Ignore all other flags, including all -f* flags
		esac
	done

	# hardened-gcc needs to be disabled, because the mangler doesn't accept
	# its output.
	gcc-specs-pie && append-ghc-cflags compile link	-nopie
	gcc-specs-ssp && append-ghc-cflags compile		-fno-stack-protector

	# prevent from failind building unregisterised ghc:
	# http://www.mail-archive.com/debian-bugs-dist@lists.debian.org/msg171602.html
	use ppc64 && append-ghc-cflags compile -mminimal-toc

	# We also add -Wa,--noexecstack to get ghc to generate .o files with
	# non-exectable stack. This it a hack until ghc does it itself properly.
	case $($(tc-getAS) -v 2>&1 </dev/null) in
		*"GNU Binutils"*) # GNU ld
			append-ghc-cflags assemble "-Wa,--noexecstack"
		;;
	esac
}

pkg_setup() {
	if use ghcbootstrap; then
		ewarn "You requested ghc bootstrapping, this is usually only used"
		ewarn "by Gentoo developers to make binary .tbz2 packages for"
		ewarn "use with the ghc ebuild's USE=\"binary\" feature."
		use binary && \
			die "USE=\"ghcbootstrap binary\" is not a valid combination."
		[[ -z $(type -P ghc) ]] && \
			die "Could not find a ghc to bootstrap with."
	fi
}

src_unpack() {
	# Create the ${S} dir if we're using the binary version
	use binary && mkdir "${S}"

	ONLYA=${A}
	[[ ${CHOST} != *-linux-gnu ]] && ONLYA=${P}-src.tar.bz2
	#base_src_unpack
	unpack ${ONLYA}
	cd "${S}"  # base_src_unpack moves to ${S}
	ghc_setup_cflags

	if use binary; then

		# Move unpacked files to the expected place
		mv "${WORKDIR}/usr" "${S}"
	else
		if ! use ghcbootstrap; then
			if [[ ${CHOST} == *-linux-gnu ]] ; then
			# Relocate from /usr to ${WORKDIR}/usr
			sed -i -e "s|/usr|${WORKDIR}/usr|g" \
				"${WORKDIR}/usr/bin/ghc-${PV}" \
				"${WORKDIR}/usr/bin/ghci-${PV}" \
				"${WORKDIR}/usr/bin/ghc-pkg-${PV}" \
				"${WORKDIR}/usr/bin/hsc2hs" \
				"${WORKDIR}"/usr/lib*/${P}/package.conf \
				|| die "Relocating ghc from /usr to workdir failed"
			else
				mkdir "${WORKDIR}"/ghc-bin-installer || die
				pushd "${WORKDIR}"/ghc-bin-installer > /dev/null || die
				use sparc-solaris && unpack ghc-${PV}-sparc-sun-solaris2.tar.bz2
				use x86-solaris && unpack ghc-${PV}-i386-unknown-solaris2.tar.bz2
				use ppc-macos && unpack ghc-${PV}-powerpc-apple-darwin.tar.bz2
				use x86-macos && unpack ghc-${PV}-i386-apple-darwin.tar.bz2

				# it is autoconf, but we really don't want to give it too
				# much arguments, in fact we do the make in-place anyway
				pushd "${P}" > /dev/null || die
				./configure --prefix="${WORKDIR}"/usr || die
				make install || die
				popd > /dev/null
				popd > /dev/null
				# fix the binaries so they run, on Solaris we need an
				# LD_LIBRARY_PATH which has our prefix libdirs, on Darwin we
				# need to replace the frameworks with our libs from the prefix
				pushd "${WORKDIR}"/usr > /dev/null || die
				if [[ ${CHOST} == *-solaris* ]] ; then
					export LD_LIBRARY_PATH="${EPREFIX}/$(get_libdir):${EPREFIX}/usr/$(get_libdir):${LD_LIBRARY_PATH}"
				elif [[ ${CHOST} == *-darwin* ]] ; then
					local readline_framework
					if [[ ${CHOST} == powerpc-*-darwin* ]]; then
						readline_framework=GNUreadline.framework/GNUreadline
					else
						readline_framework=GNUreadline.framework/Versions/A/GNUreadline
					fi
					for binary in lib/*-apple-darwin/ghc-{${PV},pkg.bin}; do
						install_name_tool -change \
							${readline_framework} \
							"${EPREFIX}"/lib/libreadline.dylib \
							${binary} || die
						install_name_tool -change \
							GMP.framework/Versions/A/GMP \
							"${EPREFIX}"/usr/lib/libgmp.dylib \
							${binary} || die
					done
					# we don't do frameworks!
					sed -i \
						-e 's/\(frameworks = \)\["GMP"\]/\1[]/g' \
						-e 's/\(extraLibraries = \)\["m"\]/\1["m","gmp"]/g' \
						lib/*-apple-darwin/package.conf || die
				fi
				popd > /dev/null
			fi
		fi

		# Hack to prevent haddock being installed, remove when ./configure
		# supports something better to not build docs or haddock.
		sed -i -e 's/DO_NOT_INSTALL =/DO_NOT_INSTALL = haddock/' \
			"${S}/utils/Makefile"

		# Highly useful when you need to pass your HC opts to bootstrap libs
		# Currently it is needed for ppc64 to build with broken compiler
		epatch "${FILESDIR}/ghc-6.10.4-propagate-hc-options-to-all-libraries.patch"

		# see ghc_setup_cflags()
		use ppc64 && epatch "${FILESDIR}/ghc-6.10.4-ppc64-always-minimal-toc.patch"

		# as we have changed the build system with the readline patch
# see below		eautoreconf
	fi

	# Make configure find docbook-xsl-stylesheets from Prefix
	sed -i -e '/^FP_DIR_DOCBOOK_XSL/s:\[.*\]:['"${EPREFIX}"'/usr/share/sgml/docbook/xsl-stylesheets/]:' configure.ac || die
	eautoreconf
}

src_compile() {
	if ! use binary; then

		# initialize build.mk
		echo '# Gentoo changes' > mk/build.mk

		# Put docs into the right place, ie /usr/share/doc/ghc-${PV}
		echo "docdir = ${EPREFIX}/usr/share/doc/${P}" >> mk/build.mk
		echo "htmldir = ${EPREFIX}/usr/share/doc/${P}" >> mk/build.mk

		# We also need to use the GHC_CFLAGS flags when building ghc itself
		echo "SRC_HC_OPTS+=${GHC_CFLAGS}" >> mk/build.mk
		case $($(tc-getAS) -v 2>&1 </dev/null) in
			*"GNU Binutils"*) # GNU ld
			echo "SRC_CC_OPTS+=${CFLAGS} -Wa,--noexecstack" >> mk/build.mk
			;;
		esac

		# We can't depend on haddock except when bootstrapping when we
		# must build docs and include them into the binary .tbz2 package
		if use ghcbootstrap && use doc; then
			echo XMLDocWays="html" >> mk/build.mk
			echo HADDOCK_DOCS=YES >> mk/build.mk
		else
			echo XMLDocWays="" >> mk/build.mk
			echo HADDOCK_DOCS=NO >> mk/build.mk
		fi

		# circumvent a very strange bug that seems related with ghc producing
		# too much output while being filtered through tee (e.g. due to
		# portage logging) reported as bug #111183
		echo "SRC_HC_OPTS+=-w" >> mk/build.mk

		# GHC build system knows to build unregisterised on alpha and hppa,
		# but we have to tell it to build unregisterised on some arches
		# ppc64: EvilMangler currently does not understand some TOCs
		if use alpha || use hppa || use ppc64; then
			echo "GhcUnregisterised=YES" >> mk/build.mk
			echo "GhcWithInterpreter=NO" >> mk/build.mk
			echo "GhcWithNativeCodeGen=NO" >> mk/build.mk
			echo "SplitObjs=NO" >> mk/build.mk
			echo "GhcRTSWays := debug" >> mk/build.mk
			echo "GhcNotThreaded=YES" >> mk/build.mk
		fi
		# Have "ld -r --relax" problem with split-objs on sparc:
		if use sparc; then
			echo "SplitObjs=NO" >> mk/build.mk
		fi

		# Get ghc from the unpacked binary .tbz2
		# except when bootstrapping we just pick ghc up off the path
		if ! use ghcbootstrap; then
			export PATH="${WORKDIR}/usr/bin:${PATH}"
		fi

		econf || die "econf failed"

		emake all || die "make failed"

	fi # ! use binary
}

src_install() {
	if use binary; then
		mkdir -p "${ED}"
		mv "${S}/usr" "${ED}"

		# Remove the docs if not requested
		if ! use doc; then
			rm -rf "${ED}/usr/share/doc/${P}/*/" \
				"${ED}/usr/share/doc/${P}/*.html" \
				|| die "could not remove docs (P vs PF revision mismatch?)"
		fi
	else
		local insttarget="install"

		# We only built docs if we were bootstrapping, otherwise
		# we copy them out of the unpacked binary .tbz2
		if use doc; then
			if use ghcbootstrap; then
				insttarget="${insttarget} install-docs"
			else
				mkdir -p "${ED}/usr/share/doc"
				mv "${WORKDIR}/usr/share/doc/${P}" "${ED}/usr/share/doc" \
					|| die "failed to copy docs"
			fi
		fi

		emake -j1 ${insttarget} \
			DESTDIR="${D}" \
			|| die "make ${insttarget} failed"

		dodoc "${S}/README" "${S}/ANNOUNCE" "${S}/LICENSE" "${S}/VERSION"

		dobashcompletion "${FILESDIR}/ghc-bash-completion"

		cp -p "${ED}/usr/$(get_libdir)/${P}/package.conf"{,.shipped} \
			|| die "failed to copy package.conf"
	fi
}

pkg_postinst() {
	# 'ghc-pkg check' fails in ghc 6.10.2, with the error message:
	# There are problems in package rts-1.0:
	#    include-dirs: PAPI_INCLUDE_DIR doesn't exist or isn't a directory
	# Upstream suggests this solution to fix it:
	export PATH="${EPREFIX}/usr/bin:${PATH}"
	$(ghc-getghcpkg) describe rts | sed 's/PAPI_INCLUDE_DIR//' | $(ghc-getghcpkg) update -

	ghc-reregister

	ewarn "IMPORTANT:"
	ewarn "If you have upgraded from another version of ghc,"
	ewarn "once app-admin/haskell-updater has installed please run:"
	ewarn "      /usr/sbin/haskell-updater --upgrade"
	ewarn "to re-build all ghc-based Haskell libraries."

	bash-completion_pkg_postinst
}

pkg_prerm() {
	# Overwrite the (potentially) modified package.conf with a copy of the
	# original one, so that it will be removed during uninstall.

	PKG="${EROOT}/usr/$(get_libdir)/${P}/package.conf"

	cp -p "${PKG}"{.shipped,}

	[[ -f ${PKG}.old ]] && rm "${PKG}.old"
}
