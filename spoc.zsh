spoctunnel () {
SSHUTTLESTATE=$1
LOGFILE=".sshuttle.log"


# INSTALL SSHPASS
# brew tap ajanis/custombrew
# brew install ajanis/custombrew/sshpass


# ADD TO PROFILE
# Add additional includes
#[[ -f ~/.spoc.zsh ]] && source ~/.spoc.zsh

# CHANGE USERNAME IN SSHUTTLE COMMAND


# Password storage/retrieval mechanism
# Support for 1password and MAC OS KeyChains
# Example command for CLI access provided below

# 1Password CLI
#SPOCPASSWD_1PASSWD="$(op read op://Charter/charterlab-spoc/password)"

# MAC OS Keychain
SPOCPASSWD_KEYCHAIN="$(security find-generic-password -s 'SPOC VPN' -a ${USER} -w)"
if [ -z $SPOCPASSWD_KEYCHAIN ]; then
        security add-generic-password -a ${USER} -s 'SPOC VPN' -w
            fi
# Password storage/retrieval mechanism
# Support for 1password and MAC OS KeyChains
# Example command for CLI access provided below 

# MAC OS Keychain
SPOCPASSWD="${SPOCPASSWD_KEYCHAIN}"



# SSHPASS=$(op read op://Charter/cddharterlab-spoc/password) \
case $SSHUTTLESTATE in
    start)
      if ! pgrep -f sshuttle; then
      echo > $LOGFILE
      SSHPASS=${SPOCPASSWD} \
      bash -c 'sshpass -e sshuttle -v -r ajanis@35.135.192.78:3022 \
      -s ~/.spoc.allow.txt \
      -X ~/.spoc.deny.txt \
      --ns-hosts 172.22.73.19 \
      --to-ns 172.22.73.19' >>$LOGFILE 2>&1 &
      fi
      ;;
    start_1pw)
      if ! pgrep -f sshuttle; then
      echo > $LOGFILE
      SSHPASS=${SPOCPASSWD} \
      bash -c 'sshpass -e sshuttle -v -r ajanis@35.135.192.78:3022 \
      -s ~/.spoc.allow.txt \
      -X ~/.spoc.deny.txt \
      --ns-hosts 172.22.73.19 \
      --to-ns 172.22.73.19' >>$LOGFILE 2>&1 &
      fi
      ;;
    start_keychain)
      if ! pgrep -f sshuttle; then
      echo > $LOGFILE
      SSHPASS=${SPOCPASSWD} \
      bash -c 'sshpass -e sshuttle -v -r ajanis@35.135.192.78:3022 \
      -s ~/.spoc.allow.txt \
      -X ~/.spoc.deny.txt \
      --ns-hosts 172.22.73.19 \
      --to-ns 172.22.73.19' >>$LOGFILE 2>&1 &
      fi
      ;;
    stop)
      if pgrep -f sshuttle; then
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
