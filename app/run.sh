#!/bin/sh

# 创建密码
htpasswd -bc /etc/nginx/passwd ${USER_NAME} ${PASSWORD}

# 修改端口号，考虑到重启容器的情况。
if [ -f oldHttpPort.txt ]
then
    OLD_HTTP_PORT=`cat oldHttpPort.txt`
else
    OLD_HTTP_PORT=80
fi
sed -i 's/'"${OLD_HTTP_PORT}"'/'"${HTTP_PORT}"'/g' /etc/nginx/conf.d/default.conf
echo ${HTTP_PORT} > oldHttpPort.txt

if [ -f oldExternalPort.txt ]
then
    OLD_EXTERNAL_PORT=`cat oldExternalPort.txt`
else
    OLD_EXTERNAL_PORT=6800
fi
sed -i 's/'"${OLD_EXTERNAL_PORT}"'/'"${EXTERNAL_PORT}"'/g' /usr/share/nginx/html/js/aria-ng*.js
echo ${EXTERNAL_PORT} > oldExternalPort.txt

# 初始化aria2配置
if [ ! -f /conf/aria2.session ] 
then
    touch /conf/aria2.session
fi

if [ ! -f /conf/aria2.conf ] 
then
    cp /app/conf/aria2.conf /conf/aria2.conf
fi

# 设置文件权限
chown -R ${PUID}:${PGID} /conf
chown -R ${PUID}:${PGID} /data
touch /var/log/aria2.log
chmod 755 /var/log/aria2.log
chown ${PUID}:${PGID} /var/log/aria2.log

# 设置aria2运行用户
if [ ${PUID} -eq "0" ]
then
    USER=root
else
    USER=aria2
    addgroup --gid "$PGID" "$USER"
    adduser \
        --disabled-password \
        --ingroup "$USER" \
        --no-create-home \
        --uid "$PUID" \
        "$USER"
fi

# 启动nginx
nginx

# 启动cron，自动更新tracker
if [ ${ENABLE_UPDATE_TRACKER} == "true" ] 
then
    crond
fi

# 启动aria2
sudo -u "$USER" /usr/bin/aria2c --conf-path=/conf/aria2.conf
