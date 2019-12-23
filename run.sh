#!/bin/sh

# 创建密码
htpasswd -bc /etc/nginx/passwd ${USER_NAME} ${PASSWORD}

# 修改端口号
sed -i 's/80/'"${HTTP_PORT}"'/g' /etc/nginx/conf.d/default.conf
sed -i 's/6800/'"${HTTP_PORT}"'/g' /usr/share/nginx/html/js/aria-ng*.js

if [ ! -f /conf/aria2.session ] 
then
    touch /conf/aria2.session
fi

if [ ! -f /conf/aria2.conf ] 
then
    cp /app/conf/aria2.conf /conf/aria2.conf
fi

chown -R ${PUID}:${PGID} /conf
touch /var/log/aria2.log
chmod 755 /var/log/aria2.log
chown ${PUID}:${PGID} /var/log/aria2.log
USER=aria2
addgroup --gid "$PGID" "$USER"
adduser \
    --disabled-password \
    --ingroup "$USER" \
    --no-create-home \
    --uid "$PUID" \
    "$USER"
sudo -u "$USER" /usr/bin/aria2c -D --conf-path=/conf/aria2.conf

# 启动nginx
nginx -g 'daemon off;'