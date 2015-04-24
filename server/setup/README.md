Running Debian Wheezy

Root password: `holocampassword`
Username: `holocam`
Password: `holocam`

(Fully-qualified) Hostname: `studioholobot.mit.edu`

# Software
* vim (`vim`)
* TMux (`tmux`)
* Ruby via [rbenv](https://github.com/sstephenson/rbenv) with `ruby-build` and dependencies (`autoconf bison build-essential libssl-dev libyaml-dev libreadline6-dev zlib1g-dev libncurses5-dev libffi-dev libgdbm3 libgdbm-dev`)
* Rails (`gem install rails`)
* NodeJS via [this](https://nodesource.com/blog/nodejs-v012-iojs-and-the-nodesource-linux-repositories)
* PostgreSQL (`postgresql postgresql-client libpq-dev`) (use `update-rc.d` to autostart)
* Redis using [this](http://redis.io/topics/quickstart) (install as init script)
* Nginx (`nginx`) (use `update-rc.d` to autostart) (install via [this](http://pkula.blogspot.com/2013/06/live-video-stream-from-raspberry-pi.html) to install with rtmp support)
* FFMpeg (`http://www.deb-multimedia.org/`)

# Process
* Install Debian through standard installer
* Add `holocam` user to `sudoers` file with `visudo`
* Setup network (see `etc/network/interfaces` file) with static hostname
* Add your public key to `.ssh/authorized_keys` for passwordless login
* Generate an SSH keypair and add it to Github
* Install required software (apt)
* Clone source repo, and install production gemset with `bundle install --without development test`
* Create PostgreSQL user (username, password both `holocam`) and database (`holocam_production`) and make sure (`postgresql.conf`) has `listen_address` set to `localhost`
* Bind Redis to listen locally only in `/etc/redis/6379.conf`
* Create Postgres tables (`rake db:migrate RAILS_ENV="production"`)
* Take secret production key from development (`rake secret`) and store it in the env variable in `/etc/environment`
* Add OAuth keys to `/etc/environment`
* Create `/etc/nginx/sites-available` and `/etc/nginx/sites-enabled`, and add `include /etc/nginx/sites-enabled/*;` to the `http` block inside `/etc/nginx/nginx.conf`, and remove the existing `server` blocks
* Copy init script to `/etc/init.d/holocam`, and autostart with `sudo update-rc.d holocam defaults`
* Precompile assets with `RAILS_ENV=production bin/rake assets:precompile`
* Add NGinx config (`etc/nginx/sites-available/holocam` and symlink to `sites-enabled`)
* See camera setup README
