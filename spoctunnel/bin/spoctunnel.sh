#!/bin/bash
logError="\033[31m"
logSuccess="\033[32m"
logInfo="\033[33m"
logDefault="\033[0m"
spoctunnelLog="HOMEBREW_VARLOG/spoctunnel.log"
spoctunnelOption=$1
spoctunnelVersion="spoctunnel_version"

function xc() {
  echo -e "$@" > >(tee -a ${spoctunnelLog})
}

function checkSpocuser() {
  if [ -z "$SPOCUSER" ]; then
    xc "${logError}No User set for SPOC SSH Connection defined.
    Set the 'SPOCUSER' variable to your SPOC Active-Directory Username in your $SHELL profile.

    ${logInfo} We will prompt you for your SPOC user now...
    ${logDefault}
	  "

    read -p "Enter SPOC Active-Directory User: " SPOCSETUSER
    export SPOCUSER="SPOCSETUSER"
    xc "${logInfo}Add the following to your $SHELL profile:
    export SPOCUSER=\"${SPOCSETUSER}\"
    ${logDefault}
	  "

  fi
  return
}

# MAC OS Keychain
function checkKeychainpass() {
  spoctunnelPass="$(security find-generic-password -s 'SPOC VPN' -a "${USER}" -w)"
  if [ -z "$spoctunnelPass" ]; then
    xc "${logError}No SPOC Password found in your MacOS Keychain!

    ${logInfo}Creating Keychain password entry now:
    Please enter your SPOC password when prompted to securely store it in your keychain
    ${logDefault}
    "

    if security add-generic-password -a "${USER}" -s 'SPOC VPN' -w; then
      xc "${logSuccess}Password Stored in Keychain...
      ${logDefault}
      "
    else
      xc "${logError}Error: Password creation failed
      ${logDefault}
      "
    fi
  fi
  return
}

function startSshuttle() {
  if ! pgrep -f sshuttle; then
    SSHPASS=${spoctunnelPass} \
      bash -c "sshpass -e sshuttle -v -r $SPOCUSER@35.135.192.78:3022 \
    -s HOMEBREW_ETC/spoc.allow.conf \
    -X HOMEBREW_ETC/spoc.deny.conf \
    --ns-hosts 172.22.73.19 \
    --to-ns 172.22.73.19"
  fi >>${spoctunnelLog} 2>&1 &
}

function stopSshuttle() {
  if pgrep -f sshuttle; then
    sudo pkill -f sshuttle
  fi >>${spoctunnelLog} 2>&1 &

}

function logStatus() {
  if [[ $? == "0" ]]; then
    xc "${logSuccess}SSHuttle connection ${spoctunnelOption} : OK"
  fi
  #else
  if [[ $? == "1" ]]; then
    xc "${logError}!!ERROR!!!"
    xc "${LOG_WARN_COLOR}SSHuttle connection ${spoctunnelOption} : FAIL"
    xc "${logInfo}Check logs with 'spoctunnel logs' ..."
  fi
}

# SSHuttle option menu
case $spoctunnelOption in
start)
  checkSpocuser
  checkKeychainpass
  startSshuttle
  logStatus
  ;;
stop)
  stopSshuttle
  logStatus
  ;;
logs)
  less +F "${spoctunnelLog}"
  ;;
version)
  xc "${logSuccess}Spoctunnel version ${spoctunnelVersion}${logDefault}"
  ;;
*)
  xc "$0 (start|stop|logs|version)
      start:          | Starts sshuttle using -s HOMEBREW_ETC/spoc.allow.conf and -X HOMEBREW_ETC/spoc.deny.conf
      stop:           | Shuts down the sshuttle application
      logs:           | View the spoctunnel log HOMEBREW_VARLOG/spoctunnel.log (This will open in tail mode.  Interrupt (Ctrl+c) to scroll through the logfile in a vim-like environment.  (Press 'q' to exit)
      version:        | Spoctunnel version (Display Version for install validation)
      "
  ;;
esac
