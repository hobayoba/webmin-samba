#!/bin/bash

# restore configs
ls /backup_configs/webmin >/dev/null 2>&1 && cp -r /backup_configs/webmin /etc/webmin
ls /backup_configs/samba  >/dev/null 2>&1 && cp -r /backup_configs/samba  /etc/samba

# set predefined values
sed -i 's/referers_none=1/referers_none=0/' /etc/webmin/config
sed -i 's/10000/8080/'                      /etc/webmin/miniserv.conf
sed -i 's/ssl=1/ssl=0/'                     /etc/webmin/miniserv.conf

# clean up before set new values
sed -i '/webprefix=/d'         /etc/webmin/config
sed -i '/webprefixnoredir==/d' /etc/webmin/config
sed -i '/redirect_prefix=/d'   /etc/webmin/miniserv.conf
sed -i '/ncookiepath=/d'       /etc/webmin/miniserv.conf
sed -i '/redirect_port=/d'     /etc/webmin/miniserv.conf

if [[ "${WEBMIN_URL}" != "" ]]; then
  echo -e "webprefix=${WEBMIN_URL}\nwebprefixnoredir=1"             >> /etc/webmin/config
  echo -e "redirect_prefix=${WEBMIN_URL}\ncookiepath=${WEBMIN_URL}" >> /etc/webmin/miniserv.conf
  sed -iE "s|/webmin|${WEBMIN_URL}|"                                   /etc/nginx/sites-enabled/default
else
  sed -i 's/webmin//' /etc/nginx/sites-enabled/default
  sed -i '/rewrite/d' /etc/nginx/sites-enabled/default
fi;

if [[ "${REDIRECT_PORT}" != "" ]]; then
  echo "redirect_port=${REDIRECT_PORT}" >> /etc/webmin/miniserv.conf
else
  echo "redirect_port=80"               >> /etc/webmin/miniserv.conf
fi

echo root:${WEBMIN_PASSWORD} | chpasswd

service nginx start
service webmin start
service smbd start
service nmbd start

while true; do
   # cleanup & backup
   rm -rf /backup_configs/webmin_prev /backup_configs/samba_prev
   mv /backup_configs/webmin /backup_configs/webmin_prev 2>/dev/null
   mv /backup_configs/samba  /backup_configs/samba_prev 2>/dev/null
   cp -r /etc/webmin /backup_configs/
   cp -r /etc/samba  /backup_configs/
   # check services
   service webmin status || service webmin start
   service nginx  status || service nginx  start
   service smbd   status || service smbd   start
   service nmbd   status || service nmbd   start
   sleep 5m
done
