> DO NOT RUN IN PRODUCTION !!!

# Updates

- Ubuntu 22.04.1 LTS
- samba 2:4.15.13+dfsg-0ubuntu1
- webmin 2.013
- Nginx v1.18
- add config backups mechanism
- env vars: WEBMIN_URL, WEBMIN_PASSWORD, REDIRECT_PORT to run behind a reverse proxy like Nginx, etc.
- docker-compose.yaml for testing purpose

### webmin-samba-docker
Docker container based on ubuntu running a samba server, with a webmin webui.

This container was build with simplisity in mind. 

To run this container all you need to do is pass port 80 on the host to port 80 on the contrainer, and mount the volume you wish to share to /media/storage on the container.

Example: 
`docker run -d -p 80:80 -p 139:139 -p 445:445 -v /path/on/host:/media/storage <image>`

### Latest image

```

```
