#!/bin/bash

export BACKUP_RESTORED=false
# try to restore backups on first run
for I in {0..14}; do
  if ls /backup_configs/$(date +'%Y.%m.%d_00' -d"${I} day ago")* >/dev/null 2>&1; then
    export BDT=$(date +'%Y.%m.%d_00' -d"${I} day ago")
    export BACKUP_DIR=$(ls -d /backup_configs/${BDT}*)
    echo "INFO: found backups, restoring from ${BACKUP_DIR}"
    rm -rf /etc/webmin /etc/samba /etc/nginx
    cp -r ${BACKUP_DIR}/webmin ${BACKUP_DIR}/samba ${BACKUP_DIR}/nginx /etc/
#    find /etc/samba  -type d | xargs -I {} chmod 755 {}
#    find /etc/samba  -type f | xargs -I {} chmod 644 {}
#    find /etc/webmin -type d | xargs -I {} chmod 755 {}
#    find /etc/webmin -type f | xargs -I {} chmod 644 {}
#    find /etc/nginx  -type d | xargs -I {} chmod 755 {}
#    find /etc/nginx  -type f | xargs -I {} chmod 644 {}
#    chown root:bin -R /etc/webmin
    export BACKUP_RESTORED=true
    echo "INFO: backup restored"
    break
  fi;
done

if ! $BACKUP_RESTORED; then
  echo "INFO: preconfigure services"

  sed -i -E "s|/default_data_path|${DATA_PATH}|" /etc/samba/smb.conf

  for SHARE in $(echo ${SHARES_LIST} | sed 's/,/ /g'); do
    echo -e "[${SHARE}]\n    path = ${DATA_PATH}/${SHARE}\n" >> /etc/samba/smb.conf
  done
  echo -e "\n\n" >> /etc/samba/smb.conf

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
fi

# configure predefined users
useradd -M -N -Groot,sambashare,users -u0 -o guest
passwd -d guest
echo root:${WEBMIN_PASSWORD} | chpasswd

service nginx start
service smbd start
service nmbd start
service webmin start

while true; do
   # check or start services
   service webmin status >/dev/null || service webmin start
   service nginx  status >/dev/null || service nginx  start
   service smbd   status >/dev/null || service smbd   start
   service nmbd   status >/dev/null || service nmbd   start
   if [[ "$(date +'%Y.%m.%d_%H')" == "$(date +'%Y.%m.%d_00')" ]] && ! ls /backup_configs/$(date +'%Y.%m.%d_00')* >/dev/null 2>&1; then
     echo "INFO: backing up configs"
     # clean up old backups
     find /backup_configs -type d -maxdepth 1 -mtime +14 -delete
     # make backups
     DT=$(date +'%Y.%m.%d_%H.%M.%S')
     mkdir -p /backup_configs/${DT}
     cp -r /etc/webmin /backup_configs/${DT}/
     cp -r /etc/samba  /backup_configs/${DT}/
     cp -r /etc/nginx  /backup_configs/${DT}/
     echo "INFO: backing up is done"
   fi;
   sleep 5m
done
