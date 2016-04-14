### ZLIB ###
_build_zlib() {
local VERSION="1.2.8"
local FOLDER="zlib-${VERSION}"
local FILE="${FOLDER}.tar.gz"
local URL="http://zlib.net/${FILE}"

_download_tgz "${FILE}" "${URL}" "${FOLDER}"
pushd "target/${FOLDER}"
./configure --prefix="${DEPS}" --libdir="${DEST}/lib" --shared
make
make install
popd
}

### OPENSSL ###
_build_openssl() {
local VERSION="1.0.2d"
local FOLDER="openssl-${VERSION}"
local FILE="${FOLDER}.tar.gz"
local URL="http://mirror.switch.ch/ftp/mirror/openssl/source/old/1.0.2/${FILE}"

_download_tgz "${FILE}" "${URL}" "${FOLDER}"
cp -vf "src/${FOLDER}-parallel-build.patch" "target/${FOLDER}/"
pushd "target/${FOLDER}"
patch -p1 -i "${FOLDER}-parallel-build.patch"
./Configure --prefix="${DEPS}" --openssldir="${DEST}/etc/ssl" \
  zlib-dynamic --with-zlib-include="${DEPS}/include" --with-zlib-lib="${DEPS}/lib" \
  shared threads linux-armv4 -DL_ENDIAN ${CFLAGS} ${LDFLAGS} \
  -Wa,--noexecstack -Wl,-z,noexecstack
sed -i -e "s/-O3//g" Makefile
make
make install_sw
cp -vfa "${DEPS}/lib/libssl.so"* "${DEST}/lib/"
cp -vfa "${DEPS}/lib/libcrypto.so"* "${DEST}/lib/"
cp -vfaR "${DEPS}/lib/engines" "${DEST}/lib/"
cp -vfaR "${DEPS}/lib/pkgconfig" "${DEST}/lib/"
rm -vf "${DEPS}/lib/libcrypto.a" "${DEPS}/lib/libssl.a"
sed -e "s|^libdir=.*|libdir=${DEST}/lib|g" -i "${DEST}/lib/pkgconfig/libcrypto.pc"
sed -e "s|^libdir=.*|libdir=${DEST}/lib|g" -i "${DEST}/lib/pkgconfig/libssl.pc"
popd
}

### CURL ###
_build_curl() {
local VERSION="7.48.0"
local FOLDER="curl-${VERSION}"
local FILE="${FOLDER}.tar.gz"
local URL="http://curl.haxx.se/download/${FILE}"

_download_tgz "${FILE}" "${URL}" "${FOLDER}"
pushd "target/${FOLDER}"
./configure --host="${HOST}" --prefix="${DEPS}" \
  --libdir="${DEST}/lib" --disable-static \
  --disable-debug --disable-curldebug \
  --with-zlib="${DEPS}" --with-ssl="${DEPS}" --with-random \
  --with-ca-bundle="${DEST}/etc/ssl/certs/ca-certificates.crt" --enable-ipv6
make
make install
popd
}

### LIBEVENT ###
_build_libevent() {
local VERSION="2.0.22-stable"
local FOLDER="libevent-${VERSION}"
local FILE="${FOLDER}.tar.gz"
local URL="https://github.com/libevent/libevent/releases/download/release-${VERSION}/${FILE}"

_download_tgz "${FILE}" "${URL}" "${FOLDER}"
pushd "target/${FOLDER}"
./configure --host="${HOST}" --prefix="${DEPS}" \
  --libdir="${DEST}/lib" --disable-static
make
make install
popd
}

### TRANSMISSION ###
_build_transmission() {
local VERSION="2.92"
local FOLDER="transmission-${VERSION}"
local FILE="${FOLDER}.tar.xz"
local URL="https://transmission.cachefly.net/${FILE}"

_download_xz "${FILE}" "${URL}" "${FOLDER}"
pushd "target/${FOLDER}"
PKG_CONFIG_PATH="${DEST}/lib/pkgconfig" \
  ./configure --host="${HOST}" --prefix="${DEST}" \
  --disable-nls --enable-cli --enable-daemon --enable-utp \
  --with-zlib="${DEPS}"
make -j1
make -j1 install
mv -v "${DEST}/share/transmission/web" "${DEST}/app"
popd
}

_build() {
  _build_zlib
  _build_openssl
  _build_curl
  _build_libevent
  _build_transmission
  _package
}
