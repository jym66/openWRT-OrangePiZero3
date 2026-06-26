#!/bin/bash
set -e

# ImmortalWrt custom packages and tweaks.
# This script intentionally does not replace diy-script.sh, so the old LEDE
# build can still be used from its original workflow.

# Remove packages that will be replaced by newer external copies.
rm -rf feeds/luci/themes/luci-theme-argon
rm -rf feeds/luci/applications/luci-app-argon-config
rm -rf feeds/luci/applications/luci-app-openclash
rm -rf feeds/luci/applications/luci-app-passwall
rm -rf feeds/packages/net/{xray-core,v2ray-geodata,sing-box,chinadns-ng,dns2socks,hysteria,ipt2socks,microsocks,naiveproxy,shadowsocks-libev,shadowsocks-rust,shadowsocksr-libev,simple-obfs,tcping,trojan-plus,tuic-client,v2ray-plugin,xray-plugin,geoview,shadow-tls}

git_sparse_clone() {
  branch="$1" repourl="$2" && shift 2
  git clone --depth=1 -b "$branch" --single-branch --filter=blob:none --sparse "$repourl"
  repodir=$(basename "$repourl")
  cd "$repodir"
  git sparse-checkout set "$@"
  mv -f "$@" ../package
  cd ..
  rm -rf "$repodir"
}

# OpenClash
git_sparse_clone master https://github.com/vernesong/OpenClash luci-app-openclash

# Passwall
git clone --depth=1 https://github.com/Openwrt-Passwall/openwrt-passwall-packages package/passwall-packages
git clone --depth=1 https://github.com/Openwrt-Passwall/openwrt-passwall package/passwall-luci

# Argon theme
git clone --depth=1 https://github.com/jerrykuku/luci-theme-argon package/luci-theme-argon
git clone --depth=1 https://github.com/jerrykuku/luci-app-argon-config package/luci-app-argon-config

# Replace Argon background when the theme layout matches upstream.
if [ -f "$GITHUB_WORKSPACE/images/bg1.jpg" ] && [ -d package/luci-theme-argon/htdocs/luci-static/argon/img ]; then
  cp -f "$GITHUB_WORKSPACE/images/bg1.jpg" package/luci-theme-argon/htdocs/luci-static/argon/img/bg1.jpg
fi

# Adjust local time format in autocore pages when present.
find package -path '*/autocore/files/*/index.htm' -type f -exec \
  sed -i 's/os.date()/os.date("%a %Y-%m-%d %H:%M:%S")/g' {} +

# Change firmware revision to the build date for ImmortalWrt default-settings.
date_version=$(date +"%y.%m.%d")
find package -path '*/default-settings/files/*' -type f -exec \
  sed -i -E "s/(DISTRIB_REVISION=')([^']*)(')/\1R${date_version} by jym66\3/g" {} +

# Fix armv8 xfsprogs build errors on trees that still need this workaround.
if [ -f feeds/packages/utils/xfsprogs/Makefile ]; then
  sed -i 's/TARGET_CFLAGS.*/TARGET_CFLAGS += -DHAVE_MAP_SYNC -D_LARGEFILE64_SOURCE/g' feeds/packages/utils/xfsprogs/Makefile
fi

# Fix third-party package Makefile include and source URL paths.
find package/*/ -maxdepth 2 -path "*/Makefile" -print0 | xargs -0 -r sed -i 's#\.\./\.\./luci.mk#$(TOPDIR)/feeds/luci/luci.mk#g'
find package/*/ -maxdepth 2 -path "*/Makefile" -print0 | xargs -0 -r sed -i 's#\.\./\.\./lang/golang/golang-package.mk#$(TOPDIR)/feeds/packages/lang/golang/golang-package.mk#g'
find package/*/ -maxdepth 2 -path "*/Makefile" -print0 | xargs -0 -r sed -i 's#PKG_SOURCE_URL:=@GHREPO#PKG_SOURCE_URL:=https://github.com#g'
find package/*/ -maxdepth 2 -path "*/Makefile" -print0 | xargs -0 -r sed -i 's#PKG_SOURCE_URL:=@GHCODELOAD#PKG_SOURCE_URL:=https://codeload.github.com#g'

# Do not force a bundled theme as the default theme at package install time.
find package/luci-theme-*/* -type f -name '*luci-theme-*' -print -exec sed -i '/set luci.main.mediaurlbase/d' {} \;
