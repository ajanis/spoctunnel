#!/bin/bash

colorRed="\033[31m"
colorGreen="\033[32m"
colorYellow="\033[33m"
colorBlue="\033[34m"
colorDefault="\033[0m"

SSHUTTLESTATE=$1
LOGFILE="$HOME/.sshuttle.log"
VERSION="spoctunnel_version"

function checkbrew () {
  if [ ! -x $(which brew) ]; then
    echo -e "${colorRed}
    You need to install the 'Homebrew' application.
    ${colorBlue}You will have to do this manually as there may be additional requirements and steps..

    ${colorYellow}
    Visit https://brew.sh for information and install instructions.
    ${colorDefault}
    "
    fi
    return

}
function checkspocuser () {
if [ -z "$SPOCUSER" ]; then
    echo -e "
    ${colorRed}No User set for SPOC SSH Connection defined.
    Set the 'SPOCUSER' variable to your SPOC Active-Directory Username in your ${SHELL} profile.

    ${colorYellow} We will prompt you for your SPOC user now...
    ${colorDefault}
    "
    read -n "Enter SPOC Active-Directory User : " SPOCSETUSER
    export SPOCUSER="${SPOCSETUSER}"
    fi
    return
}

function checksshpass () {
if [ ! -x $(which sshpass) ]; then
    echo -e "${colorRed}
    You need to install the 'sshpass' utility via Homebrew.

    ${colorBlue}Running the following commands for you...

    ${colorYellow}brew tap ajanis/custombrew
    brew install ajanis/custombrew/sshpass
    ${colorDefault}
    "
    brew tap ajanis/custombrew
    brew install ajanis/custombrew/sshpass
fi
return

}

function checksshuttle () {
if [ ! -x $(which sshuttle) ]; then
    echo -e "
    ${colorRed}You need to install the 'sshuttle' utility via Homebrew.

    ${colorBlue}Running the following command for you...

    ${colorYellow}
    brew install sshuttle
    ${colorDefault}s
    "
    brew install sshuttle
fi
return

}

# MAC OS Keychain
function checkkeychainpw () {
SPOCPASSWD_KEYCHAIN="$(security find-generic-password -s 'SPOC VPN' -a ${USER} -w)"
if [ -z $SPOCPASSWD_KEYCHAIN ]; then
        echo -e "
        ${colorRed}No SPOC Password found in your MacOS Keychain!

        ${colorBlue}Creating Keychain password entry now:

        ${colorYellow}
        Please enter your SPOC password when prompted to securely store it in your keychain
        ${colorDefault}
        "
        security add-generic-password -a "${USER}" -s 'SPOC VPN' -w
fi
return
}

checkbrew
checksshuttle
checksshpass
checkspocuser
checkkeychainpw

# Set SPOC password to MacOS Keychain Password result
SPOCPASSWD="${SPOCPASSWD_KEYCHAIN}"

# SSHuttle option menu
case $SSHUTTLESTATE in
    start)
      if ! pgrep -f sshuttle; then
      echo > $LOGFILE
      echo -e "${colorGreen}Starting SSHuttle connection to the SPOC Jumphost
      ${colorDefault}"
      SSHPASS=${SPOCPASSWD} \
      bash -c "sshpass -e sshuttle -v -r $SPOCUSER@35.135.192.78:3022 \
      -s /libexec/spoc.allow.txt \
      -X /libexec/spoc.deny.txt \
      --ns-hosts 172.22.73.19 \
      --to-ns 172.22.73.19" >>"${LOGFILE}" 2>&1 &
      fi
      sleep 3
      tail -n 10 "${LOGFILE}"
      ;;
    stop)
      if pgrep -f sshuttle; then
      echo -e "${colorGreen}Killing SSHuttle connection to SPOC
      ${colorDefault}"
      sudo pkill -f sshuttle >>$LOGFILE 2>&1
      fi
      ;;
    tail)
      tail -F $LOGFILE
      ;;
    cat)
      cat $LOGFILE
      ;;
    version)
      echo -e "${colorGreen}Spoctunnel version ${VERSION}${colorDefault}"
      ;;
    *)
      echo -e "$0 (start|stop|tail|cat|start_1pw|start_keychain)
      start:          | Starts sshuttle using -s /libexec/spoc.allow.txt and -X /libexec/spoc.deny.txt
      stop:           | Shuts down the sshuttle application
      tail:           | Tails the sshuttle process log file at ~/.sshuttle.log
      cat:            | Displays the entire file at ~/.sshuttle.log"
      ;;
esac
