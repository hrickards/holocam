Running Debian Wheezy

Root password: `holocampassword`
Username: `holocam`
Password: `holocam`

(Fully-qualified) Hostname: `studioholobot.mit.edu`

# Software
* vim (`vim`)
* Ruby via [rbenv](https://github.com/sstephenson/rbenv) with `ruby-build` and dependencies (`autoconf bison build-essential libssl-dev libyaml-dev libreadline6-dev zlib1g-dev libncurses5-dev libffi-dev libgdbm3 libgdbm-dev`)
* Rails (`gem install rails`)

# Process
* Install Debian through standard installer
* Add `holocam` user to `sudoers` file with `visudo`
* Setup network (see `etc/network/interfaces` file) with static hostname
* Add your public key to `.ssh/authorized_keys` for passwordless login
* Generate an SSH keypair and add it to Github
* Install required software (apt)
