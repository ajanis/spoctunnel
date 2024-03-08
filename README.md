
# SPOCTunnel : Sshuttle easy-button for SPOC VPN

- [SPOCTunnel : Sshuttle easy-button for SPOC VPN](#spoctunnel--sshuttle-easy-button-for-spoc-vpn)
  - [Installation and Configuration](#installation-and-configuration)
    - [Set up sudo privileges (Optional)](#set-up-sudo-privileges-optional)
      - [Example Sudo Configurations](#example-sudo-configurations)
    - [Install Homebrew](#install-homebrew)
    - [Install the `spoctunnel` helper](#install-the-spoctunnel-helper)
    - [Run the post-install commands](#run-the-post-install-commands)
  - [Using the `spoctunnel` helper script](#using-the-spoctunnel-helper-script)
    - [Menu Options, Commands and Examples](#menu-options-commands-and-examples)
    - [Start the `spoctunnel` helper](#start-the-spoctunnel-helper)
    - [View connection logs](#view-connection-logs)
    - [Stop the `spoctunnel` helper\`](#stop-the-spoctunnel-helper)
  - [ADDITIONAL INFO](#additional-info)
    - [Modifying files for DNS `allow` and `deny`](#modifying-files-for-dns-allow-and-deny)
      - [Allow Config](#allow-config)
      - [Deny Config](#deny-config)
    - [SSHPass Information](#sshpass-information)
    - [SSHuttle Information](#sshuttle-information)

This document includes two main sections.

1. Steps for installation, pre- and post- configuration, and how to use the `spoctunnel` helper.

2. Additional information about the helper script functionality and dependencies.

## Installation and Configuration

### Set up sudo privileges (Optional)

*Proceed carefully.   Your local user should already have permission to run any command as the `root` user, but will be prompted for a password.  You may choose to disable this password prompt, but this means anyone with access to your unlocked Mac would be able to obtain root privileges.*

1. Open your terminal app and run `sudo visudo` (enter your password when prompted) to edit the `/etc/sudoers` file.
2. Add the desired privileges for your user or group. (*The `visudo` program will validate your changes upon saving and will notify you of any errors.*)

#### Example Sudo Configurations

- Users in the `%admin` group may run any command as any user and will be prompted for their password. (**Default Setting**)

```bash
# User and Group specification
%admin      ALL=(ALL) ALL
```

- Users in the `%admin` group may run any command as any user without a password. **(Modified Setting)**

```bash
# User and Group specification
%admin    ALL=(ALL) NOPASSWD: ALL
```

### Install Homebrew

1. Follow the [Homebrew Installation Instructions](https://docs.brew.sh/Installation) to set up homebrew on your Mac.

### Install the `spoctunnel` helper

1. Run the following command in your terminal to set up the custom Tap `ajanis/custombrew`

    *(Note: A Tap is like a repository)*

```bash
brew tap ajanis/custombrew
```

2. Run the following command in your terminal to install the  `spoctunnel` Formula and any dependencies.

```bash
brew install ajanis/custombrew/spoctunnel
```

### Run the post-install commands

*(Note: These will be printed in your terminal after the Formula is installed)*

1. You will need to set your SPOC Active-Directory user.  This can be done by answering script prompt each time you run the script, or by adding the following to your shell profile (RECOMMENDED):

    ```> export SPOCUSER="<Your SPOC Active-Directory Username>"```

2. Create a link to the custom resolver file installed by the Formula:

    ```> sudo ln -s $(brew --prefix)/etc/resolver /etc/resolver```

   - Run the following command and look for the resolver in the output *(Note: it will be near the end)*:

      ```> sudo scutil --dns```

3. Create a link to the custom newsyslog log rotation rule installed by the Formula:

    ```> sudo ln -s $(brew --prefix)/etc/newsyslog.d/spoctunnel.conf /etc/newsyslog.d/spoctunnel.conf```

4. When you run the script for the first time, you will be prompted to add your SPOC AD Username to the Mac OS Keychain.

   This password will be retrieved automatically when you run spoctunnel in the future.

## Using the `spoctunnel` helper script

If you have followed the post-installation steps above, you should not need to do anything other than set your sPOC AD Password the first time you start the helper.

### Menu Options, Commands and Examples

- Open a new terminal window
- Run `spoctunnel` with no args to view help.

- The `spoctunnel version` command is just there to validate installation

```bash
❯ spoctunnel
spoctunnel (start|stop|tail|cat|start_1pw|start_keychain)
      start:          | Starts spoctunnel
      stop:           | Stops spoctunnel
      logs:           | Tails the spoctunnel process log file at ~/.spoctunnel.
      version:        | Displays the homebrew formula version


```

### Start the `spoctunnel` helper

- You will be prompted for your system/sudo password or fingerprint for the MacOS Keychain (*unless you have configured passwordless sudo*)
- You will be prompted to enter your sPOC AD Password the first time you run the `spoctunnel` helepr

```bash
❯ spoctunnel start
SSHuttle connection start : OK
```

### View connection logs

- The `spoctunnel logs` command will open the logfile in 'Follow' mode. (Like `tail -f`).
- If you interrupt the follow process, the log will switch to a paginated view (Like `less` or`vim`)

```bash
❯ spoctunnel logs
SSHuttle connection start : OK
Starting sshuttle proxy (version 1.1.2).
c : Starting firewall manager with command: ['/usr/bin/sudo', '-p', '[local sudo] Password: ', '/usr/bin/env', 'PYTHONPATH=/usr/local/Cellar/sshuttle/1.1.2/libexec/lib/python3.12/site-packages', '/usr/local/Cellar
/sshuttle/1.1.2/libexec/bin/python', '/usr/local/bin/sshuttle', '-v', '--method', 'auto', '--firewall']
...
c : Connected to server.
...
fw: >> pfctl -E
Waiting for data... (interrupt to abort)
```

### Stop the `spoctunnel` helper`

```bash
❯ spoctunnel stop
Killing SSHuttle connection to SPOC
```

## ADDITIONAL INFO

### Modifying files for DNS `allow` and `deny`

The `--dns` flag sends *all* DNS requests to the **sPOC Jumphost**.  The `allow.conf` file contains IP addresses that should be sent through the sPOC Jumphost.  The `deny.conf` file contains IP addresses that should be sent to your system-defined (probably corporate) nameserver.

If you need to edit them, the files are located at $(brew --prefix)/spoctunnel/allow.txt and $(brew --prefix)/spoctunnel/deny.txt

#### Allow Config

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

#### Deny Config

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

### SSHPass Information

This `sshpass` utility allows you to forward a password to the `ssh` command
This example uses a local environment variable to securely pipe password information to `sshuttle`

In the `spoctunnel` utility, the `sshpass` environment variable is set using the MacOS Keychain CLI `security` tool.
This enables secure password injection that only requires your local user password or fingerprint authentication.

**WARNING**: There are methods to invoke `sshpass` that **ARE NOT** secure.  As such, the utility is not available directly from homebrew.  I use a custom tap and formula hosted on my personal github account.

### SSHuttle Information

The `sshuttle` utility provides an easier-to-comprehend wrapper for SSH Tunnelling and managing route-specific DNS.
