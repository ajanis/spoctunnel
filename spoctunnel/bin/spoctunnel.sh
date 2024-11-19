#!/bin/bash -x
logError="\033[31m"
logSuccess="\033[32m"
logInfo="\033[33m"
logNotice="\033[34m"
logDefault="\033[0m"
spoctunnelLog="HOMEBREW_VARLOG/spoctunnel.log"
spoctunnelOption=$1
spoctunnelVersion="SPOCTUNNEL_VERSION"
spoctunnelIP=${2:-"main-jump"}
spoctunnelPort=${3}
spoctunnelPIDfile="HOMEBREW_VARRUN/sshuttle.pid"
function xc() {
  echo -e "$@" > >(tee -a ${spoctunnelLog})
}
function checkSpocuser() {
  if [ -z "$SPOCUSER" ]; then
    xc "${logError}
    No SSH User defined for SPOC SSH Connection.
    ${logInfo}
    We will prompt you for your SPOC user now...
    ${logDefault}"
    sleep 1
    read -rp "Enter SPOC Active-Directory User: " SPOCSETUSER
    export SPOCUSER="${SPOCSETUSER}"
    xc "${logInfo}Detected $SHELL as your currrent shell."
    export RCFILE="${HOME}/.$(basename "${SHELL}")rc"
    if ! grep -E -q "^export SPOCUSER=[\'\"]${SPOCUSER}[\'\"]" "${RCFILE}"; then
      xc "No 'SPOCUSER' export found in ${RCFILE}
      ${logDefault}"
      sleep 1
      read -rp "Would you like to add ''export SPOCUSER=${SPOCUSER}'' to ${RCFILE}? : [y/n]" SPOCEXPORT
      if [[ "${SPOCEXPORT}" =~ ([y|Y](:?[e|E][S|s])?) ]]; then
        sed -i '' -e '$a\
export SPOCUSER="'"${SPOCUSER}"'"
        ' "${RCFILE}"
        xc "${logSuccess}Added ${logDefault}export SPOCUSER=\"${SPOCUSER}\"${logSuccess} to ${RCFILE}"
        fi
      fi
    fi
  return
}
# MAC OS Keychain
function checkKeychainpass() {
  spoctunnelPass="$(security find-generic-password -s 'SPOC VPN' -a "${USER}" -w)"
  if [ -z "$spoctunnelPass" ]; then
    xc "${logError}No SPOC Password found in your MacOS Keychain!
    ${logInfo}
    Creating Keychain password entry now:
    Please enter your SPOC password when prompted to securely store it in your keychain
    ${logDefault}"
    sleep 1
    if security add-generic-password -a "${USER}" -s 'SPOC VPN' -w; then
      echo -e "${logSuccess}
      Success: Password Stored in Keychain...
      ${logDefault}"
    else
      echo -e "${logError}
      Error: Password creation failed
      ${logDefault}"
    fi
  fi
  return
}
function checkRunning() {
  if pgrep -q -F ${spoctunnelPIDfile}; then
    xc "${logInfo}Info: SShuttle already running${logDefault}"
    exit 0
  elif pgrep -q -lf sshuttle; then
    xc "${logError}Error: Rogue SSHuttle process found, killing all found. ${logDefault}"
    pkill -lf sshuttle
  fi
}

# function startSshuttle() {
#       SSHPASS=${spoctunnelPass}
#       (sshpass -e sshuttle -v \
#       -r "$SPOCUSER"@"$spoctunnelIP":"$spoctunnelPort"\
#       -s HOMEBREW_ETC/spoc.allow.conf \
#       -X HOMEBREW_ETC/spoc.deny.conf \
#       --ns-hosts 172.22.73.19 \
#       --to-ns 172.22.73.19 >>${spoctunnelLog} 2>&1 &) || (echo "failed" && exit 1)
# }
function startSshuttle() {
      # trap "rm -f ${spoctunnelPIDfile}" ERR
      export SSHPASS=${spoctunnelPass}
      sshpass -e sshuttle -v \
      -r "$SPOCUSER"@"$spoctunnelIP":"$spoctunnelPort" \
      -s HOMEBREW_ETC/spoc.allow.conf \
      -X HOMEBREW_ETC/spoc.deny.conf \
      --ns-hosts 172.22.73.19 \
      --to-ns 172.22.73.19 >>${spoctunnelLog} 2>&1 & pid=$!
      echo $pid > ${spoctunnelPIDfile}
      sleep 10
      if ! kill -0 $pid; then
        xc "${logError}
        Failed: SSHuttle process failed with code: $?"
        exit 1
        else
        xc "${logSuccess}
        OK: SSHuttle process started successfully"
        exit 0
        fi
}

function stopSshuttle() {
  if pgrep -q -F ${spoctunnelPIDfile}; then
    xc "${logInfo}Killing $(pgrep -lf -F ${spoctunnelPIDfile})"
    if pkill -F ${spoctunnelPIDfile}; then
      xc "${logSuccess}OK: SSHuttle stopped${logDefault}"
      exit 0
      fi
    else
    xc "${logInfo}Info: SSHuttle not running"
    exit 0
    fi
}

# function stopSshuttle() {
#   if pgrep -f sshuttle; then
#     sudo pkill -f sshuttle
#   fi >>${spoctunnelLog} 2>&1 &

# }

# function logStatus() {
#   if [[ $? == "0" ]]; then
#     xc "${logSuccess}SSHuttle connection ${spoctunnelOption} : OK"
#   fi
#   #else
#   if [[ $? == "1" ]]; then
#     xc "${logError}!!ERROR!!!"
#     xc "${LOG_WARN_COLOR}SSHuttle connection ${spoctunnelOption} : FAIL"
#     xc "${logInfo}Check logs with 'spoctunnel logs' ..."
#   fi
# }

# SSHuttle option menu
case $spoctunnelOption in
start)
  checkRunning
  checkSpocuser
  checkKeychainpass
  startSshuttle
  # logStatus
  ;;
stop)
  stopSshuttle
  # logStatus
  ;;
logs)
  less +F "${spoctunnelLog}"
  ;;
version)
  xc "${logSuccess}Spoctunnel version ${spoctunnelVersion}${logDefault}"
  ;;
postinstall)
  echo -e "${logInfo}
  1) You will need to set your SPOC Active-Directorfy user.
     This can be done by answering script prompt each time you run the script, or by adding the following to your shell profile (RECOMMENDED):
     ${logNotice}
     > export SPOCUSER=\"<Your SPOC Active-Directory Username>\"
  ${logInfo}
  2) Create a link to the custom resolver file installed by the Formula:
     ${logNotice}
     > sudo ln -s $(brew --prefix)/etc/resolver /etc/resolver
     ${logInfo}
     - Run the following command and look for the resolver in the output (toward the end):
       ${logNotice}
       > sudo scutil --dns
  ${logInfo}
  3) Create a link to the custom newsyslog log rotation rule installed by the Formula:
     ${logNotice}
     > sudo ln -s $(brew --prefix)/etc/newsyslog.d/spoctunnel.conf /etc/newsyslog.d/spoctunnel.conf
  ${logInfo}
  4) When you run the script for the first time, you will be prompted to add your SPOC AD Username to the Mac OS Keychain.
     This password will be retrieved automatically when you run spoctunnel in the future.
  ${logDefault}
  "
  ;;
*)
  xc "$0 (start|stop|logs|version) <ip>
      start:          | Starts sshuttle using -s HOMEBREW_ETC/spoc.allow.conf and -X HOMEBREW_ETC/spoc.deny.conf
      stop:           | Shuts down the sshuttle application
      logs:           | View the spoctunnel log HOMEBREW_VARLOG/spoctunnel.log (This will open in tail mode)
                        Interrupt (Ctrl+c) to scroll through the logfile in a vim-like environment.  (Press 'q' to exit)
      version:        | Spoctunnel version (Display Version for install validation)
      "
  ;;
esac
