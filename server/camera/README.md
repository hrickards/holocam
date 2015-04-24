USB webcam on Raspberry pi, sent to a central RTMP streaming server

* Copy `rtmp.conf` to `/etc/nginx`
* Add `include /etc/nginx/rtmp.conf;` to the end of `/etc/nginx/nginx.conf`

See rtmp.conf and video.conf for nginx-rtmp configuration
