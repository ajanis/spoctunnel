#!/bin/bash

echo << EOF >> ~/.spoc.zsh
#!/bin/bash

spoctunnel () {

# ADD TO PROFILE
# Add the following uncommented line to your shell profile
# [[ -f ~/.spoc.zsh ]] && source ~/.spoc.zsh


colorRed="\033[31m"
colorGreen="\033[32m"
colorYellow="\033[33m"
colorBlue="\033[34m"
colorDefault="\033[0m"

SSHUTTLESTATE=$1
LOGFILE="$HOME/.sshuttle.log"

# SET SPOCUSER TO YOUR SPOC ACCOUNT NAME
SPOCUSER=""
if [ -z "$SPOCUSER" ]; then
    echo -e "
    ${colorRed}No User set for SPOC SSH Connection defined.

    Set the ${colorYellow}'SPOCUSER' ${colorRed}variable to your
    ${colorYellow}SPOC Username ${colorRed}in the helper script

    ${colorDefault}"
    return
    fi

# INSTALL SSHPASS
if [ ! -x $(which sshpass) ]; then
    echo -e "${colorRed}

    You need to install the 'sshpass' tool via Homebrew.
    Assuming you have homebrew installed, run the following commands:

    ${colorYellow}brew tap ajanis/custombrew
    brew install ajanis/custombrew/sshpass

    ${colorDefault}"
    return
fi

# Password storage/retrieval mechanism
# Support for 1password and MAC OS KeyChains
# Example command for CLI access provided below

# 1Password CLI
#SPOCPASSWD_1PASSWD="$(op read op://Charter/charterlab-spoc/password)"

# MAC OS Keychain
SPOCPASSWD_KEYCHAIN="$(security find-generic-password -s 'SPOC VPN' -a ${USER} -w)"
if [ -z $SPOCPASSWD_KEYCHAIN ]; then
        echo -e "

        ${colorRed}No SPOC Password found in your MacOS Keychain!

        ${colorGreen}Please enter your SPOC password when prompted to securely store it in your keychain

        ${colorDefault}
        "
        security add-generic-password -a ${USER} -s 'SPOC VPN' -w
            fi


# Set SPOC password to MacOS Keychain Password result
SPOCPASSWD="${SPOCPASSWD_KEYCHAIN}"

# SSHuttle option menu
case $SSHUTTLESTATE in
    start)
      if ! pgrep -f sshuttle; then
      echo > $LOGFILE
      echo -e "${colorGreen}Starting SSHuttle connection to SPOC Jumphost
      ${colorDefault}"
      SSHPASS=${SPOCPASSWD} \
      bash -c "sshpass -e sshuttle -v -r $SPOCUSER@35.135.192.78:3022 \
      -s ~/.spoc.allow.txt \
      -X ~/.spoc.deny.txt \
      --ns-hosts 172.22.73.19 \
      --to-ns 172.22.73.19" >>$LOGFILE 2>&1 &
      fi
      ;;
    start_1pw)
      if ! pgrep -f sshuttle; then
      echo > $LOGFILE
      SSHPASS=${SPOCPASSWD} \
      bash -c "sshpass -e sshuttle -v -r $SPOCUSER@35.135.192.78:3022 \
      -s ~/.spoc.allow.txt \
      -X ~/.spoc.deny.txt \
      --ns-hosts 172.22.73.19 \
      --to-ns 172.22.73.19" >>$LOGFILE 2>&1 &
      fi
      ;;
    start_keychain)
      if ! pgrep -f sshuttle; then
      echo > $LOGFILE
      SSHPASS=${SPOCPASSWD} \
      bash -c "sshpass -e sshuttle -v -r $SPOCUSER@35.135.192.78:3022 \
      -s ~/.spoc.allow.txt \
      -X ~/.spoc.deny.txt \
      --ns-hosts 172.22.73.19 \
      --to-ns 172.22.73.19" >>$LOGFILE 2>&1 &
      fi
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
    *)
      echo -e "$0 (start|stop|tail|cat|start_1pw|start_keychain)
      start:          | Starts sshuttle using -s ~/.spoc.allow.txt and -X ~/.spoc.deny.txt
      stop:           | Shuts down the sshuttle application
      tail:           | Tails the sshuttle process log file at ~/.sshuttle.log
      cat:            | Displays the entire file at ~/.sshuttle.log
      start_1pw:      | Same as start + Uses 1password CLI for password retrieval
      start_keychain: | Same as start + Uses MacOS Keychain for password retrieval"
      ;;
esac
}

EOF
