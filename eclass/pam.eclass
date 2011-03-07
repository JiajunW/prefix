# Copyright 2004 Gentoo Foundation
# Distributed under the terms of the GNU General Public License, v2 or later
# Author Diego Pettenò <flameeyes@gentoo.org>
# $Header: /var/cvsroot/gentoo-x86/eclass/pam.eclass,v 1.19 2011/02/05 22:29:40 flameeyes Exp $
#
# This eclass contains functions to install pamd configuration files and
# pam modules.

inherit multilib flag-o-matic

# dopamd <file> [more files]
#
# Install pam auth config file in /etc/pam.d
dopamd() {
	[[ -z $1 ]] && die "dopamd requires at least one argument"

	if hasq pam ${IUSE} && ! use pam; then
		return 0;
	fi

	( # dont want to pollute calling env
		insinto /etc/pam.d
		insopts -m 0644
		doins "$@"
	) || die "failed to install $@"
	cleanpamd "$@"
}

# newpamd <old name> <new name>
#
# Install pam file <old name> as <new name> in /etc/pam.d
newpamd() {
	[[ $# -ne 2 ]] && die "newpamd requires two arguments"

	if hasq pam ${IUSE} && ! use pam; then
		return 0;
	fi

	( # dont want to pollute calling env
		insinto /etc/pam.d
		insopts -m 0644
		newins "$1" "$2"
	) || die "failed to install $1 as $2"
	cleanpamd $2
}

# dopamsecurity <section> <file> [more files]
#
# Installs the config files in /etc/security/<section>/
dopamsecurity() {
	[[ $# -lt 2 ]] && die "dopamsecurity requires at least two arguments"

	if hasq pam ${IUSE} && ! use pam; then
		return 0
	fi

	( # dont want to pollute calling env
		insinto /etc/security/$1
		insopts -m 0644
		doins "${@:2}"
	) || die "failed to install ${@:2}"
}

# newpamsecurity <section> <old name> <new name>
#
# Installs the config file <old name> as <new name> in /etc/security/<section>/
newpamsecurity() {
	[[ $# -ne 3 ]] && die "newpamsecurity requires three arguments"

	if hasq pam ${IUSE} && ! use pam; then
		return 0;
	fi

	( # dont want to pollute calling env
		insinto /etc/security/$1
		insopts -m 0644
		newins "$2" "$3"
	) || die "failed to install $2 as $3"
}

# getpam_mod_dir
#
# Returns the pam modules' directory for current implementation
getpam_mod_dir() {
	if has_version sys-libs/pam || has_version sys-libs/openpam; then
		PAM_MOD_DIR="${EPREFIX}"/$(get_libdir)/security
	else
		# Unable to find PAM implementation... defaulting
		PAM_MOD_DIR="${EPREFIX}"/$(get_libdir)/security
	fi

	echo ${PAM_MOD_DIR}
}

# pammod_hide_symbols
#
# Hide all non-PAM-used symbols from the module; this function creates a
# simple ld version script that hides all the symbols that are not
# necessary for PAM to load the module, then uses append-flags to make
# sure that it gets used.
pammod_hide_symbols() {
	cat - > "${T}"/pam-eclass-pam_symbols.ver <<EOF
{
	global: pam_sm_*;
	local: *;
};
EOF

	append-ldflags -Wl,--version-script="${T}"/pam-eclass-pam_symbols.ver
}

# dopammod <file> [more files]
#
# Install pam module file in the pam modules' dir for current implementation
dopammod() {
	[[ -z $1 ]] && die "dopammod requires at least one argument"

	if hasq pam ${IUSE} && ! use pam; then
		return 0;
	fi

	exeinto $(getpam_mod_dir#${EPREFIX})
	doexe "$@" || die "failed to install $@"
}

# newpammod <old name> <new name>
#
# Install pam module file <old name> as <new name> in the pam
# modules' dir for current implementation
newpammod() {
	[[ $# -ne 2 ]] && die "newpammod requires two arguements"

	if hasq pam ${IUSE} && ! use pam; then
		return 0;
	fi

	exeinto $(getpam_mod_dir#${EPREFIX})
	newexe "$1" "$2" || die "failed to install $1 as $2"
}

# pamd_mimic_system <pamd file> [auth levels]
#
# This function creates a pamd file which mimics system-auth file
# for the given levels in the /etc/pam.d directory.
pamd_mimic_system() {
	[[ $# -lt 2 ]] && die "pamd_mimic_system requires at least two argments"
	pamd_mimic system-auth "$@"
}

# pamd_mimic <stack> <pamd file> [auth levels]
#
# This function creates a pamd file which mimics the given stack
# for the given levels in the /etc/pam.d directory.
pamd_mimic() {
	[[ $# -lt 3 ]] && die "pamd_mimic requires at least three argments"

	if hasq pam ${IUSE} && ! use pam; then
		return 0;
	fi

	dodir /etc/pam.d
	pamdfile=${ED}/etc/pam.d/$2
	echo -e "# File autogenerated by pamd_mimic in pam eclass\n\n" >> \
		$pamdfile

	originalstack=$1
	authlevels="auth account password session"

	if has_version '<sys-libs/pam-0.78'; then
		mimic="\trequired\t\tpam_stack.so service=${originalstack}"
	else
		mimic="\tinclude\t\t${originalstack}"
	fi

	shift; shift

	while [[ -n $1 ]]; do
		hasq $1 ${authlevels} || die "unknown level type"

		echo -e "$1${mimic}" >> ${pamdfile}

		shift
	done
}

# cleanpamd <pamd file>
#
# Cleans a pam.d file from modules that might not be present on the system
# where it's going to be installed
cleanpamd() {
	while [[ -n $1 ]]; do
		if ! has_version sys-libs/pam; then
			sed -i -e '/pam_shells\|pam_console/s:^:#:' "${ED}/etc/pam.d/$1"
		fi

		shift
	done
}

pam_epam_expand() {
	sed -n -e 's|#%EPAM-\([[:alpha:]-]\+\):\([-+<>=/.![:alnum:]]\+\)%#.*|\1 \2|p' \
	"$@" | sort -u | while read condition parameter; do

	disable="yes"

	case "$condition" in
		If-Has)
		message="This can be used only if you have ${parameter} installed"
		has_version "$parameter" && disable="no"
		;;
		Use-Flag)
		message="This can be used only if you enabled the ${parameter} USE flag"
		use "$parameter" && disable="no"
		;;
		*)
		eerror "Unknown EPAM condition '${condition}' ('${parameter}')"
		die "Unknown EPAM condition '${condition}' ('${parameter}')"
		;;
	esac

	if [ "${disable}" = "yes" ]; then
		sed -i -e "/#%EPAM-${condition}:${parameter/\//\\/}%#/d" "$@"
	else
		sed -i -e "s|#%EPAM-${condition}:${parameter}%#||" "$@"
	fi

	done
}

# Think about it before uncommenting this one, for now run it by hand
# pam_pkg_preinst() {
# 	eshopts_push -o noglob # so that bash doen't expand "*"
#
# 	pam_epam_expand "${ED}"/etc/pam.d/*
#
# 	eshopts_pop # reset old shell opts
# }
