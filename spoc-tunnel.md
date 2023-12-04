
# SPOC Tunnel BASH/ZSH Function

- [SPOC Tunnel BASH/ZSH Function](#spoc-tunnel-bashzsh-function)
  - [Requirements](#requirements)
    - [Sudo privileges](#sudo-privileges)
    - [Homebrew (MacOS) package manager](#homebrew-macos-package-manager)
    - [SSHuttle](#sshuttle)
    - [SSHPass (Optional)](#sshpass-optional)
    - [Providing password through 1Password or MacOS Keychain](#providing-password-through-1password-or-macos-keychain)
      - [1Password](#1password)
      - [MacOS Keychain](#macos-keychain)
  - [Modify your sshuttle command to ONLY send DNS requests for 'spoc.charterlab.com' to the sshuttle jumphost](#modify-your-sshuttle-command-to-only-send-dns-requests-for-spoccharterlabcom-to-the-sshuttle-jumphost)
    - [Create a domain-specific-DNS configuration for the SPOC Lab](#create-a-domain-specific-dns-configuration-for-the-spoc-lab)
    - [Create files for `allow` and `deny`  that will be used by `sshuttle`](#create-files-for-allow-and-deny--that-will-be-used-by-sshuttle)
  - [Run the `sshuttle` command in your terminal](#run-the-sshuttle-command-in-your-terminal)
  - [Stop Here if you do not wish to create the helper functiond or use a \[password-manager to securely inject credentials\]\[def7\]](#stop-here-if-you-do-not-wish-to-create-the-helper-functiond-or-use-a-password-manager-to-securely-inject-credentialsdef7)
  - [Create the function that we will use to start and stop the `sshuttle` process](#create-the-function-that-we-will-use-to-start-and-stop-the-sshuttle-process)
    - [Include ~/.spoc.rc you just created in your $SHELL profile / rcfile](#include-spocrc-you-just-created-in-your-shell-profile--rcfile)
  - [Run sshuttle helper](#run-sshuttle-helper)

This document includes two main sections.

1. The steps needed to run `sshuttle` with domain-specific-dns (which forwards only requests for spoc.charterlab.com to the spoc-jumphost).

2. A function that can be added to your zsh/bash profile that allows a simple, one-step fingerprint authentication for the `sshuttle` command.  This is accomplished by using the 1Password CLI utiliity  "`op`" to read the appropriate passwords and securely pass them to the `sshuttle` utlity.  I have marked the steps for this method as "OPTIONAL".

## Requirements

### Sudo privileges

You will need to modify /etc/sudoers if you have not already so you can run commands as a privileged user.

The configuration below is OPTIONAL:

```bash

# Cmnd alias specification
Cmnd_Alias CUSTOM = /usr/local/bin/sshuttle, /usr/bin/pgrep, /usr/bin/pkill, /usr/sbin/visudo, /usr/local/bin/sshpass, /usr/local/bin/op

# User specification
    # root and users in group wheel can run anything on any machine as any user
root        ALL = (ALL) ALL
    # users in group admin can run any command from any machine as any user
    # users from group admin can also run any command from the CUSTOM alias on any machine as any user without a password
%admin      ALL = (ALL) ALL : ALL = (ALL) NOPASSWD: CUSTOM
```

### Homebrew (MacOS) package manager

- [Homebrew Installation Instructions](https://docs.brew.sh/Installation)

### SSHuttle

```bash
brew install sshuttle
```

### SSHPass (Optional)

*This utility allows you to forward a password to the `ssh` command.
This example uses an environment variable that in turn uses a password manager to securely pipe password information to `sshuttle`.*

**WARNING**: There are methods to invoke `sshpass` that **ARE NOT** secure.  As such, the utility is not available directly from homebrew.  I use a custom tap and formula hosted on my personal github account.

```bash
brew tap ajanis/custombrew
brew install ajanis/custombrew/sshpass
```

### Providing password through 1Password or MacOS Keychain

*We can securely provide a password to `sshpass` by using a password-management application with a CLI component.  Provided here are examples for 1Password and the MacOS built-in Keychain.*

**NOTE:** 1Password will require a local/machine-password or touch authentication.  The MacOS Keychain will require a sudo password unless you have configured passwordless-sudo)

#### 1Password

- Install 1Password and 1Password CLI

  ```bash
  brew install --cask 1password 1password-cli
  ```

Creating a vault and adding passwords or other secure items is beyond the scope of this document.  An example of the command used to retrieve the password is provided.

#### MacOS Keychain

- Create a generic password
  
```bash
security add-generic-password -s "SPOC VPN" -a "${USER}" -w
```

- Retrieve a generic password

```bash
security find-generic-password -s "SPOC VPN" -a "${USER}" -w
```

## Modify your sshuttle command to ONLY send DNS requests for 'spoc.charterlab.com' to the sshuttle jumphost

### Create a domain-specific-DNS configuration for the SPOC Lab

(Credit to Josh Hurtado for these instructions)

- Run the following commands as a priviliged / root user on the MacOS machine:

- Create the directory /etc/resolver

```bash
sudo mkdir /etc/resolver
```

- Create the resolver file for SPOC at /etc/resolver/spoc.charterlab.com

```bash
sudo echo 'search spoc.charterlab.com spoc.local nameserver 172.22.73.19' > /etc/resolver/spoc.charterlab.com
```

- Verify the new resolver for spoc.charterlab.com is present. *(You will have to scroll down a bit to find the correct one)*

```bash
❯ sudo scutil --dns

DNS configuration
...
resolver #8
  domain   : spoc.charterlab.com
  search domain[0] : spoc.charterlab.com
  search domain[1] : spoc.local
  search domain[2] : nameserver
  search domain[3] : 172.22.73.19
  flags    : Request A records, Request AAAA records
  reach    : 0x00000000 (Not Reachable)
```

### Create files for `allow` and `deny`  that will be used by `sshuttle`

The `--dns` flag sends *all* requests to the **sshuttle jumphost**.  You will need to modify your `sshuttle` command so that *ONLY* requests for `spoc.charterlab.com` will be handled by the **sshuttle jumphost**.

- ALLOW file command
  
```bash
echo << EOF >> ~/.spoc.allow.txt
44.0.0.0/8
10.240.12.0/22
10.244.28.0/22
10.240.40.0/22
10.240.64.0/23
10.240.72.0/22
10.240.76.0/22
#Optical's polatis
10.252.254.197/32
10.252.254.9/24
10.252.255.0/24
172.22.32.0/24
172.22.73.31/32
172.22.73.70
172.22.73.99
172.22.73.19
172.22.73.27/32
172.22.73.164/32
#172.22.73.0/24
#172.22.72.0/22
172.23.62.0/24
172.30.124.128/26
172.22.73.128/25
172.22.73.126
172.22.73.127
172.23.35.32/27
35.135.193.64/26
35.135.193.0/24
2600:6ce6:4410::/48
2605:1c00:50f2::/48
2600:6ce7:0:5::/64
2600:6cec:1c0:7::/64
#2605:1c00:50f2:2800::/64
2605:1c00:50f2:280e::/64
2605:1c00:50f2:280e::6100/64
2605:1c00:50f2:2800:172:22:73:100/128
2605:1c00:50f2:2800:172:22:73:164/128
2605:1c00:50f2:2800:172:22:73:31/128
EOF
```

- DENY File command
  
```bash
echo << EOF >> ~/.spoc.deny.txt
#corp
142.136.0.0/16
142.136.235.173
22.0.0.0/8
33.0.0.0/8
#10.151.0.0/16
#SPOC
#10.240.72.137
35.135.192.78/32
#172.23.62.20
172.23.62.21
172.22.73.17
#172.22.73.13
#2605:1c00:50f2:2800:172:22:73:17/128
#2605:1c00:50f2:2800:172:22:73:13/128
#2605:1c00:50f2:2800:172:22:73:18/128
#2605:1c00:50f2:280b:172:23:62:222/128
EOF
```

## Run the `sshuttle` command in your terminal

```bash
sshuttle -v -r $USER@35.135.192.78:3022 -s ~/.spoc.allow.txt -X ~/.spoc.deny.txt --ns-hosts 172.22.73.19 --to-ns 172.22.73.19 
```

## Stop Here if you do not wish to create the [helper functiond](#create-the-function-that-we-will-use-to-start-and-stop-the-sshuttle-process) or use a [password-manager to securely inject credentials][def7]

## Create the function that we will use to start and stop the `sshuttle` process

**NOTE:** This very simple function is just a wrapper for the `sshuttle` command that uses the CLI component of either 1Password or the MacOS Keychain to securely inject your login credentials without having to manually enter them every time.

You can modify the function to invoke `sshuttle` with any arguments you wish.  And of course, you can still run the `sshuttle` command from the CLI as always.

```bash
echo << EOF >> ~/.spoc.rc
spoctunnel () {
SSHUTTLESTATE=$1
LOGFILE="$HOME/.sshuttle.log"

# Password storage/retrieval mechanism
# Support for 1password and MAC OS KeyChains
# Example command for CLI access provided below 

# 1Password CLI
SPOCPASSWD_1PASSWD="$(op read op://Charter/charterlab-spoc/password)"

# MAC OS Keychain
SPOCPASSWD_KEYCHAIN="$(security find-generic-password -s 'SPOC VPN' -a ${USER} -w)"

# Add the password management VAR of choice
SPOCPASSWD="${SPOCPASSWD_1PASSWD}"

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
      SSHPASS=${SPOCPASSWD_KEYCHAIN} \
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
      start:      Starts sshuttle using -s ~/.spoc.allow.txt and -X ~/.spoc.deny.txt
      stop:       Shuts down the sshuttle application
      tail:       Tails the sshuttle process log file at ~/.sshuttle.log
      cat:        Displays the entire file at ~/.sshuttle.log
      start_1pw:      Starts sshuttle using -s ~/.spoc.allow.txt and -X ~/.spoc.deny.txt. Uses 1password CLI for password retrieval
      start_keychain:      Starts sshuttle using -s ~/.spoc.allow.txt and -X ~/.spoc.deny.txt. Uses MacOS Keychain for password retrieval"
      ;;
esac
}
EOF
```

### Include ~/.spoc.rc you just created in your $SHELL profile / rcfile

This example uses .zshrc, but you can substitute the rcfile for your $SHELL of choice

```bash
cat << EOF >> .zshrc
[[ -f ~/.spoc.zsh ]] && source ~/.spoc.zsh
EOF
```

## Run sshuttle helper

- Open a new terminal window or reinstantiate your shell with `exec $SHELL`
- Run `spoctunnel` to see help

```bash
❯ spoctunnel
spoctunnel (start|stop|tail|cat|start_1pw|start_keychain)
      start:          | Starts sshuttle using -s ~/.spoc.allow.txt and -X ~/.spoc.deny.txt
      stop:           | Shuts down the sshuttle application
      tail:           | Tails the sshuttle process log file at ~/.sshuttle.log
      cat:            | Displays the entire file at ~/.sshuttle.log
      start_1pw:      | Same as start + Uses 1password CLI for password retrieval
      start_keychain: | Same as start + Uses MacOS Keychain for password retrieval

```

- Run `spoctunnel start` to start the `sshuttle` application

```bash
❯ spoctunnel start
[4] 5073
```

- You will be prompted for your system/sudo password or fingerprint by 1Password or MacOS Keychain (*unless you have configured passwordless sudo*)

![Auth Screenshot](auth-screenshot.png)

- Run `spoctunnel tail` to view logs

```bash
❯ spoctunnel tail
c : Connected to server.
fw: setting up.
fw: >> pfctl -s Interfaces -i lo -v
fw: >> pfctl -s all
fw: >> pfctl -a sshuttle6-12300 -f /dev/stdin
fw: >> pfctl -E
fw: >> pfctl -s Interfaces -i lo -v
fw: >> pfctl -s all
fw: >> pfctl -a sshuttle-12300 -f /dev/stdin
fw: >> pfctl -E
c : Accept TCP: 10.153.3.239:52481 -> 44.230.79.122:443.
 s: SW#4:44.230.79.122:443: uwrite: got EPIPE
c : Accept TCP: 10.153.3.239:52484 -> 44.230.79.122:443.
c : Accept TCP: 10.153.3.239:52486 -> 172.22.73.99:443.
c : Accept TCP: 10.153.3.239:52487 -> 172.22.73.99:443.
```

- Run `spoctunnel stop` to shut down the `sshuttle` application

```bash
❯ spoctunnel stop
5073
5152
5155
5156
[4]  + 5073 terminated  SSHPASS=$(op read op://Charter/charterlab-spoc/password) bash -c  >> $LOGFILE
```
