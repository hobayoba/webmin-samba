FROM ubuntu

EXPOSE 80 139 445

ENV WEBMIN_PASSWORD=webmin
ENV WEBMIN_URL=/
ENV REDIRECT_PORT=80
ENV DATA_PATH=/data
ENV SHARES_LIST=PassingBy,InProgress,Processed

# backup configs
VOLUME /backup_configs
# storage
VOLUME /data

WORKDIR /

RUN \
apt-get update -qqq >/dev/null && \
apt-get install apt-transport-https apt-utils \
    curl \
    samba \
    samba-common \
    nginx -yqqq >/dev/null

RUN \
echo "deb https://download.webmin.com/download/repository sarge contrib" >> /etc/apt/sources.list && \
curl -sqL http://www.webmin.com/jcameron-key.asc | apt-key add - && \
apt-get update -qqq >/dev/null && \
apt-get install webmin -yqqq >/dev/null

RUN \
rm -f /etc/nginx/sites-enabled/default && \
chmod -R 777 /backup_configs /data

COPY site.conf /etc/nginx/sites-enabled/default
COPY entrypoint.sh /entrypoint.sh
COPY smb.conf /etc/samba/smb.conf

CMD [ "/bin/bash","/entrypoint.sh" ]
