#!/bin/sh
SERVER=rickards.mit.edu
RESOLUTION=320x240
FRAMERATE=10
avconv -re -t 5 -f video4linux2 -s $RESOLUTION -r $FRAMERATE -i /dev/video0 -vcodec flv -f flv rtmp://$SERVER/live/video
