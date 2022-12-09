#!/bin/bash

sudo install -D -t /usr/local/cfsxfan cfsxfan-unit.sh
sudo install -t /etc/systemd/system cfsxfan.service
sudo systemctl enable cfsxfan.service
sudo systemctl start cfsxfan.service
