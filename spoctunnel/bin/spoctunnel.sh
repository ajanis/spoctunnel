#!/bin/bash
Lr="\033[31m"
Lg="\033[32m"
Ly="\033[33m"
Lb="\033[34m"
Lw="\033[0m"
spoctunnelOption=$1
spoctunnelIP=${2:-"spoc-jump"}
spoctunnelPort=${3}
spoctunnelVersion='SPOCTUNNEL_VERSION'
homebrew_etc='HOMEBREW_ETC'
homebrew_varlog='HOMEBREW_VARLOG'
homebrew_varrun='HOMEBREW_VARRUN'

#overrides
# homebrew_etc='/usr/local/etc'
# homebrew_varlog='/usr/local/var/log'
# homebrew_varrun='/usr/local/var/run'

spoctunnelLog="${homebrew_varlog}/spoctunnel/spoctunnel.log"
spoctunnelPIDfile="${homebrew_varrun}/spoctunnel/spoctunnel.pid"

function xc() {
  echo -e "$@" > >(tee -a "${spoctunnelLog}")
}
function checkSpocuser() {
  if [ -z "$SPOCUSER" ]; then
    xc "${Lr}
    No SSH User defined for SPOC SSH Connection.
    ${Ly}
    We will prompt you for your SPOC user now...
    ${Lw}"
    sleep 1
    read -rp "Enter SPOC Active-Directory User: " SPOCSETUSER
    export SPOCUSER="${SPOCSETUSER}"
    xc "${Ly}
    Detected $SHELL as your currrent shell...
    ${Lw}"
    export RCFILE="${HOME}/.$(basename "${SHELL}")rc"
    if ! grep -E -q "^export SPOCUSER=[\'\"]${SPOCUSER}[\'\"]" "${RCFILE}"; then
      xc "${Lr}
      No 'SPOCUSER' export found in ${RCFILE}
      ${Ly}
      We can add ${Lw}export SPOCUSER=\"${SPOCUSER}\"${Ly} to ${RCFILE}
      ${Lw}"
      sleep 1
      read -rp "Would you like to add ''export SPOCUSER=${SPOCUSER}'' to ${RCFILE}? : [y/n]" SPOCEXPORT
      if [[ "${SPOCEXPORT}" =~ ([y|Y](:?[e|E][S|s])?) ]]; then
        sed -i '' -e '$a\
export SPOCUSER="'"${SPOCUSER}"'"
        ' "${RCFILE}"
        xc "${Lg}
        Added ${Lw}export SPOCUSER=\"${SPOCUSER}\"${Lg} to ${RCFILE}
        ${Lw}"
        fi
      fi
    fi
  return
}
# MAC OS Keychain
function checkKeychainpass() {
  spoctunnelPass="$(security find-generic-password -s 'SPOC VPN' -a "${USER}" -w)"
  if [ -z "$spoctunnelPass" ]; then
    xc "${Lr}No SPOC Password found in your MacOS Keychain!
    ${Ly}
    Creating Keychain password entry for 'SPOC VPN'...
    Please enter your SPOC password when prompted to securely store it in the MacOS keychain...
    ${Lw}"
    sleep 1
    if security add-generic-password -a "${USER}" -s 'SPOC VPN' -w; then
      xc "${Lg}
      Success: Password Stored in Keychain...
      ${Lw}"
      spoctunnelPass="$(security find-generic-password -s 'SPOC VPN' -a "${USER}" -w)"
    else
      xc "${Lr}
      Error: Password creation failed
      ${Lw}"
    fi
  fi
  return
}
function checkRunning() {
  if pgrep -q -F ${spoctunnelPIDfile}; then
    xc "${Ly}
    Info: SShuttle aLready running
    ${Lw}"
    exit 0
  elif pgrep -q -lf sshuttle; then
    xc "${Lr}
    Error: Rogue SSHuttle process found, killing all found processes.
    ${Lw}"
    pkill -lf sshuttle
  fi
}

function startSshuttle() {
      export SSHPASS=${spoctunnelPass}
      sshpass -e sshuttle -v \
      -r "$SPOCUSER"@"$spoctunnelIP":"$spoctunnelPort" \
      -s ${homebrew_etc}/spoctunnel/spoc.allow.conf \
      -X ${homebrew_etc}/spoctunnel/spoc.deny.conf \
      --ns-hosts 172.22.73.19 \
      --to-ns 172.22.73.19 >>${spoctunnelLog} 2>&1 & pid=$!
      echo $pid > ${spoctunnelPIDfile}
      sleep 10
      if ! kill -0 $pid; then
        xc "${Lr}
        Failed: SSHuttle process failed with code: $?"
        exec $SHELL
        else
        xc "${Lg}
        OK: SSHuttle process started successfully"
        exec $SHELL
        fi
}

function stopSshuttle() {
  if pgrep -q -F ${spoctunnelPIDfile}; then
    xc "${Ly}
    Killing $(pgrep -lf -F ${spoctunnelPIDfile})
    ${Lw}"
    if pkill -F ${spoctunnelPIDfile}; then
      xc "${Lg}OK: SSHuttle stopped${Lw}"
      exit 0
      fi
    else
    xc "${Ly}
    Info: SSHuttle not running
    ${lW}"
    exit 0
    fi
}


# SSHuttle option menu
case $spoctunnelOption in
start)
  checkRunning
  checkSpocuser
  checkKeychainpass
  startSshuttle
  ;;
stop)
  stopSshuttle
  ;;
logs)
  less +F "${spoctunnelLog}"
  ;;
version)
  xc "${Lg}Spoctunnel version ${spoctunnelVersion}${Lw}"
  ;;
postinstall)
  echo -e "${Ly}
  1) You will need to set your SPOC Active-Directorfy user.
     This can be done by answering script prompt each time you run the script, or by adding the following to your shell profile (RECOMMENDED):
     ${Lb}
     > export SPOCUSER=\"<Your SPOC Active-Directory Username>\"
  ${Ly}
  2) Create a link to the custom resolver file installed by the Formula:
     ${Lb}
     > sudo ln -s $(brew --prefix)/etc/resolver /etc/resolver
     ${Ly}
     - Run the following command and look for the resolver in the output (toward the end):
       ${Lb}
       > sudo scutil --dns
  ${Ly}
  3) Create a link to the custom newsyslog log rotation rule installed by the Formula:
     ${Lb}
     > sudo ln -s $(brew --prefix)/etc/newsyslog.d/spoctunnel.conf /etc/newsyslog.d/spoctunnel.conf
  ${Ly}
  4) When you run the script for the first time, you will be prompted to add your SPOC AD Username to the Mac OS Keychain.
     This password will be retrieved automatically when you run spoctunnel in the future.
  ${Lw}
  "
  ;;
*)
  xc "$0 (start|stop|logs|version) <ip>
      start:          | Starts sshuttle using -s ${homebrew_etc}/spoctunnel/spoc.allow.conf and -X ${homebrew_etc}/spoctunnel/spoc.deny.conf
      stop:           | Shuts down the sshuttle application
      logs:           | View the spoctunnel log ${homebrew_varlog}/spoctunnel/spoctunnel.log (This will open in tail mode)
                        Interrupt (Ctrl+c) to scroll through the logfile in a vim-like environment.  (Press 'q' to exit)
      version:        | Spoctunnel version (Display Version for install validation)
      "
  ;;
esac
