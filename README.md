
# SPOCTunnel : Sshuttle easy-button for SPOC VPN

- [SPOCTunnel : Sshuttle easy-button for SPOC VPN](#spoctunnel--sshuttle-easy-button-for-spoc-vpn)
  - [Requirements](#requirements)
    - [Set up Sudo privileges](#set-up-sudo-privileges)
    - [Install Homebrew (MacOS) package manager](#install-homebrew-macos-package-manager)
    - [Install Packages and configs](#install-packages-and-configs)
      - [SSHPass](#sshpass)
      - [SSHuttle](#sshuttle)
    - [Custom DNS Resolver](#custom-dns-resolver)
  - [Runing SSHuttle Helper Function](#runing-sshuttle-helper-function)
    - [SPOC Username](#spoc-username)
    - [SPOC Password](#spoc-password)
    - [Options](#options)
      - [Menu / Help / Version](#menu--help--version)
      - [Run `spoctunnel stop` to shut down the `sshuttle` application](#run-spoctunnel-stop-to-shut-down-the-sshuttle-application)
      - [Modifying files for network `allow` and `deny`](#modifying-files-for-network-allow-and-deny)
      - [Allow](#allow)
        - [Deny](#deny)

This document includes two main sections.

1. The components needed to run `sshuttle` with domain-specific-dns (which forwards only requests for spoc.charterlab.com to the spoc-jumphost).

2. A helper script that that fetches your password securely from the MacOS Keychain - allowing for 1-step (fingerprint or local user) password authentication for the `sshuttle` command.  This is accomplished by using the `security` utility to read the appropriate password from the MacOS Keychain and securely pass it to the `sshuttle` utlity.

## Requirements

You will need to set up the following:

- Sudo Privileges
- Install Homebrew
- Install spoctunnel from Homebrew which includes the dependencies:
  - sshuttle
  - sshpass
- Run the spoctunnel command to add your password to the mac os keychain
- Set up custom DNS Resolver for the `spoc.charterlab.com` domain

### Set up Sudo privileges

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

### Install Homebrew (MacOS) package manager

- [Homebrew Installation Instructions](https://docs.brew.sh/Installation)
- Installation Script:

```shell
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
```

### Install Packages and configs

- Homebrew `sshuttle` and `sshpass` Formulas.
- Lab-specific `allow` and `deny` configuration for DNS resolution

Run the following command to add the custom Tap and install the `spoctunnel` Formula

```bash
brew tap ajanis/custombrew
brew install ajanis/custombrew/spoctunnel
```

#### SSHPass

This `sshpass` utility allows you to forward a password to the `ssh` command
This example uses a local environment variable to securely pipe password information to `sshuttle`

In the `spoctunnel` utility, the `sshpass` environment variable is set using the MacOS Keychain CLI `security` tool.
This enables secure password injection that only requires your local user password or fingerprint authentication.

**WARNING**: There are methods to invoke `sshpass` that **ARE NOT** secure.  As such, the utility is not available directly from homebrew.  I use a custom tap and formula hosted on my personal github account.

#### SSHuttle

The `sshuttle` utility provides an easier-to-comprehend wrapper for SSH Tunnelling and managing route-specific DNS.

### Custom DNS Resolver

We add a custom resolver file to ensure that all requests to `spoc.charterlab.com` are forwarded to the SPOC nameserver.

- Create the resolver file for SPOC at /etc/resolver/spoc.charterlab.com

```bash
sudo echo 'search spoc.charterlab.com spoc.local nameserver 172.22.73.19' > /etc/resolver/spoc.charterlab.com
```

- Verify the new resolver for spoc.charterlab.com is present with the following command

(You will have to scroll down a bit to find the correct resolver.  An example is provided of the expected output)

```bash
sudo scutil --dns
```

*Example Output:*

```bash
resolver #8
  domain   : spoc.charterlab.com
  search domain[0] : spoc.charterlab.com
  search domain[1] : spoc.local
  search domain[2] : nameserver
  search domain[3] : 172.22.73.19
  flags    : Request A records, Request AAAA records
  reach    : 0x00000000 (Not Reachable)
```

## Runing SSHuttle Helper Function

### SPOC Username

- You will need to provide a SPOCUSER environment variable.  This should be your SPOC Active-Directory Username
  - Add `export SPOCUSER="<SPOC Active Directory Username>"` to your shell profile.
  - If you do not have this variable set, the script will prompt you every time to provide your Spoc AD Username

### SPOC Password

- On the first run, you will be prompted to add your SPOC Active-Directory Password to the Mac OS Keychain.
  - Enter and confirm your password when prompted.
  - Your password will be saved under the 'SPOC VPN' key.

### Options

#### Menu / Help / Version

- Open a new terminal window
- Run `spoctunnel` with no args to view help.

- The `spoctunnel version command is just there to validate installation

```bash
❯ spoctunnel
spoctunnel (start|stop|tail|cat|start_1pw|start_keychain)
      start:          | Starts spoctunnel
      stop:           | Stops spoctunnel
      logs:           | Tails the spoctunnel process log file at ~/.spoctunnel.
      version:        | Displays the homebrew formula version


```

- Start the process
- You will be prompted for your system/sudo password or fingerprint for the MacOS Keychain (*unless you have configured passwordless sudo*)

```bash
❯ spoctunnel start
Starting SSHuttle connection to the SPOC Jumphost
```

- View Logs
  - The `spoctunnel logs` command will open the logfile in 'Follow' mode. (Like `tail -f`).
  - If you interrupt the follow process, the log will switch to a paginated view (Like `less` or `vim`)

```bash
❯ spoctunnel logs
Starting SSHuttle connection to the SPOC Jumphost
Starting sshuttle proxy (version 1.1.1).
...
c : Connecting to server...
...
c : Connected to server.
fw: setting up.
...
Waiting for data... (interrupt to abort)
```

#### Run `spoctunnel stop` to shut down the `sshuttle` application

```bash
❯ spoctunnel stop
Killing SSHuttle connection to SPOC
```

#### Modifying files for network `allow` and `deny`

The `--dns` flag sends *all* requests to the **sshuttle jumphost**.  You will need to modify your `sshuttle` command so that *ONLY* requests for `spoc.charterlab.com` will be handled by the **sshuttle jumphost**.

#### Allow

```bash
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

##### Deny

```bash
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
