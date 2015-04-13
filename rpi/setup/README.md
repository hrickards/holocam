Running Raspbian 2015-02-16

Username: `pi`  
Password: `holocampassword`

# Software
* vim (`vim`)
* Node.JS (v0.12.0 compiled [here](http://conoroneill.net/download-compiled-version-of-nodejs-0120-stable-for-raspberry-pi-here))
* Tmux (`tmux`)

# Process
* Setup Raspbian through standard installer, making sure to enable SSH
* Add your public key to `.ssh/authorized_keys` for passwordless login
* Setup networking (see `/etc/network/interfaces` and `/etc/wpa_supplicant/wpa_supplicant.conf`)
* Install required software
