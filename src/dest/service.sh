#!/usr/bin/env sh
#
# Transmission service

# import DroboApps framework functions
. /etc/service.subr

framework_version="2.1"
name="transmission"
version="2.94-drobo"
description="A fast, easy, and free BitTorrent client"
depends=""
webui="WebUI"

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
  framework_version="2.0"
  . "${prog_dir}/libexec/service.subr"
fi

start() {
  export TRANSMISSION_WEB_HOME="${prog_dir}/app"
  "${daemon}" --config-dir "${homedir}" --pid-file "${pidfile}" --logfile "${tmp_dir}/${name}.log"
  sleep 1
  renice "${nicelevel}" $(cat "${pidfile}")
}

# boilerplate
if [ ! -d "${tmp_dir}" ]; then mkdir -p "${tmp_dir}"; fi
exec 3>&1 4>&2 1>> "${logfile}" 2>&1
STDOUT=">&3"
STDERR=">&4"
echo "$(date +"%Y-%m-%d %H-%M-%S"):" "${0}" "${@}"
set -o errexit  # exit on uncaught error code
set -o nounset  # exit on unset variable
set -o xtrace   # enable script tracing

main "${@}"
