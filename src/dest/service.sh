#!/usr/bin/env sh
#
# Transmission service

# import DroboApps framework functions
. /etc/service.subr

# DroboApp framework version
framework_version="2.0"

# app description
name="transmission"
version="2.84"
description="BitTorrent download manager"

# framework-mandated variables
pidfile="/tmp/DroboApps/${name}/pid.txt"
logfile="/tmp/DroboApps/${name}/log.txt"
statusfile="/tmp/DroboApps/${name}/status.txt"
errorfile="/tmp/DroboApps/${name}/error.txt"

# app-specific variables
prog_dir=$(dirname $(readlink -fn ${0}))
daemon="${prog_dir}/bin/transmission-daemon"
conffile="${prog_dir}/data/settings.json"
homedir="${prog_dir}/data"
nicelevel=19

# script hardening
set -o errexit  # exit on uncaught error code
set -o nounset  # exit on unset variable
set -o pipefail # propagate last error code on pipe

# ensure log folder exists
if ! grep -q ^tmpfs /proc/mounts; then mount -t tmpfs tmpfs /tmp; fi
logfolder="$(dirname ${logfile})"
if [[ ! -d "${logfolder}" ]]; then mkdir -p "${logfolder}"; fi

# redirect all output to logfile
exec 3>&1 1>> "${logfile}" 2>&1

# log current date, time, and invocation parameters
echo $(date +"%Y-%m-%d %H-%M-%S"): ${0} ${@}

# enable script tracing
set -o xtrace

# _is_running
# args: path to pid file
# returns: 0 if pid is running, 1 if not running or if pidfile does not exist.
_is_running() {
  /sbin/start-stop-daemon -K -s 0 -x "${python}" -p "${pidfile}" -q
}

start() {
  export TRANSMISSION_WEB_HOME="${prog_dir}/www"
  export EVENT_NOEPOLL=1
  "${daemon}" -g "${homedir}" -x "${pidfile}" -e "${logfile}"
  sleep 2
  renice "${nicelevel}" $(cat "${pidfile}")
}

_service_start() {
  set +e
  set +u
  if _is_running "${pidfile}"; then
    echo ${name} is already running >&3
    return 1
  fi
  start_service
  set -u
  set -e
}

_service_stop() {
  /sbin/start-stop-daemon -K -x "${daemon}" -p "${pidfile}" -v || echo "${name} is not running" >&3
}

_service_restart() {
  service_stop
  sleep 3
  service_start
}

_service_status() {
  status >&3
}

_service_help() {
  echo "Usage: $0 [start|stop|restart|status]" >&3
  set +e
  exit 1
}

case "${1:-}" in
  start|stop|restart|status) _service_${1} ;;
  *) _service_help ;;
esac