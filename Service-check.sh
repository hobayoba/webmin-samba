#!/bin/bash

if [ ! -f /data/webmin/config ]; then
 mkdir -p /data/samba /data/webmin
 cp -r /etc/samba/* /data/samba/. && cp -r /etc/webmin/* /data/webmin/.
fi
wait
ln -f /data/samba/* /etc/samba/ && ln -f /etc/webmin/* /data/webmin/
if [[ "${URL}" != "" ]]; then
 echo -e "webprefix=/webmin\nwebprefixnoredir=1" >> /etc/webmin/config
 echo -e "redirect_prefix=/webmin\ncookiepath=/webmin" >> /etc/webmin/miniserv.conf
fi;
service nginx start
service webmin start
service smbd start
service nmbd start
while true; do
 if [[ $(service webmin status) = *stopped* ]]; then
   break
 else
   sleep 5m
 fi
done
