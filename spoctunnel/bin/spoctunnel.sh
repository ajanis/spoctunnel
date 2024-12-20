#!/bin/bash

# Color vars for message output
Lr="\033[38;5;124m"
Lg="\033[38;5;40m"
Ly="\033[38;5;011m"
Lb="\033[38;5;073m"
Lw="\033[38;5;254m"
Lo="\033[38;5;208m"
Lgr="\033[38;5;248m"
Lb2="\033[38;5;32m"
Ly2="\033[38;5;178m"
Lgr2="\033[38;5;153m"


# Input parameters for script option and optional jump-server HOSTNAME/IP and SSH 
spoctunnelOption=$1
spoctunnelIP=${2:-"spoc-jump"}
spoctunnelPort=${3}
homebrew_etc="$(brew --prefix )/etc/spoctunnel"
homebrew_varlog="$(brew --prefix )/var/log/spoctunnel"
homebrew_varrun="$(brew --prefix )/var/run/spoctunnel"
spoctunnelLog="${homebrew_varlog}/spoctunnel.log"
spoctunnelPIDfile="${homebrew_varrun}/spoctunnel.pid"
spoctunnelVersion='SPOCTUNNEL_VERSION'

# Logging Function
function xc() {
  echo -e "$@" > >(tee -a "${spoctunnelLog}")
}

# Check for user ENV('SPOCUSER'), Prompt if missing, Add to shell rcfile
function checkSpocuser() {
  if [ -z "$SPOCUSER" ]; then
    xc "${Lo}
    Warning: No SSH User defined for SPOC SSH Connection. 
    Please enter your SPOC LDAP user when prompted.
    ${Lb}
    Note: This should be your CAAS LDAP User.
    ${Lw}"
    sleep 1
    read -rp "Enter SPOC LDAP User: " SPOCSETUSER
    export SPOCUSER="${SPOCSETUSER}"
    xc "${Lg}
    OK: SPOC SSH user set and exported for current session.
    ${Lw}"
    xc "${Ly}
    Info: Detected $SHELL as your currrent shell...
    ${Lw}"
    RCFILE="${HOME}/.$(basename "${SHELL}")rc"
    if grep -E -q "^export SPOCUSER=[\'\"]${SPOCUSER}[\'\"]" "${RCFILE}"; then
    xc "${Ly}
    Info: Found 'SPOCUSER' export in ${RCFILE}.
    ${Lw}"
    else
    xc "${Lo}
    Warning: No 'SPOCUSER' export found in ${RCFILE}!
    We can add ${Ly}'export SPOCUSER=\"${SPOCUSER}\"'${Lo} to ${RCFILE} in the following step.
    ${Lw}"
      sleep 1
      read -rp "Would you like to add 'export SPOCUSER=${SPOCUSER}' to ${RCFILE}? : [y/n]" SPOCEXPORT
      if [[ "${SPOCEXPORT}" =~ ([y|Y](:?[e|E][S|s])?) ]]; then
sed -i '' -e '$a\
export SPOCUSER="'"${SPOCUSER}"'"
' "${RCFILE}"
    xc "${Lg}
    OK: Added ${Ly}'export SPOCUSER=\"${SPOCUSER}\"'${Lg} to ${RCFILE}
    ${Lo}"
        fi
      fi
    fi
  return
}

# Check for ENV('spoctunnelPass') for SSH login, Prompt if missing, Store in MacOS Keychain for future use
function checkKeychainpass() {
  spoctunnelPass="$(security find-generic-password -s 'SPOC VPN' -a "${USER}" -w)"
  if [ -z "$spoctunnelPass" ]; then
    xc "${Lo}
    Warning: No SPOC Password found in your MacOS Keychain!
    Please enter your SPOC LDAP password when prompted.
    ${Lb}
    Note: Your password will be securely stored in the MacOS keychain as 'SPOC VPN' for future use.
    ${Lw}"
    sleep 1
    if security add-generic-password -a "${USER}" -s 'SPOC VPN' -w; then
    xc "${Lg}
    OK: Password Stored in Keychain...
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

# Stop SSHuttle process started by this script via pidfile, Detect running process not started by this script and kill before further action
function stopSshuttle() {
  if pgrep -q -F "${spoctunnelPIDfile}"; then
    xc "${Ly}
    Info: Stopping SSHuttle process:
    ${Lb}"
    pgrep -lfa -F "${spoctunnelPIDfile}"
    xc "${Lg}"
    if pkill -F "${spoctunnelPIDfile}"; then
    xc "${Lg}
    OK: SSHuttle stopped.
    ${Lw}"
      exit 0
      fi
      elif pgrep -q -lf sshuttle; then
    xc "${Lo}
    Warning: A running SSHuttle process has been detected that was not started by our script.
    ${Lb}"
        pgrep -lfao sshuttle
    xc "${Lgr}"
        if pkill -fo sshuttle; then
        sleep 1
    xc "${Lg}
    OK: Rogue SSHuttle process killed.
    ${Lw}"
          return 0
          fi
      else
    xc "${Ly}
    Info: SSHuttle not running
    ${Lw}"
        exit 0
      fi
}

# Check for running SSHuttle process started by this script, also check for process not started by this script and call function to terminate
function checkRunning() {
  if pgrep -q -F "${spoctunnelPIDfile}"; then
    xc "${Ly}
    Info: SSHuttle process aLready running:
    ${Lb}"
    pgrep -lfa -F "${spoctunnelPIDfile}"
    exit 0
    elif pgrep -q -lf sshuttle; then
      stopSshuttle
    else
      return 0
    fi
}

# Start SSHuttle process, include SPOC ssh user, SSH password from MacOS Keychain (securely passed as ENV var to SSHPass, pass DNS allow/deny files, set pidfile)
function startSshuttle() {
      export SSHPASS=${spoctunnelPass}
      sshpass -e sshuttle -v \
      -r "$SPOCUSER"@"$spoctunnelIP":"$spoctunnelPort" \
      -s "${homebrew_etc}"/spoc.allow.conf \
      -X "${homebrew_etc}"/spoc.deny.conf \
      --ns-hosts 172.22.73.19 \
      --to-ns 172.22.73.19 >>"${spoctunnelLog}" 2>&1 & pid=$!
      echo $pid > "${spoctunnelPIDfile}"
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

# Spoctunnel Script Run Options
case $spoctunnelOption in

start)
  # Start a new SSHuttle process after checking for existing processes, SPOC SSH user and password
  checkRunning
  checkSpocuser
  checkKeychainpass
  startSshuttle
  ;;

stop)
  # Stop running SSHuttle processes
  stopSshuttle
  ;;

status)
  # Check for running SSHuttle processes
  checkRunning
  ;;

logs)
  less +F "${spoctunnelLog}"
  ;;

version)
  # Print current release version of Homebrew package
  xc "${Lg}Spoctunnel version ${spoctunnelVersion}${Lw}"
  ;;

postinstall)

  # Print post-install steps (normally handled by Homebrew on install)

  xc "${Ly}
  1) ${Lb2}The first time you run this script, you will be prompted for your ${Lb22}SPOC LDAP Username${Lb2}.
     You will also be prompted to automatically add it to ${Lb22}'${HOME}/.$(basename "${SHELL}")rc'${Lb2}.
     To do this manually, run the following command:
     ${Ly2}
     > echo 'export SPOCUSER=\"<Your SPOC LDAP Username>\"' >> ${HOME}/.$(basename "${SHELL}")rc
  ${Ly}
  2) ${Lb2}When you run the script for the first time, you will be prompted to add your ${Lb22}SPOC LDAP Password${Lb2} to the Mac OS Keychain.
     Your password will be securely retrieved automatically when you run the script in the future.
     To do thius manually, run the following commands:
     ${Ly2}
     > security find-generic-password -a ${USER} -s 'SPOC VPN' -w
     > security add-generic-password -a ${USER} -s 'SPOC VPN' -w
  ${Ly}
  3a) ${Lb2}Create a link to the custom resolver file installed by the Formula.
      This must be done manually.
     ${Ly2}
     > sudo ln -s $(brew --prefix)/etc/resolver /etc/resolver
  ${Ly}
  3b) ${Lb2}Run the following command and look for the resolver in the output (toward the end):
      This must be done manually.
      ${Ly2}
      > sudo scutil --dns
  ${Ly}
  4) ${Lb2}Create a link to the custom newsyslog log rotation rule installed by the Formula:
     This must be done manually.
     ${Ly2}
     > sudo ln -s $(brew --prefix)/etc/newsyslog.d/spoctunnel.conf /etc/newsyslog.d/spoctunnel.conf
  ${Lw}"
  ;;
*)
  # Print Usage/Help
xc "${Lgr2}
Help Menu:
----------

${Lg}$0 ${Lo}[${Lb}start${Lb} ${Lw}(${Ly2}Optional: Jump-Server IP or Hostname${Lw}) (${Ly2}Optional: Jump-Server SSH Port${Lw})${Lo}] [${Lb}stop${Lo}] [${Lb}status${Lo}] [${Lb}logs${Lo}] [${Lb}version${Lo}] [${Lb}postinstall${Lo}] [${Lb}help${Lo}]

${Ly}start${Lw} | Starts sshuttle using -s ${homebrew_etc}/spoc.allow.conf and -X ${homebrew_etc}/spoc.deny.conf
  ${Lb}• Optionally: Pass extra args: [#2 Jump Server IP/Hostname] [#3 Jump Server SSH Port]
  ${Lb}• Recommended: Add an entry to your SSH config for 'spoc-jump' with desired Jump Server SSH IP and Port.
    
    ${Lgr2}Host spoc-jump
        HostName 123.456.789.10
        Port 2222$

${Ly}stop${Lw}  | Shuts down the sshuttle application
${Ly}status${Lw} | Get SSHuttle process info and kill rogue SSHuttle processes that were not created via this script.
${Ly}logs${Lw}  | View the spoctunnel log ${homebrew_varlog}/spoctunnel.log (This will open in tail mode)
  ${Lb}• Interrupt (Ctrl+c) to scroll through the logfile in a vim-like environment.  (Press 'q' to exit)
${Ly}version${Lw} | Spoctunnel version (Display Version for install validation)
${Ly}postinstall${Lw} | Print post-installation instructions (These are normally handled by Homebrew upon installation)
"
  ;;
esac
