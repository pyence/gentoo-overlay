# Copyright 1999-2019 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=6

WX_GTK_VER=3.0
PLOCALES="ar bg ca cs da de el es eu fa fi fr_FR gl hu id it ja ko nl pl pt_BR pt_PT ru sr_RS sr_RS@latin uk_UA vi zh_CN zh_TW"
COMMIT_ID="b118fe7e7a5c37540e2f0aa75af105e272bad234"

inherit autotools flag-o-matic gnome2-utils l10n wxwidgets xdg-utils vcs-snapshot

DESCRIPTION="Advanced subtitle editor"
HOMEPAGE="http://www.aegisub.org/ https://github.com/Aegisub/Aegisub"
SRC_URI="https://github.com/Aegisub/Aegisub/archive/${COMMIT_ID}.tar.gz -> ${P}.tar.gz"

LICENSE="BSD MIT"
SLOT="0"
KEYWORDS="amd64 x86"
IUSE="+alsa debug +fftw openal oss portaudio pulseaudio spell test +uchardet"

# aegisub bundles luabins (https://github.com/agladysh/luabins).
# Unfortunately, luabins upstream is practically dead since 2010.
# Thus unbundling luabins isn't worth the effort.
RDEPEND="
	x11-libs/wxGTK:${WX_GTK_VER}[X,opengl,debug?]
	dev-lang/luajit:2[lua52compat]
	dev-libs/boost:=[icu,nls,threads]
	dev-libs/icu:=
	media-libs/ffmpegsource:=
	media-libs/fontconfig
	media-libs/freetype
	media-libs/libass:=[fontconfig]
	sys-libs/zlib
	virtual/libiconv
	virtual/opengl
	alsa? ( media-libs/alsa-lib )
	fftw? ( >=sci-libs/fftw-3.3:= )
	openal? ( media-libs/openal )
	portaudio? ( =media-libs/portaudio-19* )
	pulseaudio? ( media-sound/pulseaudio )
	spell? ( app-text/hunspell:= )
	uchardet? ( app-i18n/uchardet )
"
DEPEND="${RDEPEND}
	dev-util/intltool
	sys-devel/gettext
	virtual/pkgconfig
	test? (
		>=dev-cpp/gtest-1.8.1
		dev-lua/busted
		dev-lua/luarocks
	)
"

REQUIRED_USE="|| ( alsa openal oss portaudio pulseaudio )"

PATCHES=(
	"${FILESDIR}/${PV}/${P}-fix-system-luajit-build.patch"
	"${FILESDIR}/${PV}/${P}-respect-compiler-flags.patch"
	"${FILESDIR}/${PV}/${P}-support-system-gtest.patch"
	"${FILESDIR}/${PV}/${P}-fix-icu59-build.patch"
	"${FILESDIR}/${PV}/${P}-fix-icu62-build.patch"
	"${FILESDIR}/aegisub-boost.patch"
)

aegisub_check_compiler() {
	if [[ ${MERGE_TYPE} != "binary" ]] && ! test-flag-CXX -std=c++11; then
		die "Your compiler lacks C++11 support. Use GCC>=4.7.0 or Clang>=3.3."
	fi
}

pkg_pretend() {
	aegisub_check_compiler
}

pkg_setup() {
	aegisub_check_compiler
}

src_prepare() {
	default_src_prepare

	# Remove tests that require unavailable uuid Lua module.
	rm automation/tests/modules/lfs.moon || die

	remove_locale() {
		rm "po/${1}.po" || die
	}

	l10n_find_plocales_changes 'po' '' '.po'
	l10n_for_each_disabled_locale_do remove_locale

	# See http://devel.aegisub.org/ticket/1914
	config_rpath_update "${S}"/config.rpath

	eautoreconf

	cat <<- EOF > build/git_version.h || die
		#define BUILD_GIT_VERSION_NUMBER 8897
		#define BUILD_GIT_VERSION_STRING "${PV}"
		#define TAGGED_RELEASE 0
	EOF
}

src_configure() {
	# Prevent access violations from OpenAL detection. See Gentoo bug 508184.
	use openal && export agi_cv_with_openal="yes"

	setup-wxwidgets
	local myeconfargs=(
		--disable-update-checker
		--with-ffms2
		--with-system-luajit
		$(use_enable debug)
		$(use_with alsa)
		$(use_with fftw fftw3)
		$(use_with openal)
		$(use_with oss)
		$(use_with portaudio)
		$(use_with pulseaudio libpulse)
		$(use_with spell hunspell)
		$(use_with uchardet)
	)
	econf "${myeconfargs[@]}"
}

src_compile() {
	emake WITH_SYSTEM_GTEST=$(usex test)
}

src_test() {
	emake test-automation
	emake test-libaegisub
}

pkg_preinst() {
	gnome2_icon_savelist
}

pkg_postinst() {
	gnome2_icon_cache_update
	xdg_desktop_database_update
}

pkg_postrm() {
	gnome2_icon_cache_update
	xdg_desktop_database_update
}
