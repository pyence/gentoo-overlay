# Copyright 1999-2017 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2

EAPI=6

inherit rpm eutils pax-utils

# Binary only distribution
QA_PREBUILT="*"

DESCRIPTION="Project collaboration and tracking software for upwork.com"
HOMEPAGE="https://www.upwork.com/"
SRC_URI="
	amd64? ( https://updates-desktopapp.upwork.com/binaries/v4_2_136_0_y3wmiwgkm81z1nlk/upwork_x86_64.rpm -> ${P}_x86_64.rpm )
	x86? ( https://updates-desktopapp.upwork.com/binaries/v4_2_136_0_y3wmiwgkm81z1nlk/upwork_i386.rpm -> ${P}_i386.rpm )
"
LICENSE="ODESK"
SLOT="0"
KEYWORDS="~amd64 ~x86"

S=${WORKDIR}
PATCHES=( "${FILESDIR}/${PN}-desktop.patch" )

RDEPEND="
	dev-libs/libgcrypt:11
	gnome-base/gconf
	media-libs/alsa-lib
	net-print/cups
	sys-libs/libcap
	virtual/udev
	x11-libs/gtk+:2
	x11-libs/gtkglext
"

src_install() {
	# Wrapper to the real executable
	dobin usr/bin/upwork

	insinto /usr/share
	pax-mark m usr/share/upwork/upwork
	doins -r usr/share/upwork
	dosym /usr/lib/libudev.so /usr/share/upwork/libudev.so.0

	# Make this executable because it's the real executable
	fperms 0755 /usr/share/upwork/upwork

	domenu usr/share/applications/upwork.desktop
	doicon usr/share/pixmaps/upwork.png
}
