FROM ubuntu

EXPOSE 80 139 445
ENV WEBMIN_PASSWORD=webmin
ENV WEBMIN_URL=/

WORKDIR /

COPY Service-check.sh .

RUN apt-get update -qqq && \
apt-get upgrade -yqqq && \
apt-get install apt-transport-https wget samba samba-common nginx -yqqq && \
mkdir /media/storage /data

# configs
VOLUME /data

RUN chmod -R 0777 /media/storage /data

RUN echo "deb https://download.webmin.com/download/repository sarge contrib" >> /etc/apt/sources.list && \
cd /root && \
wget http://www.webmin.com/jcameron-key.asc && \
apt-key add jcameron-key.asc && \
rm /etc/apt/apt.conf.d/docker-gzip-indexes && \
apt-get purge apt-show-versions -yqqq && \
rm /var/lib/apt/lists/*lz4 && \
apt-get -o Acquire::GzipIndexes=false update -yqqq && \
apt-get update -qqq && \
apt-get install webmin -yqqq

RUN sed -i 's/10000/8080/g' /etc/webmin/miniserv.conf && \
sed -i 's/ssl=1/ssl=0/g' /etc/webmin/miniserv.conf && \
rm -f /etc/nginx/sites-enabled/default

RUN echo root:webmin | chpasswd

COPY site.conf /etc/nginx/sites-enabled/default

CMD [ "/bin/bash","/Service-check.sh" ]
