#!/usr/bin/env sh
#
# Transmission service

# import DroboApps framework functions
. /etc/service.subr

framework_version="2.1"
name="transmission"
version="2.84"
description="BitTorrent download manager"
depends=""
webui=":9091/transmission/web/"

prog_dir="$(dirname "$(realpath "${0}")")"
daemon="${prog_dir}/bin/transmission-daemon"
conffile="${prog_dir}/data/settings.json"
homedir="${prog_dir}/data"
tmp_dir="/tmp/DroboApps/${name}"
pidfile="${tmp_dir}/pid.txt"
logfile="${tmp_dir}/log.txt"
statusfile="${tmp_dir}/status.txt"
errorfile="${tmp_dir}/error.txt"
nicelevel=19

# backwards compatibility
if [ -z "${FRAMEWORK_VERSION:-}" ]; then
  . "${prog_dir}/libexec/service.subr"
fi

start() {
  export TRANSMISSION_WEB_HOME="${prog_dir}/www"
  export EVENT_NOEPOLL=1
  "${daemon}" -g "${homedir}" -x "${pidfile}" -e "${logfile}"
  sleep 1
  renice "${nicelevel}" $(cat "${pidfile}")
}

# boilerplate
if ! grep -q ^tmpfs /proc/mounts; then mount -t tmpfs tmpfs /tmp; fi
if [ ! -d "${tmp_dir}" ]; then mkdir -p "${tmp_dir}"; fi
exec 3>&1 4>&2 1>> "${logfile}" 2>&1
STDOUT=">&3"
STDERR=">&4"
echo "$(date +"%Y-%m-%d %H-%M-%S"):" "${0}" "${@}"
set -o errexit  # exit on uncaught error code
set -o nounset  # exit on unset variable
set -o xtrace   # enable script tracing

main "${@}"
