Running Raspbian 2015-02-16

Username: `pi`  
Password: `holocampassword`

(Fully-qualified) Hostname: studioholobotpi.mit.edu

# Software
* Node.JS (v0.12.0 compiled [here](http://conoroneill.net/download-compiled-version-of-nodejs-0120-stable-for-raspberry-pi-here))
* Dev-nicety stuff (`zsh`, `vim`, `tmux`)
* Node.JS Production Manager `pm2`

# Process
## General
* Setup Raspbian through standard installer, making sure to enable SSH
* Add your public key to `.ssh/authorized_keys` for passwordless login
* Ensure `PermitRootLogin no` and `PasswordAuthentication no` are present in `/etc/sshd/sshd_config` for secure SSH
* Setup networking (see `/etc/network/interfaces`)
* Install required software

## Camera
* Copy `/etc/init.d/webcam` init script, and use `sudo update-rc.d webcam defaults` to enable it by default

## App
* Install required node packages (`npm install`)
* Install and setup `pm2` using [these](https://www.digitalocean.com/community/tutorials/how-to-use-pm2-to-setup-a-node-js-production-environment-on-an-ubuntu-vps) instructions
* Start on boot with `sudo env PATH=$PATH:/usr/local/bin pm2 startup -u pi`
