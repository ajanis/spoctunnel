#!/bin/bash

colorRed="\033[31m"
colorGreen="\033[32m"
colorYellow="\033[33m"
colorBlue="\033[34m"
colorDefault="\033[0m"

spoctunnelLog="${HOME}/spoctunnel.log"
touch "${spoctunnelLog}"
spoctunnelOption=$1
spoctunnelVersion="spoctunnel_version"

function checkSpocuser() {
  if [ -z "$SPOCUSER" ]; then
    echo -e "
    ${colorRed}No User set for SPOC SSH Connection defined.
    Set the 'SPOCUSER' variable to your SPOC Active-Directory Username in your $SHELL profile.

    ${colorYellow} We will prompt you for your SPOC user now...
    ${colorDefault}
    "
    read -p "Enter SPOC Active-Directory User: " SPOCSETUSER
    export SPOCUSER="SPOCSETUSER"
    echo -e "
    ${colorYellow}
    Add the following to your $SHELL profile:
    export SPOCUSER=\"${SPOCSETUSER}\"
    ${colorDefault}
    "
  fi
  return
}

# MAC OS Keychain
function checkKeychainpass() {
  spoctunnelPass="$(security find-generic-password -s 'SPOC VPN' -a ${USER} -w)"
  if [ -z $spoctunnelPass ]; then
    echo -e "
    ${colorRed}No SPOC Password found in your MacOS Keychain!

    ${colorYellow}
    Creating Keychain password entry now:
    Please enter your SPOC password when prompted to securely store it in your keychain
    ${colorDefault}
    "

    if security add-generic-password -a "${USER}" -s 'SPOC VPN' -w; then
      echo -e "
      ${colorGreen}Password Stored in Keychain...
      ${colorDefault}
      "
    else
      echo -e "
      ${colorRed}Error: Password creation failed
      ${colorDefault}
      "
    fi
  fi
  return
}

# SSHuttle option menu
case $spoctunnelOption in
start)
  checkSpocuser
  checkKeychainpass
  echo -e "${colorGreen}Starting SSHuttle connection to the SPOC Jumphost
    ${colorDefault}"
  if ! pgrep -f sshuttle; then
    echo >"${spoctunnelLog}"
    echo -e "${colorGreen}Starting SSHuttle connection to the SPOC Jumphost
    ${colorDefault}"
    SSHPASS=${spoctunnelPass} \
      bash -c "sshpass -e sshuttle -v -r $SPOCUSER@35.135.192.78:3022 \
      -s HOMEBREW_ETC/spoc.allow.conf \
      -X HOMEBREW_ETC/spoc.deny.conf \
      --ns-hosts 172.22.73.19 \
      --to-ns 172.22.73.19"
  fi >>"${spoctunnelLog}" 2>&1 &
  ;;
stop)
  echo -e "${colorGreen}Killing SSHuttle connection to SPOC
  ${colorDefault}"
  if pgrep -f sshuttle; then
    echo -e "${colorGreen}Killing SSHuttle connection to SPOC
  ${colorDefault}"
    sudo pkill -f sshuttle
  fi >>"${spoctunnelLog}" 2>&1
  ;;
logs)
  less +F "${spoctunnelLog}"
  ;;
version)
  echo -e "${colorGreen}Spoctunnel version ${spoctunnelVersion}${colorDefault}"
  ;;
*)
  echo -e "$0 (start|stop|logs|version)
      start:          | Starts sshuttle using -s HOMEBREW_ETC/spoc.allow.conf and -X HOMEBREW_ETC/spoc.deny.conf
      stop:           | Shuts down the sshuttle application
      logs:           | View the spoctunnel log ~/.spoctunnel.log (This will open in tail mode.  Interrupt to scroll through the log)
      version:        | Spoctunnel version (Display Version for install validation)
      "
  ;;
esac
