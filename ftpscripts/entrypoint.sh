#!/bin/bash

cp /root/ftp.conf /etc/proftpd.conf

exec "$@"
